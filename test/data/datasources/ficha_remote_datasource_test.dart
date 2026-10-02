import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dio/dio.dart';
import 'package:fichaai_mobile/data/datasources/ficha_remote_datasource.dart';
import 'package:fichaai_mobile/models/dto/ficha_dto.dart';
import 'package:fichaai_mobile/core/errors/fallo_red.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late FichaFuenteRemota datasource;
  late MockDio mockDio;

  setUp(() {
    mockDio = MockDio();
    datasource = FichaFuenteRemota(dio: mockDio);
  });

  group('FichaFuenteRemota Tests - HTTP Double', () {
    test('listarFichas retorna lista de DTOs en estado 200 OK', () async {
      final respuestaSimulada = Response(
        requestOptions: RequestOptions(path: '/fichas'),
        statusCode: 200,
        data: {
          'exito': true,
          'datos': [
            {'id_ficha': '1', 'modelo': 'Celular 1'},
            {'id_ficha': '2', 'modelo': 'Celular 2'},
          ]
        },
      );

      when(() => mockDio.get(
            any(),
            queryParameters: any(named: 'queryParameters'),
          )).thenAnswer((_) async => respuestaSimulada);

      final resultado = await datasource.listarFichas();

      expect(resultado.length, 2);
      expect(resultado.first.modelo, 'Celular 1');
    });

    test('crearFicha arroja FalloCliente con errores 422 en estado 422', () async {
      final respuestaSimulada = Response(
        requestOptions: RequestOptions(path: '/fichas'),
        statusCode: 422,
        data: {
          'exito': false,
          'mensaje': 'Datos inválidos',
          'errores': [
            {'campo': 'precio_oficial', 'mensaje': 'El precio no puede ser negativo'}
          ]
        },
      );

      when(() => mockDio.post(
            any(),
            data: any(named: 'data'),
            options: any(named: 'options'),
          )).thenThrow(DioException(
        requestOptions: RequestOptions(path: '/fichas'),
        response: respuestaSimulada,
        type: DioExceptionType.badResponse,
      ));

      final dto = FichaDto(idFicha: '1', modelo: 'Test');

      try {
        await datasource.crearFicha(dto);
        fail('Debería haber lanzado una excepción');
      } catch (e) {
        expect(e, isA<FalloCliente>());
        final fallo = e as FalloCliente;
        expect(fallo.es422Validacion, true);
        expect(fallo.erroresPorCampo['precio_oficial'], 'El precio no puede ser negativo');
      }
    });

    test('lanza FalloTimeout cuando hay timeout (tiempo de espera agotado)', () async {
      when(() => mockDio.get(
            any(),
            queryParameters: any(named: 'queryParameters'),
          )).thenThrow(DioException(
        requestOptions: RequestOptions(path: '/fichas'),
        type: DioExceptionType.connectionTimeout,
      ));

      expect(() => datasource.listarFichas(), throwsA(isA<FalloTimeout>()));
    });
    
    test('simular 401 y arroja FalloCliente es401NoAutorizado', () async {
      final respuestaSimulada = Response(
        requestOptions: RequestOptions(path: '/fichas'),
        statusCode: 401,
      );

      when(() => mockDio.get(
            any(),
            queryParameters: any(named: 'queryParameters'),
          )).thenThrow(DioException(
        requestOptions: RequestOptions(path: '/fichas'),
        response: respuestaSimulada,
        type: DioExceptionType.badResponse,
      ));

      try {
        await datasource.listarFichas();
        fail('Debería haber lanzado una excepción');
      } catch (e) {
        expect(e, isA<FalloCliente>());
        final fallo = e as FalloCliente;
        expect(fallo.es401NoAutorizado, true);
      }
    });
  });
}
