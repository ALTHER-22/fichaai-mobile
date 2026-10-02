import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../../core/errors/fallo_red.dart';
import '../../core/network/cliente_http.dart';
import '../../models/dto/ficha_dto.dart';

/// Fuente de Datos Remota (Remote Data Source):
/// Responsabilidad exclusiva: Ejecutar llamadas HTTP contra la API backend y mapear JSON a DTOs.
///
/// REGLA ARQUITECTÓNICA (Semana 13 - Criterio 5):
/// - Esta capa NO conoce la base de datos local ni decide si usar caché.
/// - Traduce códigos de error y respuestas de validación 422 a excepciones del dominio.
class FichaFuenteRemota {
  final Dio _dio;

  FichaFuenteRemota({Dio? dio}) : _dio = dio ?? ClienteHttp.instance.dio;

  /// Obtiene el catálogo de smartphones desde el servidor
  Future<List<FichaDto>> listarFichas({int pagina = 1, int limite = 50}) async {
    try {
      final respuesta = await _dio.get(
        '/fichas',
        queryParameters: {'pagina': pagina, 'limite': limite},
      );

      if (respuesta.statusCode == 200 && respuesta.data != null) {
        final data = respuesta.data;
        if (data['exito'] == true && data['datos'] is List) {
          return (data['datos'] as List)
              .map((item) => FichaDto.fromJson(item as Map<String, dynamic>))
              .toList();
        }
      }

      _procesarErroresHttp(respuesta);
      return [];
    } on DioException catch (e) {
      throw _mapearDioException(e);
    } catch (e) {
      if (e is FalloRed) rethrow;
      throw FalloInesperado(e.toString());
    }
  }

  /// Crea una nueva ficha técnica en el servidor con soporte de Idempotencia
  Future<FichaDto> crearFicha(FichaDto fichaDto, {String? idempotencyKey}) async {
    try {
      final cabeceras = <String, dynamic>{};
      if (idempotencyKey != null) {
        cabeceras['Idempotency-Key'] = idempotencyKey;
      }

      final respuesta = await _dio.post(
        '/fichas',
        data: fichaDto.toJson(),
        options: Options(headers: cabeceras),
      );

      if (respuesta.statusCode == 201 && respuesta.data != null) {
        final data = respuesta.data;
        if (data['datos'] != null) {
          return FichaDto.fromJson(data['datos'] as Map<String, dynamic>);
        }
      }

      // Si el servidor respondió con 422 o error de cliente dentro de validateStatus < 500
      _procesarErroresHttp(respuesta);
      throw const FalloServidor('No se pudo confirmar la creación en el servidor');
    } on DioException catch (e) {
      throw _mapearDioException(e);
    } catch (e) {
      if (e is FalloRed) rethrow;
      throw FalloInesperado(e.toString());
    }
  }

  /// Extracción asistida con IA (Gemini a través del backend)
  Future<FichaDto?> extraerFichaIA(String texto) async {
    try {
      final respuesta = await _dio.post(
        '/fichas/extraer-ia',
        data: {'texto': texto},
        options: Options(
          connectTimeout: const Duration(seconds: 20),
          receiveTimeout: const Duration(seconds: 60),
          sendTimeout: const Duration(seconds: 30),
        ),
      );

      if (respuesta.statusCode == 200 && respuesta.data != null) {
        final data = respuesta.data;
        if (data['exito'] == true && data['datos'] != null) {
          return FichaDto.fromJson(data['datos'] as Map<String, dynamic>);
        }
      }

      _procesarErroresHttp(respuesta);
      return null;
    } on DioException catch (e) {
      debugPrint('[FichaRemoteDataSource] DioException en extraerFichaIA: $e');
      throw _mapearDioException(e);
    } catch (e) {
      debugPrint('[FichaRemoteDataSource] Error en extraerFichaIA: $e');
      if (e is FalloRed) rethrow;
      throw FalloInesperado(e.toString());
    }
  }

  /// Procesa códigos HTTP interpretados por validateStatus < 500
  void _procesarErroresHttp(Response respuesta) {
    final status = respuesta.statusCode;
    final data = respuesta.data;

    if (status == 422) {
      final mapaErrores = <String, String>{};
      if (data is Map && data['errores'] is List) {
        for (final err in data['errores']) {
          if (err is Map && err['campo'] != null && err['mensaje'] != null) {
            mapaErrores[err['campo'].toString()] = err['mensaje'].toString();
          }
        }
      }
      throw FalloCliente(
        data is Map && data['mensaje'] != null
            ? data['mensaje'].toString()
            : 'Error de validación en los campos del formulario.',
        codigoEstado: 422,
        erroresPorCampo: mapaErrores,
      );
    }

    if (status == 400) {
      final msg = data is Map && data['mensaje'] != null ? data['mensaje'].toString() : 'Solicitud incorrecta';
      throw FalloCliente(msg, codigoEstado: 400);
    }

    if (status == 401) {
      throw const FalloCliente('Sesión no autorizada o credenciales expiradas.', codigoEstado: 401);
    }

    if (status == 404) {
      throw const FalloCliente('El recurso solicitado no existe.', codigoEstado: 404);
    }

    if (status != null && status >= 500) {
      throw FalloServidor('Error temporal del servidor ($status).', status);
    }
  }

  /// Mapea excepciones de Dio a la jerarquía sellada de FalloRed
  FalloRed _mapearDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const FalloTimeout();
      case DioExceptionType.connectionError:
        return const FalloSinConexion();
      case DioExceptionType.badResponse:
        final status = e.response?.statusCode;
        if (status == 422) {
          final data = e.response?.data;
          final mapaErrores = <String, String>{};
          if (data is Map && data['errores'] is List) {
            for (final err in data['errores']) {
              if (err is Map && err['campo'] != null && err['mensaje'] != null) {
                mapaErrores[err['campo'].toString()] = err['mensaje'].toString();
              }
            }
          }
          return FalloCliente(
            'Error de validación del servidor (422)',
            codigoEstado: 422,
            erroresPorCampo: mapaErrores,
          );
        }
        if (status != null && status >= 500) {
          return FalloServidor('Fallo en el servicio del backend ($status)', status);
        }
        final resData = e.response?.data;
        final mensajeError = (resData is Map && resData['mensaje'] != null)
            ? resData['mensaje'].toString()
            : 'Error en la petición (${e.response?.statusCode})';
        return FalloCliente(
          mensajeError,
          codigoEstado: e.response?.statusCode,
        );
      default:
        return FalloSinConexion(e.message ?? 'Fallo de conectividad con el servidor');
    }
  }
}
