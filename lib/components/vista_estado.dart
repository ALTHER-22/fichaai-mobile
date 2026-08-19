import 'package:flutter/material.dart';
import '../theme/tokens_app.dart';
import 'boton_primario.dart';

enum TipoVistaEstado { cargando, vacio, error }

class VistaEstado extends StatelessWidget {
  const VistaEstado({
    super.key,
    required this.tipo,
    required this.mensaje,
    this.onReintentar,
  });

  final TipoVistaEstado tipo;
  final String mensaje;
  final VoidCallback? onReintentar;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<TokensApp>()!;
    final tema = Theme.of(context);

    IconData icono;
    switch (tipo) {
      case TipoVistaEstado.cargando:
        icono = Icons.hourglass_empty;
        break;
      case TipoVistaEstado.vacio:
        icono = Icons.inbox;
        break;
      case TipoVistaEstado.error:
        icono = Icons.error_outline;
        break;
    }

    return Center(
      child: Padding(
        padding: EdgeInsets.all(tokens.espacioBase * 3),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (tipo == TipoVistaEstado.cargando)
              const CircularProgressIndicator()
            else
              Icon(icono, size: 64, color: tema.colorScheme.onSurface.withValues(alpha: 0.5)),
            SizedBox(height: tokens.espacioBase * 2),
            Text(
              mensaje,
              textAlign: TextAlign.center,
              style: tema.textTheme.bodyMedium,
            ),
            if (tipo == TipoVistaEstado.error && onReintentar != null) ...[
              SizedBox(height: tokens.espacioBase * 3),
              BotonPrimario(
                texto: 'Reintentar',
                onPulsar: onReintentar,
              ),
            ]
          ],
        ),
      ),
    );
  }
}
