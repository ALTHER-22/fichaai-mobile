import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../config/ambiente_config.dart';

/// Interceptor de Registro y Diagnóstico:
/// 1. Documenta método, dirección, encabezados, cuerpo y tiempos de respuesta.
/// 2. REGLA DE SEGURIDAD (Semana 13): Oculta el encabezado Authorization (Bearer ***).
/// 3. Enmascara contraseñas y tokens sensibles en los cuerpos de petición y respuesta.
/// 4. REGLA DE SEGURIDAD: Desactivado completamente en ambiente de producción (!AmbienteConfig.habilitarLogging).
class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (!AmbienteConfig.habilitarLogging) {
      return handler.next(options);
    }

    options.extra['tiempo_inicio'] = DateTime.now().millisecondsSinceEpoch;

    final headersSeguros = sanitizarEncabezados(options.headers);

    debugPrint('--> HTTP ${options.method} ${options.uri}');
    debugPrint('    Encabezados: $headersSeguros');
    if (options.data != null) {
      debugPrint('    Cuerpo: ${sanitizarCuerpo(options.data)}');
    }

    return handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (!AmbienteConfig.habilitarLogging) {
      return handler.next(response);
    }

    final inicio = response.requestOptions.extra['tiempo_inicio'] as int?;
    final duracionMs = inicio != null
        ? DateTime.now().millisecondsSinceEpoch - inicio
        : 0;

    debugPrint('<-- HTTP ${response.statusCode} ${response.requestOptions.method} ${response.requestOptions.uri} (${duracionMs}ms)');
    return handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (!AmbienteConfig.habilitarLogging) {
      return handler.next(err);
    }

    debugPrint('<-- HTTP ERROR ${err.response?.statusCode ?? "RED"} ${err.requestOptions.method} ${err.requestOptions.uri}: ${err.message}');
    return handler.next(err);
  }

  Map<String, dynamic> sanitizarEncabezados(Map<String, dynamic> headers) {
    final copia = Map<String, dynamic>.from(headers);
    if (copia.containsKey('Authorization')) {
      copia['Authorization'] = 'Bearer [TOKEN_PROTEGIDO_OCULTO]';
    }
    return copia;
  }

  dynamic sanitizarCuerpo(dynamic body) {
    if (body is Map) {
      final copia = Map<String, dynamic>.from(body);
      for (final clave in ['password', 'contrasena', 'token', 'token_acceso', 'token_actualizacion', 'refresh_token']) {
        if (copia.containsKey(clave)) {
          copia[clave] = '********';
        }
      }
      return copia;
    }
    return body;
  }
}
