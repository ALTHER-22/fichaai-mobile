import 'package:flutter_test/flutter_test.dart';
import 'package:fichaai_mobile/main.dart';
import 'package:fichaai_mobile/providers/auth_provider.dart';
import 'package:fichaai_mobile/providers/ficha_provider.dart';

void main() {
  testWidgets('Smoke test de inicialización de la aplicación FichaAI', (WidgetTester tester) async {
    final authProvider = AuthProvider();
    final fichaProvider = FichaProvider();

    await tester.pumpWidget(FichaAIApp(
      authProvider: authProvider,
      fichaProvider: fichaProvider,
    ));

    // Verificar que el título de la aplicación se renderiza
    expect(find.text('FichaAI'), findsWidgets);
  });
}
