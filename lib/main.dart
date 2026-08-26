import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/ficha_provider.dart';
import 'routes/app_router.dart';

void main() {
  runApp(const FichaAIApp());
}

class FichaAIApp extends StatelessWidget {
  const FichaAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => FichaProvider()),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          return MaterialApp.router(
            title: 'FichaAI',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.claro,
            routerConfig: AppRouter.createRouter(authProvider),
          );
        },
      ),
    );
  }
}
