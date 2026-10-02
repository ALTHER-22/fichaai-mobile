import '../../models/ficha_model.dart';

/// Contrato del Repositorio de Fichas Técnicas.
/// Aísla a la capa de estado (UI) de la red y del almacenamiento físico.
abstract class FichaRepository {
  /// Obtiene la lista de fichas aplicando estrategia offline-first
  Future<List<FichaModel>> obtenerFichas({bool sincronizarConServidor = true});

  /// Obtiene una ficha por su identificador
  Future<FichaModel?> obtenerFichaPorId(String id);

  /// Crea una ficha decidiendo entre envío remoto inmediato o encolado Outbox
  Future<FichaModel> crearFicha(FichaModel ficha);

  /// Búsqueda asistida por inteligencia artificial
  Future<FichaModel?> buscarConIA(String consulta);

  /// Forzar sincronización bajo demanda
  Future<void> sincronizarTodo();

  /// Purga total de datos (Logout / LOPDP)
  Future<void> purgarDatos();
}
