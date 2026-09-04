import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/ficha_provider.dart';
import 'services/connectivity_service.dart';
import 'services/sync_service.dart';
import 'package:go_router/go_router.dart';
import 'routes/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Soporte multiplataforma para SQLite (Windows Desktop, Linux, Android, iOS)
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // Inicializar monitoreo en tiempo real de conectividad
  ConnectivityService.instance.inicializar();

  // Inicializar proveedor de autenticación y restaurar sesión segura desde Keystore/Keychain/DPAPI
  final authProvider = AuthProvider();
  await authProvider.inicializar();

  // Cargar catálogo local offline-first desde base de datos SQLite
  final fichaProvider = FichaProvider();
  await fichaProvider.cargarFichasLocales();

  // Inicializar worker de sincronización Outbox
  SyncService.instance.inicializar(getToken: () => authProvider.token);

  runApp(FichaAIApp(
    authProvider: authProvider,
    fichaProvider: fichaProvider,
  ));
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
