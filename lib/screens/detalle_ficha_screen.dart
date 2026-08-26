import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/ficha_provider.dart';
import '../models/ficha_model.dart';
import '../theme/tokens_app.dart';
import '../components/vista_estado.dart';

class DetalleFichaScreen extends StatelessWidget {
  final String idFicha;
  const DetalleFichaScreen({super.key, required this.idFicha});

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<TokensApp>()!;
    final tema = Theme.of(context);
    final fichaProvider = context.watch<FichaProvider>();

    // Obtener la ficha por su ID de ruta
    final FichaModel? ficha = fichaProvider.obtenerPorId(idFicha) ?? fichaProvider.resultadoBusquedaIA;

    if (ficha == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detalle de Ficha')),
        body: VistaEstado(
          tipo: TipoVistaEstado.error,
          mensaje: 'No se encontró la ficha técnica solicitada (ID: $idFicha).',
          onReintentar: () => context.go('/'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(ficha.modelo),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Compartir Ficha',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Enlace copiado: fichaai://app/fichas/$idFicha'),
                  backgroundColor: tema.colorScheme.primary,
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(tokens.espacioBase * 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabecera con imagen y precio
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(tokens.radioTarjeta),
              ),
              child: Padding(
                padding: EdgeInsets.all(tokens.espacioBase * 2),
                child: Column(
                  children: [
                    if (ficha.urlImagen != null && ficha.urlImagen!.isNotEmpty) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(tokens.radioTarjeta),
                        child: Image.network(
                          ficha.urlImagen!,
                          height: 200,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => Container(
                            height: 150,
                            color: Colors.grey.shade200,
                            child: const Center(
                              child: Icon(Icons.phone_android, size: 80, color: Colors.grey),
                            ),
                          ),
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return const SizedBox(
                              height: 150,
                              child: Center(child: CircularProgressIndicator()),
                            );
                          },
                        ),
                      ),
                      SizedBox(height: tokens.espacioBase * 2),
                    ],
                    Text(
                      ficha.modelo,
                      textAlign: TextAlign.center,
                      style: tema.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    if (ficha.fabricante != null) ...[
                      SizedBox(height: tokens.espacioBase * 0.5),
                      Text(
                        'Fabricante: ${ficha.fabricante}',
                        style: tema.textTheme.titleMedium?.copyWith(
                          color: tema.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    if (ficha.precioOficial != null) ...[
                      SizedBox(height: tokens.espacioBase),
                      Chip(
                        avatar: const Icon(Icons.attach_money, size: 18),
                        label: Text(
                          '${ficha.precioOficial} ${ficha.moneda}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        backgroundColor: Colors.green.shade100,
                      ),
                    ],
                  ],
                ),
              ),
            ),

            SizedBox(height: tokens.espacioBase * 2),
            Text(
              'Especificaciones Técnicas Oficiales',
              style: tema.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: tokens.espacioBase),

            // Tarjetas de especificaciones
            _buildSpecTile(context, Icons.screenshot_monitor, 'Pantalla', ficha.pantalla),
            _buildSpecTile(context, Icons.memory, 'Procesador', ficha.procesador),
            _buildSpecTile(context, Icons.speed, 'Memoria RAM', ficha.ram),
            _buildSpecTile(context, Icons.storage, 'Almacenamiento', ficha.almacenamiento),
            _buildSpecTile(context, Icons.camera_alt_outlined, 'Cámara Principal', ficha.camaraPrincipal),
            _buildSpecTile(context, Icons.camera_front_outlined, 'Cámara Frontal', ficha.camaraFrontal),
            _buildSpecTile(context, Icons.battery_charging_full, 'Batería y Carga', ficha.bateria),
            _buildSpecTile(context, Icons.settings_system_daydream, 'Sistema Operativo', ficha.sistemaOperativo),
            _buildSpecTile(context, Icons.wifi, 'Conectividad', ficha.conectividad),
            _buildSpecTile(context, Icons.stars_outlined, 'Extras y Resistencia', ficha.extras),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecTile(BuildContext context, IconData icon, String titulo, String? valor) {
    if (valor == null || valor.isEmpty) return const SizedBox.shrink();

    final tokens = Theme.of(context).extension<TokensApp>()!;
    final tema = Theme.of(context);

    return Card(
      margin: EdgeInsets.only(bottom: tokens.espacioBase),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(tokens.radioTarjeta),
      ),
      child: ListTile(
        leading: Icon(icon, color: tema.colorScheme.primary),
        title: Text(
          titulo,
          style: tema.textTheme.bodySmall?.copyWith(
            color: tema.colorScheme.onSurface.withValues(alpha: 0.6),
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          valor,
          style: tema.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}
