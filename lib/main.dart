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

class FichaAIApp extends StatelessWidget {
  final AuthProvider authProvider;
  final FichaProvider fichaProvider;

  const FichaAIApp({
    super.key,
    required this.authProvider,
    required this.fichaProvider,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider.value(value: fichaProvider),
        ChangeNotifierProvider.value(value: ConnectivityService.instance),
        ChangeNotifierProvider.value(value: SyncService.instance),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          return MaterialApp.router(
            title: 'FichaAI',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.claro,
            routerConfig: AppRouter.createRouter(auth),
          );
        },
      ),
    );
  }
}
