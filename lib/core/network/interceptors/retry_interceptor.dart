import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Interceptor de Reintentos Idempotentes:
/// Aplica reintentos automáticos con espera exponencial creciente (Exponential Backoff).
///
/// REGLAS ESTRICTAS DE RESILIENCIA (Semana 13):
/// 1. Solo reintenta operaciones IDEMPOTENTES (GET, HEAD, OPTIONS, PUT, DELETE, o POST con cabecera Idempotency-Key).
/// 2. NUNCA reintenta peticiones POST sin Idempotency-Key (evita duplicación de registros).
/// 3. NUNCA reintenta errores del cliente 4xx (400, 401, 404, 422, ya que la petición fue rechazada por el servidor).
/// 4. Solo reintenta fallos de red transitorios (Timeouts, SocketExceptions) y errores del servidor 5xx.
class RetryInterceptor extends Interceptor {
  final Dio dio;
  final int maxReintentos;

  RetryInterceptor({
    required this.dio,
    this.maxReintentos = 3,
  });

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final options = err.requestOptions;

    // Verificar si la operación es idempotente
    if (!_esOperacionIdempotente(options)) {
      return handler.next(err);
    }

    // Verificar si el error es transitorio (no 4xx)
    if (!_esErrorTransitorio(err)) {
      return handler.next(err);
    }

    final intentoActual = (options.extra['reintento_contador'] as int? ?? 0);

    if (intentoActual >= maxReintentos) {
      debugPrint('[RetryInterceptor] Límite de reintentos alcanzado ($maxReintentos) para ${options.path}');
      return handler.next(err);
    }

    final proximoIntento = intentoActual + 1;
    options.extra['reintento_contador'] = proximoIntento;

    // Cálculo de backoff exponencial: min(30, 2^intento) segundos
    final segundosEspera = min(30, pow(2, proximoIntento).toInt());
    debugPrint('[RetryInterceptor] Reintento $proximoIntento/$maxReintentos en ${segundosEspera}s para ${options.path}');

    await Future.delayed(Duration(seconds: segundosEspera));

    try {
      final respuesta = await dio.fetch(options);
      return handler.resolve(respuesta);
    } on DioException catch (nuevoErr) {
      return handler.next(nuevoErr);
    } catch (e) {
      return handler.next(err);
    }
  }

  /// Verifica si la petición es inherentemente idempotente o cuenta con clave de idempotencia
  bool _esOperacionIdempotente(RequestOptions options) {
    final metodo = options.method.toUpperCase();
    const metodosIdempotentes = {'GET', 'HEAD', 'OPTIONS', 'PUT', 'DELETE'};

    if (metodosIdempotentes.contains(metodo)) {
      return true;
    }

    // Si es POST o PATCH, solo es idempotente si porta la cabecera Idempotency-Key
    if (options.headers.containsKey('Idempotency-Key')) {
      return true;
    }

    return false;
  }

  /// Determina si el fallo es de red transitorio o error de servidor 5xx
  bool _esErrorTransitorio(DioException err) {
    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.connectionError) {
      return true;
    }

    final codigo = err.response?.statusCode;
    if (codigo != null && codigo >= 500 && codigo < 600) {
      return true;
    }

    return false;
  }
}
