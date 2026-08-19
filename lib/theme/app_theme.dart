import 'package:flutter/material.dart';
import 'tokens_app.dart';

class AppTheme {
  // Primitives
  static const Color _azul900 = Color(0xFF0D47A1);
  static const Color _gris100 = Color(0xFFF5F5F5);
  static const Color _gris900 = Color(0xFF212121);
  static const Color _rojoError = Color(0xFFB00020);
  
  // Semantic Colors mapped to ColorScheme
  static final ThemeData claro = ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme.light(
      primary: _azul900,
      surface: _gris100,
      onSurface: _gris900,
      error: _rojoError,
    ),
    textTheme: const TextTheme(
      titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _gris900),
      bodyMedium: TextStyle(fontSize: 16, color: _gris900),
      labelLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    ),
    extensions: const <ThemeExtension<dynamic>>[
      TokensApp(
        espacioBase: 8.0,
        radioTarjeta: 12.0,
        duracionTransicion: Duration(milliseconds: 250),
      ),
    ],
  );
}
