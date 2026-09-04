import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../models/ficha_model.dart';
import '../models/operacion_pendiente_model.dart';

/// Gestor de la base de datos local SQLite con migraciones versionadas y cola Outbox.
/// Aplica el principio de minimización (solo columnas requeridas por UI y sync).
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  DatabaseHelper._internal();

  static Database? _database;
  static const int _schemaVersion = 1;
  static const String _dbName = 'fichaai_local.db';

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    // Inicializar FFI para Windows / Linux o tests de escritorio
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    String rutaDb;
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux)) {
      final appDir = await getApplicationSupportDirectory();
      rutaDb = p.join(appDir.path, _dbName);
    } else {
      final dbPath = await getDatabasesPath();
      rutaDb = p.join(dbPath, _dbName);
    }

    return await openDatabase(
      rutaDb,
      version: _schemaVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    debugPrint('[DatabaseHelper] Creando esquema local v$version');

    // Tabla principal minimizada con campos de sincronización y LWW
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

    // Tabla de operaciones pendientes (Patrón Outbox para escrituras offline)
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

    // Cargar datos iniciales de demostración si la base es nueva
    await _insertarDatosIniciales(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    debugPrint('[DatabaseHelper] Migración incremental de v$oldVersion a v$newVersion');
    // Ejemplo de migración versionada futura sin destruir datos existentes del usuario:
    // if (oldVersion < 2) {
    //   await db.execute('ALTER TABLE fichas ADD COLUMN garantia_meses INTEGER;');
    // }
  }

  Future<void> _insertarDatosIniciales(Database db) async {
    final ahora = DateTime.now().toIso8601String();
    final datosSemilla = [
      {
        'id_local': 'seed_1_a55',
        'id_servidor': '1',
        'modelo': 'Samsung Galaxy A55 5G',
        'fabricante': 'Samsung',
        'procesador': 'Samsung Exynos 1480',
        'ram': '8 GB RAM',
        'almacenamiento': '256 GB',
        'pantalla': '6.6" Super AMOLED FHD+ 120Hz',
        'camara_principal': '50 MP f/1.8 OIS',
        'camara_frontal': '32 MP f/2.2',
        'bateria': '5000 mAh (25W)',
        'sistema_operativo': 'Android 14 con One UI 6.1',
        'conectividad': '5G, Wi-Fi 6, Bluetooth 5.3, NFC',
        'extras': 'IP67 resistencia al agua, Gorilla Glass Victus+',
        'precio_oficial': 449.0,
        'moneda': 'USD',
        'url_imagen': 'https://fdn2.gsmarena.com/vv/bigpic/samsung-galaxy-a55.jpg',
        'sincronizado': 1,
        'fecha_servidor': ahora,
        'fecha_guardado_local': ahora,
      },
      {
        'id_local': 'seed_2_spark20',
        'id_servidor': '2',
        'modelo': 'Tecno Spark 20 Pro Plus',
        'fabricante': 'Tecno',
        'procesador': 'MediaTek Helio G99 Ultimate',
        'ram': '8 GB RAM',
        'almacenamiento': '256 GB',
        'pantalla': '6.78" Curved AMOLED FHD+ a 120Hz',
        'camara_principal': '108 MP f/1.75 con PDAF',
        'camara_frontal': '32 MP con flash dual',
        'bateria': '5000 mAh (33W)',
        'sistema_operativo': 'Android 14 con HIOS 14',
        'conectividad': '4G LTE, Wi-Fi 5, Bluetooth 5.2, NFC',
        'extras': 'IP53 resistencia, huella en pantalla',
        'precio_oficial': 190.0,
        'moneda': 'USD',
        'url_imagen': 'https://fdn2.gsmarena.com/vv/bigpic/tecno-spark20-pro-plus.jpg',
        'sincronizado': 1,
        'fecha_servidor': ahora,
        'fecha_guardado_local': ahora,
      },
      {
        'id_local': 'seed_3_x14ultra',
        'id_servidor': '3',
        'modelo': 'Xiaomi 14 Ultra',
        'fabricante': 'Xiaomi',
        'procesador': 'Qualcomm Snapdragon 8 Gen 3',
        'ram': '16 GB RAM',
        'almacenamiento': '512 GB',
        'pantalla': '6.73" LTPO AMOLED WQHD+ 120Hz',
        'camara_principal': '50 MP (1 pulgada) Leica Quad-Cam',
        'camara_frontal': '32 MP',
        'bateria': '5000 mAh (90W cable / 80W inalámbrico)',
        'sistema_operativo': 'Android 14 con HyperOS',
        'conectividad': '5G, Wi-Fi 7, Bluetooth 5.4, NFC',
        'extras': 'IP68 titanio, cámaras ópticas Leica',
        'precio_oficial': 1499.0,
        'moneda': 'USD',
        'url_imagen': 'https://fdn2.gsmarena.com/vv/bigpic/xiaomi-14-ultra.jpg',
        'sincronizado': 1,
        'fecha_servidor': ahora,
        'fecha_guardado_local': ahora,
      }
    ];

    for (final item in datosSemilla) {
      await db.insert('fichas', item, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  // ==========================================
  // OPERACIONES SOBRE FICHAS TÉCNICAS
  // ==========================================

  Future<List<FichaModel>> obtenerTodasLasFichas() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'fichas',
      orderBy: 'sincronizado ASC, fecha_guardado_local DESC',
    );
    return maps.map((m) => FichaModel.fromMapLocal(m)).toList();
  }

  Future<FichaModel?> obtenerFichaPorId(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'fichas',
      where: 'id_local = ? OR id_servidor = ?',
      whereArgs: [id, id],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return FichaModel.fromMapLocal(maps.first);
    }
    return null;
  }

  Future<void> insertarOActualizarFicha(FichaModel ficha) async {
    final db = await database;
    await db.insert(
      'fichas',
      ficha.toMapLocal(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> marcarComoSincronizado({
    required String idLocal,
    required String idServidor,
    required String fechaServidor,
  }) async {
    final db = await database;
    await db.update(
      'fichas',
      {
        'id_servidor': idServidor,
        'sincronizado': 1,
        'fecha_servidor': fechaServidor,
      },
      where: 'id_local = ?',
      whereArgs: [idLocal],
    );
  }

  /// Estrategia de Reconciliación: La última escritura gana (Last-Write-Wins - LWW).
  /// Compara la marca de tiempo del servidor ('fecha_servidor'). Si la versión remota
  /// es más reciente, sobrescribe el registro local.
  /// SACRIFICIO DECLARADO: Se descartan cambios concurrentes anteriores de forma silenciosa.
  Future<void> reconciliarConLWW(FichaModel fichaRemota) async {
    final db = await database;
    final idBuscado = fichaRemota.idServidor ?? fichaRemota.idFicha;
    if (idBuscado == null) return;

    final locales = await db.query(
      'fichas',
      where: 'id_servidor = ?',
      whereArgs: [idBuscado],
    );

    if (locales.isEmpty) {
      // No existe localmente, insertar directo
      await db.insert('fichas', fichaRemota.toMapLocal());
      return;
    }

    final local = FichaModel.fromMapLocal(locales.first);

    // Si el registro local aún está pendiente de envío offline, no sobreescribir
    if (!local.sincronizado) {
      debugPrint('[LWW] Ficha local pendiente de sincronización, preservando cambio offline');
      return;
    }

    final fechaRemotaStr = fichaRemota.fechaServidor;
    final fechaLocalStr = local.fechaServidor;

    if (fechaRemotaStr != null && fechaLocalStr != null) {
      final fechaRemotaDt = DateTime.tryParse(fechaRemotaStr);
      final fechaLocalDt = DateTime.tryParse(fechaLocalStr);

      if (fechaRemotaDt != null && fechaLocalDt != null) {
        if (fechaRemotaDt.isAfter(fechaLocalDt) || fechaRemotaDt.isAtSameMomentAs(fechaLocalDt)) {
          await db.update(
            'fichas',
            fichaRemota.toMapLocal(),
            where: 'id_servidor = ?',
            whereArgs: [idBuscado],
          );
        }
        return;
      }
    }

    // Por defecto, la versión confirmada del servidor prevalece
    await db.update(
      'fichas',
      fichaRemota.toMapLocal(),
      where: 'id_servidor = ?',
      whereArgs: [idBuscado],
    );
  }

  // ==========================================
  // COLA OUTBOX (OPERACIONES PENDIENTES OFFLINE)
  // ==========================================

  Future<void> encolarOperacion(OperacionPendienteModel operacion) async {
    final db = await database;
    await db.insert(
      'cola_operaciones',
      operacion.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<OperacionPendienteModel>> obtenerOperacionesPendientes() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'cola_operaciones',
      where: 'estado = ? AND intentos < max_intentos',
      whereArgs: ['pendiente'],
      orderBy: 'creado_en ASC',
    );
    return maps.map((m) => OperacionPendienteModel.fromMap(m)).toList();
  }

  Future<void> actualizarOperacion(OperacionPendienteModel operacion) async {
    final db = await database;
    await db.update(
      'cola_operaciones',
      operacion.toMap(),
      where: 'id_operacion = ?',
      whereArgs: [operacion.idOperacion],
    );
  }

  Future<void> eliminarOperacion(String idOperacion) async {
    final db = await database;
    await db.delete(
      'cola_operaciones',
      where: 'id_operacion = ?',
      whereArgs: [idOperacion],
    );
  }

  Future<int> contarOperacionesPendientes() async {
    final db = await database;
    final res = await db.rawQuery(
      "SELECT COUNT(*) as total FROM cola_operaciones WHERE estado = 'pendiente' AND intentos < max_intentos",
    );
    return Sqflite.firstIntValue(res) ?? 0;
  }

  // ==========================================
  // PURGA COMPLETA (CIERRE DE SESIÓN / LOPDP)
  // ==========================================

  /// Elimina la totalidad de los datos locales de la base de datos al cerrar sesión.
  /// Cumple con la Ley Orgánica de Protección de Datos Personales (LOPDP Ecuador).
  Future<void> purgarTodo() async {
    final db = await database;
    await db.delete('cola_operaciones');
    await db.delete('fichas');
    debugPrint('[DatabaseHelper] Purga total de SQLite ejecutada exitosamente.');
  }
}
