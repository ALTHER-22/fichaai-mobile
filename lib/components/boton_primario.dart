import 'package:flutter/material.dart';

class BotonPrimario extends StatelessWidget {
  const BotonPrimario({
    super.key,
    required this.texto,
    this.onPulsar,
    this.cargando = false,
  });

  final String texto;
  final VoidCallback? onPulsar;
  final bool cargando;

  @override
  Widget build(BuildContext context) {
    // El area tctil mnima es asegurada por el mnimo por defecto de Material 3, pero la forzamos explcitamente.
    return Semantics(
      button: true,
      enabled: onPulsar != null && !cargando,
      label: texto,
      child: ElevatedButton(
        onPressed: cargando ? null : onPulsar,
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 48), // WCAG 2.2 area tctil >= 44-48
        ),
        child: cargando
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              )
            : Text(texto),
      ),
    );
  }
}
