import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../core/errors/fallo_red.dart';
import '../../models/dto/ficha_dto.dart';
import '../../models/ficha_model.dart';
import '../../models/operacion_pendiente_model.dart';
import '../../services/connectivity_service.dart';
import '../../services/sync_service.dart';
import '../datasources/ficha_local_datasource.dart';
import '../datasources/ficha_remote_datasource.dart';
import 'ficha_repository.dart';

/// Implementación del Repositorio de Fichas Técnicas (Clean Architecture):
/// Coordina la Fuente Local (SQLite) y la Fuente Remota (HTTP / Backend).
///
/// ESTRATEGIA OFFLINE-FIRST (Semana 13 - Apartado 1.4.17):
/// 1. Devuelve de inmediato los datos de la fuente local (la pantalla nunca aparece vacía).
/// 2. Si hay conectividad, consulta la API en paralelo y reconcilia usando Last-Write-Wins (LWW).
/// 3. Si la red falla, preserva los datos mostrados y avisa el estado sin interrumpir al usuario.
/// 4. En escrituras:
///    - Si hay red, envía de inmediato al servidor con Idempotency-Key.
///    - Si el servidor rechaza con 422 (validación), propaga el error al formulario.
///    - Si hay fallo de red o modo avión, guarda en SQLite y encola en la tabla Outbox.
class FichaRepositoryImpl implements FichaRepository {
  final FichaFuenteRemota _fuenteRemota;
  final FichaFuenteLocal _fuenteLocal;
  final ConnectivityService _conectividad;
  final SyncService _syncService;

  FichaRepositoryImpl({
    FichaFuenteRemota? fuenteRemota,
    FichaFuenteLocal? fuenteLocal,
    ConnectivityService? conectividad,
    SyncService? syncService,
  })  : _fuenteRemota = fuenteRemota ?? FichaFuenteRemota(),
        _fuenteLocal = fuenteLocal ?? FichaFuenteLocal(),
        _conectividad = conectividad ?? ConnectivityService.instance,
        _syncService = syncService ?? SyncService.instance;

  @override
  Future<List<FichaModel>> obtenerFichas({bool sincronizarConServidor = true}) async {
    // 1. Devolver de inmediato lo que hay en local
    final locales = await _fuenteLocal.obtenerTodas();

    // 2. Si no se solicita sincronización o no hay red, retornar directo de SQLite
    if (!sincronizarConServidor || !_conectividad.estaConectado) {
      return locales;
    }

    // 3. Consultar la API en paralelo
    try {
      final remotasDto = await _fuenteRemota.listarFichas();
      for (final dto in remotasDto) {
        final modeloDominio = dto.toDomain();
        await _fuenteLocal.reconciliarLWW(modeloDominio);
      }
      // Retornar base local actualizada con marcas oficiales del servidor
      return await _fuenteLocal.obtenerTodas();
    } catch (e) {
      debugPrint('[FichaRepository] Fallo sincronizando con backend: $e. Conservando datos locales.');
      return locales;
    }
  }

  @override
  Future<FichaModel?> obtenerFichaPorId(String id) async {
    return await _fuenteLocal.obtenerPorId(id);
  }

  @override
  Future<FichaModel> crearFicha(FichaModel nuevaFicha) async {
    final idLocal = nuevaFicha.idLocal.isNotEmpty ? nuevaFicha.idLocal : const Uuid().v4();
    final opId = const Uuid().v4(); // UUID de Idempotencia para el cliente
    final ahora = DateTime.now().toIso8601String();

    final fichaAProcesar = nuevaFicha.copyWith(
      idLocal: idLocal,
      fechaGuardadoLocal: ahora,
    );

    // Si hay conexión a la red, intentar creación directa en el backend
    if (_conectividad.estaConectado) {
      try {
        final dtoEnvio = FichaDto.fromDomain(fichaAProcesar);
        final dtoConfirmado = await _fuenteRemota.crearFicha(
          dtoEnvio,
          idempotencyKey: opId,
        );

        // Guardar confirmado en SQLite con fecha del servidor
        final fichaConfirmada = dtoConfirmado.toDomain(idLocal: idLocal).copyWith(
          sincronizado: true,
          fechaGuardadoLocal: ahora,
        );
        await _fuenteLocal.guardar(fichaConfirmada);
        return fichaConfirmada;
      } on FalloCliente catch (e) {
        // Regla: Errores 4xx (como 422 de validación) nunca se reintentan ni se encolan
        debugPrint('[FichaRepository] Rechazo de validación 4xx del servidor: ${e.erroresPorCampo}');
        rethrow;
      } catch (e) {
        debugPrint('[FichaRepository] Error transitorio de red: $e. Pasando a persistencia Outbox.');
      }
    }

    // Flujo Offline-First / Outbox si no hay red o hubo fallo temporal
    final fichaOffline = fichaAProcesar.copyWith(sincronizado: false);
    await _fuenteLocal.guardar(fichaOffline);

    final operacion = OperacionPendienteModel(
      idOperacion: opId,
      tipoOperacion: 'CREAR_FICHA',
      idEntidadLocal: idLocal,
      payload: jsonEncode(fichaOffline.toJson()),
      creadoEn: ahora,
    );
    await _fuenteLocal.encolarOperacionOutbox(operacion);

    // Disparar sincronización asíncrona si la red regresa
    _syncService.actualizarContadorPendientes();
    return fichaOffline;
  }

  @override
  Future<FichaModel?> buscarConIA(String consulta) async {
    if (consulta.trim().isEmpty) return null;

    // 1. Intentar extracción con IA a través del backend oficial de FichaAI
    try {
      final dto = await _fuenteRemota.extraerFichaIA(consulta);
      if (dto != null) {
        return dto.toDomain();
      }
    } catch (e) {
      debugPrint('[FichaRepository] Error en backend IA: $e');
      // Si la consulta remota falla (ej. sin red o timeout), buscar coincidencia local en SQLite
      final locales = await _fuenteLocal.obtenerTodas();
      final matches = locales.where((f) =>
          f.modelo.toLowerCase().contains(consulta.toLowerCase()) ||
          (f.fabricante?.toLowerCase().contains(consulta.toLowerCase()) ?? false)).toList();

      if (matches.isNotEmpty) {
        return matches.first;
      }
      rethrow;
    }

    // 2. Coincidencia en SQLite local si el backend respondió pero no generó ficha
    final locales = await _fuenteLocal.obtenerTodas();
    final matches = locales.where((f) =>
        f.modelo.toLowerCase().contains(consulta.toLowerCase()) ||
        (f.fabricante?.toLowerCase().contains(consulta.toLowerCase()) ?? false)).toList();

    if (matches.isNotEmpty) {
      return matches.first;
    }

    return null;
  }

  @override
  Future<void> sincronizarTodo() async {
    await _syncService.procesarColaPendiente();
    await obtenerFichas(sincronizarConServidor: true);
  }

  @override
  Future<void> purgarDatos() async {
    await _fuenteLocal.purgarTodo();
  }
}
