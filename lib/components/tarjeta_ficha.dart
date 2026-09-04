import 'package:flutter/material.dart';
import '../theme/tokens_app.dart';

class TarjetaFicha extends StatelessWidget {
  const TarjetaFicha({
    super.key,
    required this.modelo,
    required this.fabricante,
    this.procesador,
    this.compacta = false,
    this.sincronizado = true,
    this.onPulsar,
    this.accionFinal,
  });

  final String modelo;
  final String fabricante;
  final String? procesador;
  final bool compacta;
  final bool sincronizado;
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
      elevation: 2,
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
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            modelo,
                            style: tema.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Distintivo visible de sincronización / offline
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: sincronizado ? Colors.green.shade50 : Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: sincronizado ? Colors.green.shade600 : Colors.amber.shade800,
                              width: 0.8,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                sincronizado ? Icons.check_circle : Icons.cloud_off,
                                size: 12,
                                color: sincronizado ? Colors.green.shade700 : Colors.amber.shade900,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                sincronizado ? 'Sincronizado' : 'Offline / Pendiente',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: sincronizado ? Colors.green.shade800 : Colors.amber.shade900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: tokens.espacioBase * 0.5),
                    Text(
                      fabricante,
                      style: tema.textTheme.bodyMedium?.copyWith(
                        color: tema.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (!compacta && procesador != null) ...[
                      SizedBox(height: tokens.espacioBase * 0.5),
                      Text(
                        'Procesador: $procesador',
                        style: tema.textTheme.bodySmall?.copyWith(color: Colors.grey.shade700),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
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
