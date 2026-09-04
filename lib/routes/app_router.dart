import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../screens/buscador_screen.dart';
import '../screens/listado_fichas_screen.dart';
import '../screens/detalle_ficha_screen.dart';
import '../screens/formulario_ficha_screen.dart';
import '../screens/login_screen.dart';

final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

class AppRouter {
  static GoRouter createRouter(AuthProvider authProvider) {
    return GoRouter(
      initialLocation: '/',
      refreshListenable: authProvider,
      routes: [
        // 1. Ruta Principal: Buscador Inteligente con IA
        GoRoute(
          path: '/',
          name: 'buscador',
          builder: (context, state) => const BuscadorScreen(),
        ),

        // 2. Ruta de Catálogo General
        GoRoute(
          path: '/catalogo',
          name: 'catalogo',
          builder: (context, state) => const ListadoFichasScreen(),
        ),

        // 3. Ruta de Detalle con Enlace Profundo (Deep Link /fichas/:id)
        GoRoute(
          path: '/fichas/:id',
          name: 'detalle_ficha',
          builder: (context, state) {
            final id = state.pathParameters['id'] ?? '1';
            return DetalleFichaScreen(idFicha: id);
          },
        ),

        // 4. Ruta de Autenticación
        GoRoute(
          path: '/login',
          name: 'login',
          builder: (context, state) {
            final from = state.uri.queryParameters['from'];
            return LoginScreen(redirectTo: from);
          },
        ),

        // 5. Ruta Protegida: Registrar Ficha (Requiere Auth)
        GoRoute(
          path: '/admin/nueva-ficha',
          name: 'nueva_ficha',
          builder: (context, state) => const FormularioFichaScreen(),
          redirect: (context, state) {
            // Guard de seguridad: si no está autenticado, redirigir a /login
            if (!authProvider.estaAutenticado) {
              return '/login?from=${state.matchedLocation}';
            }
            return null; // Permitir acceso
          },
        ),
      ],
      errorBuilder: (context, state) => Scaffold(
        appBar: AppBar(title: const Text('Error de Navegación')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Ruta no encontrada: ${state.uri.path}'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go('/'),
                child: const Text('Volver al Inicio'),
              )
            ],
          ),
        ),
      ),
    );
  }
}
