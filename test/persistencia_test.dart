import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:fichaai_mobile/models/ficha_model.dart';
import 'package:fichaai_mobile/models/operacion_pendiente_model.dart';

void main() {
  // Inicializar FFI para SQLite en el entorno de pruebas de escritorio
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('Pruebas Unitarias - Persistencia Local y Outbox (Semana 12)', () {
    test('FichaModel serializa y deserializa campos de sincronización y LWW', () {
      final ficha = FichaModel(
        idLocal: 'uuid-local-123',
        idServidor: 'srv-999',
        modelo: 'Google Pixel 8 Pro',
        fabricante: 'Google',
        procesador: 'Google Tensor G3',
        ram: '12 GB RAM',
        precioOficial: 999.0,
        sincronizado: false,
        fechaServidor: '2026-09-04T12:00:00.000Z',
        fechaGuardadoLocal: '2026-09-04T12:05:00.000Z',
      );

      final map = ficha.toMapLocal();
      expect(map['id_local'], 'uuid-local-123');
      expect(map['id_servidor'], 'srv-999');
      expect(map['sincronizado'], 0); // 0 = pendiente de sync en SQLite
      expect(map['fecha_servidor'], '2026-09-04T12:00:00.000Z');

      final deserializada = FichaModel.fromMapLocal(map);
      expect(deserializada.idLocal, 'uuid-local-123');
      expect(deserializada.idServidor, 'srv-999');
      expect(deserializada.sincronizado, false);
      expect(deserializada.modelo, 'Google Pixel 8 Pro');
      expect(deserializada.precioOficial, 999.0);
    });

    test('OperacionPendienteModel calcula backoff exponencial creciente', () {
      final op0 = OperacionPendienteModel(
        idOperacion: 'op-uuid-1',
        tipoOperacion: 'CREAR_FICHA',
        idEntidadLocal: 'entidad-1',
        payload: '{}',
        intentos: 0,
        creadoEn: DateTime.now().toIso8601String(),
      );
      expect(op0.tiempoEsperaReintento.inSeconds, 1); // 2^0 = 1s

      final op1 = op0.copyWith(intentos: 1);
      expect(op1.tiempoEsperaReintento.inSeconds, 2); // 2^1 = 2s

      final op2 = op0.copyWith(intentos: 2);
      expect(op2.tiempoEsperaReintento.inSeconds, 4); // 2^2 = 4s

      final op3 = op0.copyWith(intentos: 3);
      expect(op3.tiempoEsperaReintento.inSeconds, 8); // 2^3 = 8s

      final op4 = op0.copyWith(intentos: 4);
      expect(op4.tiempoEsperaReintento.inSeconds, 16); // 2^4 = 16s

      final op5 = op0.copyWith(intentos: 5);
      expect(op5.tiempoEsperaReintento.inSeconds, 30); // Acotado a 30s max
    });

    test('SQLite en memoria: Flujo completo de escritura offline, cola Outbox y reconciliación LWW', () async {
      final db = await databaseFactory.openDatabase(inMemoryDatabasePath);

      // 1. Crear esquema idéntico a DatabaseHelper
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

      // 2. Escritura Offline: Registro local no sincronizado
      final fichaOffline = FichaModel(
        idLocal: 'loc_offline_001',
        modelo: 'Xiaomi 15 Pro',
        fabricante: 'Xiaomi',
        precioOficial: 899.0,
        sincronizado: false,
        fechaGuardadoLocal: DateTime.now().toIso8601String(),
      );
      await db.insert('fichas', fichaOffline.toMapLocal());

      // 3. Encolar en Outbox con UUID único de cliente
      final opOutbox = OperacionPendienteModel(
        idOperacion: 'uuid-outbox-abc-123',
        tipoOperacion: 'CREAR_FICHA',
        idEntidadLocal: 'loc_offline_001',
        payload: jsonEncode(fichaOffline.toJson()),
        creadoEn: DateTime.now().toIso8601String(),
      );
      await db.insert('cola_operaciones', opOutbox.toMap());

      // Verificar que la ficha y la operación existen en SQLite
      final fichasGuardadas = await db.query('fichas');
      expect(fichasGuardadas.length, 1);
      expect(fichasGuardadas.first['sincronizado'], 0);

      final opsGuardadas = await db.query('cola_operaciones');
      expect(opsGuardadas.length, 1);
      expect(opsGuardadas.first['id_operacion'], 'uuid-outbox-abc-123');

      // 4. Simular confirmación del servidor con marca de tiempo del backend
      final fechaServidorConfirmada = '2026-09-04T14:40:00.000Z';
      await db.update(
        'fichas',
        {
          'id_servidor': 'srv_uuid_xiaomi_15',
          'sincronizado': 1,
          'fecha_servidor': fechaServidorConfirmada,
        },
        where: 'id_local = ?',
        whereArgs: ['loc_offline_001'],
      );
      // Eliminar de la cola Outbox al sincronizarse
      await db.delete('cola_operaciones', where: 'id_operacion = ?', whereArgs: ['uuid-outbox-abc-123']);

      final fichaActualizada = await db.query('fichas', where: 'id_local = ?', whereArgs: ['loc_offline_001']);
      expect(fichaActualizada.first['sincronizado'], 1);
      expect(fichaActualizada.first['id_servidor'], 'srv_uuid_xiaomi_15');
      expect(fichaActualizada.first['fecha_servidor'], fechaServidorConfirmada);

      final opsRestantes = await db.query('cola_operaciones');
      expect(opsRestantes.isEmpty, true);

      // 5. Purga Total (Cierre de Sesión / LOPDP)
      await db.delete('cola_operaciones');
      await db.delete('fichas');

      final fichasTrasPurga = await db.query('fichas');
      final opsTrasPurga = await db.query('cola_operaciones');
      expect(fichasTrasPurga.isEmpty, true);
      expect(opsTrasPurga.isEmpty, true);

      await db.close();
    });
  });
}
