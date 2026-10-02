import 'package:flutter/foundation.dart';
import '../core/errors/fallo_red.dart';
import '../models/ficha_model.dart';
import '../components/vista_estado.dart';
import '../data/repositories/ficha_repository.dart';
import '../data/repositories/ficha_repository_impl.dart';
import '../services/sync_service.dart';

/// Proveedor de fichas técnicas (Capa de Estado / UI):
///
/// PRINCIPIO ARQUITECTÓNICO (Semana 13 - Criterio 5):
/// - Desconoce por completo si el dato vino de la red, de SQLite o de una caché.
/// - Consume exclusivamente la interfaz FichaRepository.
/// - Traduce los errores del dominio (incluyendo 422 Unprocessable Entity)
///   a estados de la interfaz y mapeo de errores por campo.
class FichaProvider extends ChangeNotifier {
  final FichaRepository _repositorio;
  final SyncService _syncService;

  List<FichaModel> _fichas = [];
  TipoVistaEstado _estado = TipoVistaEstado.cargando;
  bool _buscandoIA = false;
  String _mensajeError = '';
  Map<String, String> _erroresValidacion = {};
  FichaModel? _resultadoBusquedaIA;
  FichaModel? _fichaSeleccionada;
  DateTime? _ultimaSincronizacion;
  bool _inicializado = false;

  List<FichaModel> get fichas => List.unmodifiable(_fichas);
  TipoVistaEstado get estado => _estado;
  bool get buscandoIA => _buscandoIA;
  String get mensajeError => _mensajeError;
  Map<String, String> get erroresValidacion => _erroresValidacion;
  FichaModel? get resultadoBusquedaIA => _resultadoBusquedaIA;
  FichaModel? get fichaSeleccionada => _fichaSeleccionada;
  DateTime? get ultimaSincronizacion => _ultimaSincronizacion ?? _syncService.ultimaSincronizacionExitosa;
  int get operacionesPendientes => _syncService.operacionesPendientes;
  bool get inicializado => _inicializado;

  FichaProvider({
    FichaRepository? repositorio,
    SyncService? syncService,
  })  : _repositorio = repositorio ?? FichaRepositoryImpl(),
        _syncService = syncService ?? SyncService.instance {
    _syncService.addListener(() {
      cargarFichasLocales(sincronizarConServidor: false);
    });
  }

  /// Carga el catálogo mediante el repositorio (offline-first con revalidación)
  Future<void> cargarFichasLocales({bool sincronizarConServidor = true}) async {
    try {
      if (_fichas.isEmpty) {
        _estado = TipoVistaEstado.cargando;
        notifyListeners();
      }

      final lista = await _repositorio.obtenerFichas(
        sincronizarConServidor: sincronizarConServidor,
      );
      _fichas = lista;

      if (_fichas.isEmpty) {
        _estado = TipoVistaEstado.vacio;
      } else {
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
      debugPrint('[FichaProvider] Error cargando catálogo: $e');
      _estado = TipoVistaEstado.error;
      _mensajeError = 'Error al leer el catálogo de dispositivos';
      notifyListeners();
    }
  }

  void actualizarEstado(TipoVistaEstado nuevo) {
    _estado = nuevo;
    notifyListeners();
  }

  /// Búsqueda inteligente con IA (delegada al repositorio)
  Future<FichaModel?> buscarConIA(String consulta, {String? token}) async {
    if (consulta.trim().isEmpty) return null;

    _buscandoIA = true;
    _mensajeError = '';
    _resultadoBusquedaIA = null;
    notifyListeners();

    try {
      final ficha = await _repositorio.buscarConIA(consulta);
      _resultadoBusquedaIA = ficha;
      if (ficha == null) {
        _mensajeError = 'No se encontraron especificaciones para "$consulta".';
      }
      _buscandoIA = false;
      notifyListeners();
      return ficha;
    } catch (e) {
      if (e is FalloTimeout) {
        _mensajeError = 'Tiempo de espera agotado al consultar la IA. Intente nuevamente.';
      } else if (e is FalloSinConexion) {
        _mensajeError = 'Sin conexión con el backend de FichaAI. Verifique su red.';
      } else {
        _mensajeError = 'No se pudo consultar el servicio de IA.';
      }
      _buscandoIA = false;
      notifyListeners();
      return null;
    }
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

  /// Creación de Ficha Técnica a través del repositorio:
  /// Maneja respuestas de validación 422 del servidor mapeando errores al formulario.
  Future<bool> guardarFicha(FichaModel nuevaFicha, {String? token}) async {
    _mensajeError = '';
    _erroresValidacion = {};
    notifyListeners();

    try {
      final guardada = await _repositorio.crearFicha(nuevaFicha);
      _fichas.removeWhere((f) => f.idLocal == guardada.idLocal);
      _fichas.insert(0, guardada);
      notifyListeners();
      return true;
    } on FalloCliente catch (e) {
      debugPrint('[FichaProvider] Error de cliente capturado: ${e.mensaje}, campos: ${e.erroresPorCampo}');
      _mensajeError = e.mensaje;
      _erroresValidacion = e.erroresPorCampo;
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint('[FichaProvider] Error al guardar ficha: $e');
      _mensajeError = 'Ocurrió un error al procesar el guardado';
      notifyListeners();
      return false;
    }
  }

  /// Dispara la sincronización manual bajo demanda del usuario
  Future<void> forzarSincronizacion({String? token}) async {
    await _repositorio.sincronizarTodo();
    await cargarFichasLocales(sincronizarConServidor: true);
  }

  /// Limpia la memoria local del catálogo (llamado en el cierre de sesión)
  void limpiarMemoria() {
    _fichas.clear();
    _erroresValidacion.clear();
    _resultadoBusquedaIA = null;
    _fichaSeleccionada = null;
    _estado = TipoVistaEstado.vacio;
    notifyListeners();
  }
}
