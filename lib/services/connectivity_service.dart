import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Servicio para monitorizar el estado de la conexión de red y modo avión en tiempo real.
class ConnectivityService extends ChangeNotifier {
  static final ConnectivityService instance = ConnectivityService._internal();
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _estaConectado = true;

  bool get estaConectado => _estaConectado;

  void inicializar() {
    _subscription?.cancel();
    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      _actualizarEstado(results);
    });
    // Verificación inicial
    _connectivity.checkConnectivity().then(_actualizarEstado);
  }

  void _actualizarEstado(List<ConnectivityResult> results) {
    // Si la lista contiene solo 'none', no hay conexión (modo avión o sin red)
    final conectado = results.any((r) => r != ConnectivityResult.none);
    if (_estaConectado != conectado) {
      _estaConectado = conectado;
      debugPrint('[ConnectivityService] Conexión cambiada: conectado=$_estaConectado ($results)');
      notifyListeners();
    }
  }

  Future<bool> verificarConexion() async {
    final results = await _connectivity.checkConnectivity();
    _estaConectado = results.any((r) => r != ConnectivityResult.none);
    notifyListeners();
    return _estaConectado;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
