import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/ambiente_config.dart';
import '../../services/secure_storage_service.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/token_refresh_interceptor.dart';
import 'interceptors/retry_interceptor.dart';
import 'interceptors/logging_interceptor.dart';

/// Cliente HTTP Centralizado (Singleton):
/// Configura una única instancia de Dio compartida en toda la aplicación.
///
/// CARACTERÍSTICAS ARQUITECTÓNICAS (Semana 13 - Criterio 1):
/// - Instancia única y centralizada (Singleton).
/// - Dirección base dinámica según el ambiente (AmbienteConfig.urlApi).
/// - Tiempos de espera explícitos (connectTimeout: 10s, receiveTimeout: 15s).
/// - Criterio de validación: `validateStatus: (codigo) => codigo != null && codigo < 500`.
///   Permite que los errores de cliente (400, 401, 404, 422) lleguen como respuestas
///   interpretables para su mapeo de dominio en lugar de excepciones crudas no capturadas.
/// - Cadena de interceptores en orden estricto de ejecución.
class ClienteHttp {
  static ClienteHttp? _instance;
  late final Dio dio;

  ClienteHttp._internal({
    SecureStorageService? secureStorage,
    VoidCallback? onSesionExpirada,
  }) {
    final storage = secureStorage ?? SecureStorageService();

    dio = Dio(
      BaseOptions(
        baseUrl: AmbienteConfig.urlApi,
        connectTimeout: AmbienteConfig.tiempoConexion,
        receiveTimeout: AmbienteConfig.tiempoRecepcion,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        // Acepta todo código menor a 500 para interpretar errores 4xx del cliente
        validateStatus: (codigo) => codigo != null && codigo < 500,
      ),
    );

    // ORDEN ESTRICTO DE REGISTRO DE INTERCEPTORES (Guía Semana 13, Apartado 1.4.5)
    // 1. Autenticación: inyecta Bearer token desde almacenamiento cifrado
    dio.interceptors.add(AuthInterceptor(secureStorage: storage));

    // 2. Renovación: captura 401, renueva token con el refresh token y reintenta
    dio.interceptors.add(TokenRefreshInterceptor(
      dio: dio,
      secureStorage: storage,
      onSesionExpirada: onSesionExpirada,
    ));

    // 3. Registro (Logging): imprime actividad sanitizando Authorization; apagado en producción
    dio.interceptors.add(LoggingInterceptor());

    // 4. Reintentos: solo operaciones idempotentes ante timeouts o errores 5xx
    dio.interceptors.add(RetryInterceptor(dio: dio));
  }

  /// Inicializa el Singleton del cliente HTTP
  static ClienteHttp inicializar({
    SecureStorageService? secureStorage,
    VoidCallback? onSesionExpirada,
  }) {
    _instance = ClienteHttp._internal(
      secureStorage: secureStorage,
      onSesionExpirada: onSesionExpirada,
    );
    return _instance!;
  }

  /// Acceso a la instancia única
  static ClienteHttp get instance {
    _instance ??= ClienteHttp._internal();
    return _instance!;
  }
}
