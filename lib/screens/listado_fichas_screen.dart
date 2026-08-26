import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/ficha_provider.dart';
import '../components/vista_estado.dart';
import '../components/tarjeta_ficha.dart';
import '../theme/tokens_app.dart';

class ListadoFichasScreen extends StatelessWidget {
  const ListadoFichasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<TokensApp>()!;
    final fichaProvider = context.watch<FichaProvider>();
    final fichas = fichaProvider.fichas;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Catálogo de Dispositivos'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Ir al Buscador con IA',
            onPressed: () => context.go('/'),
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (fichas.isEmpty) {
              return VistaEstado(
                tipo: TipoVistaEstado.vacio,
                mensaje: 'No hay dispositivos registrados en el catálogo.',
                onReintentar: () => context.go('/'),
              );
            }

            // Comportamiento responsivo: cuadrícula en pantallas anchas, lista en estrechas
            final bool esAncho = constraints.maxWidth > 600;

            return GridView.builder(
              padding: EdgeInsets.all(tokens.espacioBase * 2),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: esAncho ? 2 : 1,
                mainAxisExtent: esAncho ? 160 : null,
                crossAxisSpacing: tokens.espacioBase * 2,
                mainAxisSpacing: tokens.espacioBase * 2,
                childAspectRatio: esAncho ? 1 : 3,
              ),
              itemCount: fichas.length,
              itemBuilder: (context, index) {
                final ficha = fichas[index];
                return TarjetaFicha(
                  modelo: ficha.modelo,
                  fabricante: ficha.fabricante ?? 'Oficial',
                  procesador: ficha.procesador,
                  compacta: !esAncho,
                  onPulsar: () {
                    // Navegación declarativa hacia el detalle con parámetro de ruta
                    context.go('/fichas/${ficha.idFicha ?? index}');
                  },
                  accionFinal: Semantics(
                    label: 'Ver detalles de ${ficha.modelo}',
                    button: true,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_forward_ios, size: 16),
                      onPressed: () => context.go('/fichas/${ficha.idFicha ?? index}'),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Nueva Ficha'),
        onPressed: () => context.go('/admin/nueva-ficha'),
      ),
    );
  }
}
