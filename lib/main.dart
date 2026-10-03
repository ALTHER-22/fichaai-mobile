import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/ficha_provider.dart';
import 'services/connectivity_service.dart';
import 'services/secure_storage_service.dart';
import 'services/sync_service.dart';
import 'core/network/cliente_http.dart';
import 'package:go_router/go_router.dart';
import 'routes/app_router.dart';

import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:fichaai_mobile/core/utils/logger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Soporte multiplataforma para SQLite (Windows Desktop, Linux, Android, iOS)
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // Inicializar monitoreo en tiempo real de conectividad
  ConnectivityService.instance.inicializar();

  // Inicializar servicio de almacenamiento seguro
  final secureStorage = SecureStorageService();

  // Inicializar proveedor de autenticación y restaurar sesión segura desde Keystore/Keychain/DPAPI
  final authProvider = AuthProvider(secureStorage: secureStorage);
  await authProvider.inicializar();

  // Inicializar cliente HTTP centralizado (Singleton con interceptores)
  ClienteHttp.inicializar(
    secureStorage: secureStorage,
    onSesionExpirada: () {
      authProvider.cerrarSesionPorExpiracion();
    },
  );

  // Cargar catálogo local offline-first desde base de datos SQLite y sincronizar en paralelo
  final fichaProvider = FichaProvider();
  await fichaProvider.cargarFichasLocales(sincronizarConServidor: false);
  fichaProvider.forzarSincronizacion();

  // Inicializar worker de sincronización Outbox
  SyncService.instance.inicializar(getToken: () => authProvider.token);

  // Inicializar Sentry condicionalmente para evitar ClassCastException y errores 400 con DSN falso
  const sentryDsn = String.fromEnvironment('SENTRY_DSN', defaultValue: '');
  if (sentryDsn.isNotEmpty) {
    await SentryFlutter.init(
      (options) {
        options.dsn = sentryDsn;
        options.tracesSampleRate = 1.0;
        
        // Filtrar encabezados de autorización (Punto de la Semana 15)
        options.beforeSend = (event, hint) {
          final request = event.request;
          if (request != null && request.headers.containsKey('Authorization')) {
            final newHeaders = Map<String, String>.from(request.headers);
            newHeaders['Authorization'] = '[FILTRADO]';
            return event.copyWith(request: request.copyWith(headers: newHeaders));
          }
          return event;
        };
      },
      appRunner: () => runApp(FichaAIApp(
        authProvider: authProvider,
        fichaProvider: fichaProvider,
      )),
    );
    if (authProvider.usuario != null) {
      Sentry.configureScope((scope) => scope.setUser(SentryUser(id: authProvider.usuario)));
    }
  } else {
    appLogger.i('Sentry en modo local/desarrollo (sin DSN configurado)');
    runApp(FichaAIApp(
      authProvider: authProvider,
      fichaProvider: fichaProvider,
    ));
  }
}

class FichaAIApp extends StatefulWidget {
  final AuthProvider authProvider;
  final FichaProvider fichaProvider;

  const FichaAIApp({
    super.key,
    required this.authProvider,
    required this.fichaProvider,
  });

  @override
  State<FichaAIApp> createState() => _FichaAIAppState();
}

class _FichaAIAppState extends State<FichaAIApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = AppRouter.createRouter(widget.authProvider);
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: widget.authProvider),
        ChangeNotifierProvider.value(value: widget.fichaProvider),
        ChangeNotifierProvider.value(value: ConnectivityService.instance),
        ChangeNotifierProvider.value(value: SyncService.instance),
      ],
      child: MaterialApp.router(
        scaffoldMessengerKey: rootScaffoldMessengerKey,
        title: 'FichaAI',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.claro,
        routerConfig: _router,
      ),
    );
  }
}

