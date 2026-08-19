import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/listado_fichas_screen.dart';

void main() {
  runApp(const FichaAIApp());
}

class FichaAIApp extends StatelessWidget {
  const FichaAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FichaAI',
      theme: AppTheme.claro,
      home: const ListadoFichasScreen(),
    );
  }
}
