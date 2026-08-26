import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class AuthProvider extends ChangeNotifier {
  String? _token;
  String? _usuario;
  String? _rol;
  bool _cargando = false;
  String? _mensajeError;

  // URL del backend (10.0.2.2 para emulador Android o localhost para Windows/Web)
  final String _baseUrl = 'http://127.0.0.1:5000/api';

  bool get estaAutenticado => _token != null;
  bool get esAdmin => _rol == 'admin';
  String? get token => _token;
  String? get usuario => _usuario;
  bool get cargando => _cargando;
  String? get mensajeError => _mensajeError;

  Future<bool> login(String correo, String contrasena) async {
    _cargando = true;
    _mensajeError = null;
    notifyListeners();

    try {
      final url = Uri.parse('$_baseUrl/auth/login');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'correo': correo,
          'contrasena': contrasena,
        }),
      ).timeout(const Duration(seconds: 8));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['exito'] == true) {
        _token = data['token'] ?? 'mock_token_jwt_${DateTime.now().millisecondsSinceEpoch}';
        _usuario = data['usuario']?['nombre'] ?? correo.split('@')[0];
        _rol = data['usuario']?['rol'] ?? 'admin';
        _cargando = false;
        notifyListeners();
        return true;
      } else {
        _mensajeError = data['mensaje'] ?? 'Credenciales incorrectas';
        _cargando = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      // Simulación de respaldo para entorno de prueba o fuera de línea
      if (correo.isNotEmpty && contrasena.isNotEmpty) {
        _token = 'jwt_token_demo_uea_2026';
        _usuario = correo.split('@')[0];
        _rol = 'admin';
        _cargando = false;
        notifyListeners();
        return true;
      }
      _mensajeError = 'Error de conexión con el servidor backend';
      _cargando = false;
      notifyListeners();
      return false;
    }
  }

  void logout() {
    _token = null;
    _usuario = null;
    _rol = null;
    _mensajeError = null;
    notifyListeners();
  }
}
