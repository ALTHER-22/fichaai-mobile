import '../../models/ficha_model.dart';
import '../../models/operacion_pendiente_model.dart';
import '../../services/database_helper.dart';

/// Fuente de Datos Local (Local Data Source):
/// Responsabilidad exclusiva: Leer y escribir en la base de datos del dispositivo (SQLite).
///
/// REGLA ARQUITECTÓNICA (Semana 13 - Criterio 5):
/// - Esta capa NO conoce la API REST, ni endpoints, ni la red.
/// - Encapsula transacciones locales y persistencia offline de la Semana 12.
class FichaFuenteLocal {
  final DatabaseHelper _db;

  FichaFuenteLocal({DatabaseHelper? db}) : _db = db ?? DatabaseHelper.instance;

  Future<List<FichaModel>> obtenerTodas() async {
    return await _db.obtenerTodasLasFichas();
  }

  Future<FichaModel?> obtenerPorId(String id) async {
    return await _db.obtenerFichaPorId(id);
  }

  Future<void> guardar(FichaModel ficha) async {
    await _db.insertarOActualizarFicha(ficha);
  }

  Future<void> reconciliarLWW(FichaModel fichaRemota) async {
    await _db.reconciliarConLWW(fichaRemota);
  }

  Future<void> encolarOperacionOutbox(OperacionPendienteModel op) async {
    await _db.encolarOperacion(op);
  }

  Future<void> marcarComoSincronizado({
    required String idLocal,
    required String idServidor,
    required String fechaServidor,
  }) async {
    await _db.marcarComoSincronizado(
      idLocal: idLocal,
      idServidor: idServidor,
      fechaServidor: fechaServidor,
    );
  }

  Future<void> purgarTodo() async {
    await _db.purgarTodo();
  }
}
