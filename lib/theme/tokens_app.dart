import 'package:flutter/material.dart';
import 'dart:ui';

@immutable
class TokensApp extends ThemeExtension<TokensApp> {
  const TokensApp({
    required this.espacioBase,
    required this.radioTarjeta,
    required this.duracionTransicion,
  });

  final double espacioBase;
  final double radioTarjeta;
  final Duration duracionTransicion;

  @override
  TokensApp copyWith({
    double? espacioBase,
    double? radioTarjeta,
    Duration? duracionTransicion,
  }) {
    return TokensApp(
      espacioBase: espacioBase ?? this.espacioBase,
      radioTarjeta: radioTarjeta ?? this.radioTarjeta,
      duracionTransicion: duracionTransicion ?? this.duracionTransicion,
    );
  }

  @override
  TokensApp lerp(ThemeExtension<TokensApp>? otro, double t) {
    if (otro is! TokensApp) return this;
    return TokensApp(
      espacioBase: lerpDouble(espacioBase, otro.espacioBase, t)!,
      radioTarjeta: lerpDouble(radioTarjeta, otro.radioTarjeta, t)!,
      duracionTransicion: duracionTransicion,
    );
  }
}
