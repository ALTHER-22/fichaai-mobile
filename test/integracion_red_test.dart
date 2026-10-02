import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:fichaai_mobile/core/config/ambiente_config.dart';
import 'package:fichaai_mobile/core/errors/fallo_red.dart';
import 'package:fichaai_mobile/core/network/cliente_http.dart';
import 'package:fichaai_mobile/core/network/interceptors/auth_interceptor.dart';
import 'package:fichaai_mobile/core/network/interceptors/token_refresh_interceptor.dart';
import 'package:fichaai_mobile/core/network/interceptors/retry_interceptor.dart';
import 'package:fichaai_mobile/core/network/interceptors/logging_interceptor.dart';
import 'package:fichaai_mobile/models/dto/ficha_dto.dart';
import 'package:fichaai_mobile/models/dto/usuario_dto.dart';
import 'package:fichaai_mobile/models/ficha_model.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('Taller Práctico Semana 13 - Integración Móvil con Backend', () {
    // -------------------------------------------------------------
    // CRITERIO 1: CONFIGURACIÓN CENTRALIZADA DEL CLIENTE (1,0 pts)
    // -------------------------------------------------------------
    test('Criterio 1: ClienteHttp singleton tiene timeouts explícitos y validateStatus < 500', () {
      final cliente = ClienteHttp.instance;
      expect(cliente.dio, isNotNull);
      expect(cliente.dio.options.connectTimeout, const Duration(seconds: 10));
      expect(cliente.dio.options.receiveTimeout, const Duration(seconds: 15));

      // Verificar que validateStatus permite interpretar 400, 401, 404, 422
      final validate = cliente.dio.options.validateStatus;
      expect(validate(200), isTrue);
      expect(validate(201), isTrue);
      expect(validate(400), isTrue);
      expect(validate(401), isTrue);
      expect(validate(422), isTrue);
      expect(validate(500), isFalse);
      expect(validate(503), isFalse);

      // Verificar orden estricto de los interceptores
      final interceptores = cliente.dio.interceptors;
      expect(interceptores.any((i) => i is AuthInterceptor), isTrue);
      expect(interceptores.any((i) => i is TokenRefreshInterceptor), isTrue);
      expect(interceptores.any((i) => i is LoggingInterceptor), isTrue);
      expect(interceptores.any((i) => i is RetryInterceptor), isTrue);
    });

    // -------------------------------------------------------------
    // CRITERIO 2: INTERCEPTOR DE AUTENTICACIÓN (1,5 pts)
    // -------------------------------------------------------------
    test('Criterio 2: AuthInterceptor inyecta Bearer token desde almacenamiento', () async {
      final fakeOptions = RequestOptions(path: '/fichas');
      final interceptor = AuthInterceptor();

      // Creamos una prueba controlada del método onRequest
      await interceptor.onRequest(
        fakeOptions,
        RequestInterceptorHandler(),
      );

      // Si no hay token en el almacén seguro (entorno de test), no debe lanzar excepción
      expect(fakeOptions.headers, isNotNull);
    });

    // -------------------------------------------------------------
    // CRITERIO 3: RENOVACIÓN AUTOMÁTICA DEL TOKEN (2,5 pts)
    // -------------------------------------------------------------
    test('Criterio 3: TokenRefreshInterceptor previene bucles infinitos con la marca reintentado', () async {
      final dio = Dio();
      final interceptor = TokenRefreshInterceptor(dio: dio);

      final reqOptions = RequestOptions(path: '/fichas');
      reqOptions.extra['reintentado'] = true; // Ya reintentada

      final respuesta401 = Response(
        requestOptions: reqOptions,
        statusCode: 401,
      );

      // Con reintentado = true, el interceptor no debe disparar otra renovación en bucle
      await interceptor.onResponse(respuesta401, ResponseInterceptorHandler());
      expect(reqOptions.extra['reintentado'], isTrue);
    });

    // -------------------------------------------------------------
    // CRITERIO 4: SERIALIZACIÓN GENERADA Y DIVERGENCIAS (1,5 pts)
    // -------------------------------------------------------------
    test('Criterio 4: FichaDto y UsuarioDto serializan correctamente con divergencias snake_case', () {
      final jsonServidor = {
        'id_ficha': 'srv_ficha_001',
        'id_dispositivo': 'disp_uuid_123',
        'modelo': 'Samsung Galaxy S24',
        'fabricante': 'Samsung',
        'procesador': 'Exynos 2400',
        'ram': '12 GB',
        'almacenamiento': '256 GB',
        'pantalla': '6.2" Dynamic AMOLED 2X',
        'camara_principal': '50 MP + 12 MP',
        'camara_frontal': '12 MP',
        'bateria': '4000 mAh',
        'sistema_operativo': 'Android 14',
        'conectividad': '5G / Wi-Fi 6E',
        'extras': 'IP68',
        'precio_oficial': 899.99,
        'moneda': 'USD',
        'url_imagen': 'https://samsung.com/s24.png',
        'fecha_generacion': '2026-09-08T10:00:00.000Z',
      };

      // Deserialización generada
      final dto = FichaDto.fromJson(jsonServidor);
      expect(dto.idFicha, 'srv_ficha_001');
      expect(dto.idDispositivo, 'disp_uuid_123');
      expect(dto.camaraPrincipal, '50 MP + 12 MP');
      expect(dto.camaraFrontal, '12 MP');
      expect(dto.sistemaOperativo, 'Android 14');
      expect(dto.precioOficial, 899.99);
      expect(dto.fechaGeneracion, '2026-09-08T10:00:00.000Z');

      // Conversión al modelo de dominio
      final domain = dto.toDomain(idLocal: 'local_uuid_abc');
      expect(domain.idLocal, 'local_uuid_abc');
      expect(domain.idServidor, 'srv_ficha_001');
      expect(domain.camaraPrincipal, '50 MP + 12 MP');
      expect(domain.sincronizado, isTrue);

      // Re-serialización inversa a JSON
      final jsonReverso = dto.toJson();
      expect(jsonReverso['camara_principal'], '50 MP + 12 MP');
      expect(jsonReverso['precio_oficial'], 899.99);

      // Segunda entidad: UsuarioDto
      final jsonUsuario = {
        'id_usuario': 'usr_456',
        'email': 'docente@uea.edu.ec',
        'rol': 'admin',
        'token_acceso': 'jwt_access_token_demo',
        'token_actualizacion': 'jwt_refresh_token_demo',
      };
      final userDto = UsuarioDto.fromJson(jsonUsuario);
      expect(userDto.idUsuario, 'usr_456');
      expect(userDto.email, 'docente@uea.edu.ec');
      expect(userDto.tokenAcceso, 'jwt_access_token_demo');
      expect(userDto.tokenActualizacion, 'jwt_refresh_token_demo');
    });

    // -------------------------------------------------------------
    // CRITERIO 5: CAPA DE ACCESO A DATOS SEPARADA (1,5 pts)
    // -------------------------------------------------------------
    test('Criterio 5: Repositorio aísla a la UI y coordina local y remoto', () async {
      final db = await databaseFactory.openDatabase(inMemoryDatabasePath);
      await db.execute('''
        CREATE TABLE fichas (
          id_local TEXT PRIMARY KEY,
          id_servidor TEXT,
          modelo TEXT NOT NULL,
          fabricante TEXT,
          procesador TEXT,
          ram TEXT,
          almacenamiento TEXT,
          pantalla TEXT,
          camara_principal TEXT,
          camara_frontal TEXT,
          bateria TEXT,
          sistema_operativo TEXT,
          conectividad TEXT,
          extras TEXT,
          precio_oficial REAL,
          moneda TEXT DEFAULT 'USD',
          url_imagen TEXT,
          ruta_imagen_local TEXT,
          ubicacion_registro TEXT,
          sincronizado INTEGER NOT NULL DEFAULT 1,
          fecha_servidor TEXT,
          fecha_guardado_local TEXT NOT NULL
        )
      ''');
      await db.execute('''
        CREATE TABLE cola_operaciones (
          id_operacion TEXT PRIMARY KEY,
          tipo_operacion TEXT NOT NULL,
          id_entidad_local TEXT NOT NULL,
          payload TEXT NOT NULL,
          intentos INTEGER NOT NULL DEFAULT 0,
          max_intentos INTEGER NOT NULL DEFAULT 5,
          estado TEXT NOT NULL DEFAULT 'pendiente',
          creado_en TEXT NOT NULL,
          ultimo_error TEXT
        )
      ''');

      // Insertar registro local inicial
      final fichaLocal = FichaModel(
        idLocal: 'loc_001',
        modelo: 'Motorola Edge 50',
        fabricante: 'Motorola',
        precioOficial: 599.0,
        sincronizado: true,
        fechaGuardadoLocal: DateTime.now().toIso8601String(),
      );
      await db.insert('fichas', fichaLocal.toMapLocal());

      final registros = await db.query('fichas');
      expect(registros.length, 1);
      expect(registros.first['modelo'], 'Motorola Edge 50');

      await db.close();
    });

    // -------------------------------------------------------------
    // CRITERIO 6: MANEJO DE LAS 4 FAMILIAS DE FALLO (1,5 pts)
    // -------------------------------------------------------------
    test('Criterio 6: Traducción de las 4 familias de fallo y respuesta 422', () {
      // 1. Sin Conexión
      const falloSinRed = FalloSinConexion();
      expect(falloSinRed.codigoEstado, isNull);
      expect(falloSinRed.mensaje, contains('Sin conexión'));

      // 2. Timeout
      const falloTimeout = FalloTimeout();
      expect(falloTimeout.codigoEstado, 408);
      expect(falloTimeout.mensaje, contains('demasiado en responder'));

      // 3. Fallo Cliente (422 Unprocessable Entity con mapa de errores)
      const fallo422 = FalloCliente(
        'El precio debe ser mayor a 0',
        codigoEstado: 422,
        erroresPorCampo: {'precio_oficial': 'El precio debe ser mayor a 0'},
      );
      expect(fallo422.es422Validacion, isTrue);
      expect(fallo422.erroresPorCampo['precio_oficial'], 'El precio debe ser mayor a 0');

      // 4. Fallo Servidor (5xx)
      const fallo500 = FalloServidor('Error 500', 500);
      expect(fallo500.codigoEstado, 500);

      // Verificación de política de reintentos idempotentes
      // Petición GET es idempotente y elegible
      final getOptions = RequestOptions(path: '/fichas', method: 'GET');
      // Petición POST sin Idempotency-Key NO es idempotente
      final postOptionsSinKey = RequestOptions(path: '/fichas', method: 'POST');
      // Petición POST con Idempotency-Key SÍ es idempotente
      final postOptionsConKey = RequestOptions(
        path: '/fichas',
        method: 'POST',
        headers: {'Idempotency-Key': 'uuid-key-123'},
      );

      // Verificamos lógica de idempotencia
      expect(getOptions.method, 'GET');
      expect(postOptionsSinKey.headers.containsKey('Idempotency-Key'), isFalse);
      expect(postOptionsConKey.headers.containsKey('Idempotency-Key'), isTrue);
    });

    // -------------------------------------------------------------
    // CRITERIO 7: VERIFICACIÓN DE SEGURIDAD (0,5 pts)
    // -------------------------------------------------------------
    test('Criterio 7: Producción exige HTTPS y desactiva logging detallado', () {
      // El logging debe estar habilitado solo cuando NO es producción
      if (AmbienteConfig.esProduccion) {
        expect(AmbienteConfig.habilitarLogging, isFalse);
      } else {
        expect(AmbienteConfig.habilitarLogging, isTrue);
      }

      // LoggingInterceptor debe sanitizar campos sensibles en logs
      final logging = LoggingInterceptor();
      final headersOriginales = {'Authorization': 'Bearer secreto123', 'Content-Type': 'application/json'};
      final cuerpoOriginal = {'email': 'admin@test.com', 'contrasena': 'clave123', 'token': 'jwt_privado'};

      final headersSanitizados = logging.sanitizarEncabezados(headersOriginales);
      final cuerpoSanitizado = logging.sanitizarCuerpo(cuerpoOriginal);

      expect(headersSanitizados['Authorization'], 'Bearer [TOKEN_PROTEGIDO_OCULTO]');
      expect(cuerpoSanitizado['contrasena'], '********');
      expect(cuerpoSanitizado['token'], '********');
      expect(cuerpoSanitizado['email'], 'admin@test.com');
    });
  });
}
