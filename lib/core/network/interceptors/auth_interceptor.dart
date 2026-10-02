import 'package:dio/dio.dart';
import '../../../services/secure_storage_service.dart';

/// Interceptor de Autenticación:
/// Inyecta automáticamente el Bearer Token en el encabezado Authorization,
/// leyéndolo asíncronamente desde el almacenamiento cifrado del sistema operativo
/// (Android Keystore / iOS Keychain / Windows DPAPI).
///
/// Si la ruta es pública (login, registro) o no hay token, la petición avanza libremente.
class AuthInterceptor extends Interceptor {
  final SecureStorageService _secureStorage;

  AuthInterceptor({SecureStorageService? secureStorage})
      : _secureStorage = secureStorage ?? SecureStorageService();

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Si la petición ya incluye cabecera Authorization explícita (ej: refresh token), respetarla
    if (options.headers.containsKey('Authorization')) {
      return handler.next(options);
    }

    try {
      final token = await _secureStorage.obtenerToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    } catch (_) {
      // Si falla la lectura segura, la petición continúa y el backend responderá 401 si es protegida
    }

    return handler.next(options);
  }
}
