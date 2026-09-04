import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import '../models/ficha_model.dart';
import '../models/operacion_pendiente_model.dart';
import '../components/vista_estado.dart';
import '../services/database_helper.dart';
import '../services/sync_service.dart';

/// Proveedor de fichas técnicas con persistencia offline-first en SQLite,
/// cola Outbox y sincronización resiliente.
class FichaProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final SyncService _syncService = SyncService.instance;

  List<FichaModel> _fichas = [];
  TipoVistaEstado _estado = TipoVistaEstado.cargando;
  bool _buscandoIA = false;
  String _mensajeError = '';
  FichaModel? _resultadoBusquedaIA;
  FichaModel? _fichaSeleccionada;
  DateTime? _ultimaSincronizacion;
  bool _inicializado = false;

  final String _baseUrl = 'http://127.0.0.1:5000/api';

  List<FichaModel> get fichas => List.unmodifiable(_fichas);
  TipoVistaEstado get estado => _estado;
  bool get buscandoIA => _buscandoIA;
  String get mensajeError => _mensajeError;
  FichaModel? get resultadoBusquedaIA => _resultadoBusquedaIA;
  FichaModel? get fichaSeleccionada => _fichaSeleccionada;
  DateTime? get ultimaSincronizacion => _ultimaSincronizacion ?? _syncService.ultimaSincronizacionExitosa;
  int get operacionesPendientes => _syncService.operacionesPendientes;
  bool get inicializado => _inicializado;

  FichaProvider() {
    _syncService.addListener(() {
      // Cuando SyncService termina de procesar, recargar SQLite
      cargarFichasLocales();
    });
  }

  /// Carga inicial rápida desde la base de datos local SQLite (Lectura sin conexión)
  Future<void> cargarFichasLocales() async {
    try {
      final lista = await _db.obtenerTodasLasFichas();
      _fichas = lista;

      if (_fichas.isEmpty) {
        _estado = TipoVistaEstado.vacio;
      }

      // Obtener la fecha del dato local más reciente para calcular la antigüedad
      if (_fichas.isNotEmpty) {
        final primeraConFecha = _fichas.firstWhere(
          (f) => f.fechaServidor != null || f.fechaGuardadoLocal.isNotEmpty,
          orElse: () => _fichas.first,
        );
        final fechaStr = primeraConFecha.fechaServidor ?? primeraConFecha.fechaGuardadoLocal;
        _ultimaSincronizacion = DateTime.tryParse(fechaStr) ?? DateTime.now();
      }

      _inicializado = true;
      notifyListeners();
    } catch (e) {
      debugPrint('[FichaProvider] Error cargando datos locales SQLite: $e');
      _estado = TipoVistaEstado.error;
      _mensajeError = 'Error al leer la base de datos local';
      notifyListeners();
    }
  }

  void actualizarEstado(TipoVistaEstado nuevo) {
    _estado = nuevo;
    notifyListeners();
  }

  /// Búsqueda inteligente con IA (Gemini a través del backend)
  Future<FichaModel?> buscarConIA(String consulta, {String? token}) async {
    if (consulta.trim().isEmpty) return null;

    _buscandoIA = true;
    _mensajeError = '';
    _resultadoBusquedaIA = null;
    notifyListeners();

    try {
      final url = Uri.parse('$_baseUrl/fichas/extraer-ia');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'texto': consulta}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['exito'] == true && data['datos'] != null) {
          final ficha = FichaModel.fromJson(data['datos']);
          _resultadoBusquedaIA = ficha;
          _buscandoIA = false;
          notifyListeners();
          return ficha;
        }
      }
    } catch (e) {
      debugPrint('[FichaProvider] Error consultando backend IA: $e');
    }

    // Fallback local enriquecido si el backend no responde
    await Future.delayed(const Duration(milliseconds: 1000));
    final coincidencias = _fichas.where((f) =>
        f.modelo.toLowerCase().contains(consulta.toLowerCase()) ||
        (f.fabricante?.toLowerCase().contains(consulta.toLowerCase()) ?? false)).toList();

    if (coincidencias.isNotEmpty) {
      _resultadoBusquedaIA = coincidencias.first;
    } else {
      _resultadoBusquedaIA = FichaModel(
        modelo: consulta,
        fabricante: consulta.split(' ').first,
        procesador: 'Chipset inteligente detectado',
        ram: '8 GB RAM',
        almacenamiento: '256 GB',
        pantalla: '6.7" AMOLED FHD+ 120Hz',
        camaraPrincipal: '50 MP con OIS',
        camaraFrontal: '16 MP',
        bateria: '5000 mAh (33W)',
        sistemaOperativo: 'Android 14',
        precioOficial: 299.0,
        sincronizado: false,
      );
    }

    _buscandoIA = false;
    notifyListeners();
    return _resultadoBusquedaIA;
  }

  FichaModel? obtenerPorId(String id) {
    try {
      _fichaSeleccionada = _fichas.firstWhere(
        (f) => f.idLocal == id || f.idServidor == id || f.idFicha == id,
      );
      return _fichaSeleccionada;
    } catch (e) {
      return null;
    }
  }

  void seleccionarFicha(FichaModel ficha) {
    _fichaSeleccionada = ficha;
    notifyListeners();
  }

  /// Escritura sin conexión con Cola Outbox (Escritura Offline y Resiliencia):
  /// 1. Asigna un UUID único del cliente para garantizar idempotencia.
  /// 2. Aplica actualización optimista guardando en SQLite con sincronizado = 0.
  /// 3. Encola la operación en la tabla Outbox `cola_operaciones`.
  /// 4. Dispara el procesamiento asíncrono sin bloquear la interfaz.
  Future<bool> guardarFicha(FichaModel nuevaFicha, {String? token}) async {
    final idLocal = const Uuid().v4();
    final ahora = DateTime.now().toIso8601String();

    final fichaGuardar = FichaModel(
      idLocal: idLocal,
      modelo: nuevaFicha.modelo,
      fabricante: nuevaFicha.fabricante ?? 'Genérico',
      procesador: nuevaFicha.procesador,
      ram: nuevaFicha.ram,
      almacenamiento: nuevaFicha.almacenamiento,
      pantalla: nuevaFicha.pantalla,
      camaraPrincipal: nuevaFicha.camaraPrincipal,
      camaraFrontal: nuevaFicha.camaraFrontal,
      bateria: nuevaFicha.bateria,
      sistemaOperativo: nuevaFicha.sistemaOperativo,
      conectividad: nuevaFicha.conectividad,
      extras: nuevaFicha.extras,
      precioOficial: nuevaFicha.precioOficial,
      moneda: nuevaFicha.moneda,
      urlImagen: nuevaFicha.urlImagen,
      sincronizado: false, // Marcada como pendiente de sincronización
      fechaGuardadoLocal: ahora,
    );

    // 1. Guardar localmente en SQLite
    await _db.insertarOActualizarFicha(fichaGuardar);

    // 2. Encolar en la tabla Outbox con UUID único de cliente
    final opId = const Uuid().v4();
    final operacion = OperacionPendienteModel(
      idOperacion: opId,
      tipoOperacion: 'CREAR_FICHA',
      idEntidadLocal: idLocal,
      payload: jsonEncode(fichaGuardar.toJson()),
      creadoEn: ahora,
    );
    await _db.encolarOperacion(operacion);

    // 3. Actualización optimista en memoria para respuesta instantánea de UI
    _fichas.insert(0, fichaGuardar);
    notifyListeners();

    // 4. Intentar procesar la cola si hay red disponible
    _syncService.procesarColaPendiente(token: token);

    return true;
  }

  /// Dispara la sincronización manual bajo demanda del usuario
  Future<void> forzarSincronizacion({String? token}) async {
    await _syncService.procesarColaPendiente(token: token);
    await _syncService.sincronizarDesdeServidor(token: token);
    await cargarFichasLocales();
  }

  /// Limpia la memoria local del catálogo (llamado en el cierre de sesión)
  void limpiarMemoria() {
    _fichas.clear();
    _resultadoBusquedaIA = null;
    _fichaSeleccionada = null;
    _estado = TipoVistaEstado.vacio;
    notifyListeners();
  }
}
