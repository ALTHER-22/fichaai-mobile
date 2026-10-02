import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:fichaai_mobile/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('E2E Test', () {
    testWidgets('Flujo crítico: Login y visualización de catálogo', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // 1. Pantalla de Login: ingresar credenciales
      final emailField = find.byType(TextFormField).first;
      final passwordField = find.byType(TextFormField).last;
      final loginButton = find.text('Iniciar Sesión');

      expect(emailField, findsOneWidget);
      expect(passwordField, findsOneWidget);

      await tester.enterText(emailField, 'test@ejemplo.com');
      await tester.enterText(passwordField, 'password123');
      await tester.pumpAndSettle();

      await tester.tap(loginButton);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // 2. Verifica si navegó al catálogo (o si falló login en caso de no tener mock del servidor)
      // En una prueba real, deberíamos mockear el cliente HTTP o apuntar a un servidor de staging.
      // Aquí comprobamos que estemos intentando cargar el catálogo.
      expect(find.text('Catálogo'), findsWidgets);
    });
  });
}
