import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../services/secure_storage_service.dart';

/// Interceptor de Renovación Automática de Credenciales:
/// 1. Detecta automáticamente respuestas con código 401 Unauthorized.
/// 2. Protección contra bucles infinitos mediante la bandera `extra['reintentado'] = true`.
/// 3. Bloqueo de peticiones concurrentes (Completer lock): Si varias peticiones
///    expiran simultáneamente, solo la primera dispara la renovación; las demás esperan
///    el nuevo token sin saturar el backend con múltiples solicitudes de refresco.
/// 4. Reintenta la petición original con el nuevo token de forma 100% transparente para la UI.
/// 5. Si la renovación falla (refresh token expirado), purga la sesión y redirige al login.
class TokenRefreshInterceptor extends Interceptor {
  final Dio dio;
  final SecureStorageService _secureStorage;
  final VoidCallback? onSesionExpirada;

  // Semáforo para peticiones concurrentes
  static Completer<bool>? _renovacionEnCurso;

  TokenRefreshInterceptor({
    required this.dio,
    SecureStorageService? secureStorage,
    this.onSesionExpirada,
  }) : _secureStorage = secureStorage ?? SecureStorageService();

  @override
  Future<void> onResponse(Response response, ResponseInterceptorHandler handler) async {
    // Si validateStatus < 500 deja pasar el 401 como respuesta
    if (response.statusCode == 401) {
      final requestOptions = response.requestOptions;
      final yaReintentado = requestOptions.extra['reintentado'] == true;

      // No renovar peticiones de login/refresh para evitar ciclos
      final esRutaAuth = requestOptions.path.contains('/auth/login') ||
          requestOptions.path.contains('/auth/renovar');

      if (!yaReintentado && !esRutaAuth) {
        final renovado = await _ejecutarRenovacionConcurrente();
        if (renovado) {
          final nuevaRespuesta = await _reintentarPeticion(requestOptions);
          return handler.resolve(nuevaRespuesta);
        } else {
          await _cerrarSesionPorExpiracion();
        }
      }
    }

    return handler.next(response);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final es401 = err.response?.statusCode == 401;
    final requestOptions = err.requestOptions;
    final yaReintentado = requestOptions.extra['reintentado'] == true;
    final esRutaAuth = requestOptions.path.contains('/auth/login') ||
        requestOptions.path.contains('/auth/renovar');

    if (es401 && !yaReintentado && !esRutaAuth) {
      final renovado = await _ejecutarRenovacionConcurrente();
      if (renovado) {
        try {
          final nuevaRespuesta = await _reintentarPeticion(requestOptions);
          return handler.resolve(nuevaRespuesta);
        } catch (e) {
          return handler.next(err);
        }
      } else {
        await _cerrarSesionPorExpiracion();
      }
    }

    return handler.next(err);
  }

  /// Control de concurrencia: si ya existe una renovación en curso, las demás peticiones esperan
  Future<bool> _ejecutarRenovacionConcurrente() async {
    if (_renovacionEnCurso != null) {
      debugPrint('[TokenRefreshInterceptor] Esperando renovación concurrente en curso...');
      return await _renovacionEnCurso!.future;
    }

    _renovacionEnCurso = Completer<bool>();

    try {
      debugPrint('[TokenRefreshInterceptor] Iniciando renovación de credenciales...');
      final exito = await _solicitarNuevoAccessToken();
      _renovacionEnCurso!.complete(exito);
      return exito;
    } catch (e) {
      debugPrint('[TokenRefreshInterceptor] Error durante la renovación del token: $e');
      _renovacionEnCurso!.complete(false);
      return false;
    } finally {
      _renovacionEnCurso = null;
    }
  }

  /// Llama al endpoint de renovación con el token de actualización
  Future<bool> _solicitarNuevoAccessToken() async {
    final refreshToken = await _secureStorage.obtenerRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      debugPrint('[TokenRefreshInterceptor] No existe refresh token en almacenamiento cifrado');
      return false;
    }

    try {
      // Usar una instancia aislada para no pasar por los mismos interceptores
      final clienteAislado = Dio(BaseOptions(
        baseUrl: dio.options.baseUrl,
        connectTimeout: const Duration(seconds: 8),
        receiveTimeout: const Duration(seconds: 8),
      ));

      final respuesta = await clienteAislado.post(
        '/auth/renovar',
        data: {'token_actualizacion': refreshToken},
        options: Options(headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $refreshToken',
        }),
      );

      if (respuesta.statusCode == 200 && respuesta.data != null) {
        final nuevoAccessToken = respuesta.data['token_acceso']?.toString();
        if (nuevoAccessToken != null && nuevoAccessToken.isNotEmpty) {
          await _secureStorage.actualizarTokenAcceso(nuevoAccessToken);
          debugPrint('[TokenRefreshInterceptor] ¡Token de acceso renovado exitosamente!');
          return true;
        }
      }
    } catch (e) {
      debugPrint('[TokenRefreshInterceptor] Falló el endpoint /auth/renovar: $e');
    }

    return false;
  }

  /// Reintenta la petición original marcándola como 'reintentada'
  Future<Response> _reintentarPeticion(RequestOptions originalOptions) async {
    originalOptions.extra['reintentado'] = true; // Protección estricta contra bucles

    final nuevoToken = await _secureStorage.obtenerToken();
    if (nuevoToken != null) {
      originalOptions.headers['Authorization'] = 'Bearer $nuevoToken';
    }

    return await dio.fetch(originalOptions);
  }

  Future<void> _cerrarSesionPorExpiracion() async {
    debugPrint('[TokenRefreshInterceptor] Refresh token expirado. Purgando sesión y redirigiendo...');
    await _secureStorage.eliminarSesion();
    onSesionExpirada?.call();
  }
}
