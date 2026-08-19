import 'package:flutter/material.dart';
import '../theme/tokens_app.dart';

class TarjetaFicha extends StatelessWidget {
  const TarjetaFicha({
    super.key,
    required this.modelo,
    required this.fabricante,
    this.procesador,
    this.compacta = false,
    this.onPulsar,
    this.accionFinal,
  });

  final String modelo;
  final String fabricante;
  final String? procesador;
  final bool compacta;
  final VoidCallback? onPulsar;
  final Widget? accionFinal;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<TokensApp>()!;
    final tema = Theme.of(context);

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(tokens.radioTarjeta),
      ),
      child: InkWell(
        onTap: onPulsar,
        borderRadius: BorderRadius.circular(tokens.radioTarjeta),
        child: Padding(
          padding: EdgeInsets.all(compacta ? tokens.espacioBase : tokens.espacioBase * 2),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(modelo, style: tema.textTheme.titleLarge),
                    SizedBox(height: tokens.espacioBase * 0.5),
                    Text(fabricante, style: tema.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                    if (!compacta && procesador != null) ...[
                      SizedBox(height: tokens.espacioBase),
                      Text('Procesador: $procesador', style: tema.textTheme.bodyMedium),
                    ]
                  ],
                ),
              ),
              accionFinal ?? const SizedBox.shrink(),
            ],
          ),
        ),
      ),
    );
  }
}
