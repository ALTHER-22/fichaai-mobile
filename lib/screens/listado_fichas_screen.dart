import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../providers/ficha_provider.dart';
import '../services/connectivity_service.dart';
import '../services/sync_service.dart';
import '../components/vista_estado.dart';
import '../components/tarjeta_ficha.dart';
import '../theme/tokens_app.dart';

class ListadoFichasScreen extends StatelessWidget {
  const ListadoFichasScreen({super.key});

  String _formatearFecha(DateTime? fecha) {
    if (fecha == null) return 'Sin registro previo';
    final formato = DateFormat('dd/MM/yyyy HH:mm:ss');
    final diferencia = DateTime.now().difference(fecha);

    if (diferencia.inSeconds < 60) {
      return 'Hace ${diferencia.inSeconds} seg (${formato.format(fecha)})';
    } else if (diferencia.inMinutes < 60) {
      return 'Hace ${diferencia.inMinutes} min (${formato.format(fecha)})';
    } else {
      return formato.format(fecha);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<TokensApp>()!;
    final fichaProvider = context.watch<FichaProvider>();
    final connectivity = context.watch<ConnectivityService>();
    final syncService = context.watch<SyncService>();
    final authProvider = context.watch<AuthProvider>();
    final fichas = fichaProvider.fichas;

    final estaOffline = !connectivity.estaConectado;
    final fechaSync = fichaProvider.ultimaSincronizacion;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 10,
        title: const Text('Catálogo', style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        actions: [
          if (authProvider.estaAutenticado)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
              child: Chip(
                avatar: CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: const Icon(Icons.person, size: 14, color: Colors.white),
                ),
                label: Text(
                  '${authProvider.usuario}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                backgroundColor: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                padding: const EdgeInsets.symmetric(horizontal: 2),
              ),
            ),
          // Botón para forzar sincronización manual de la cola Outbox
          if (syncService.sincronizando)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            IconButton(
              icon: Badge(
                isLabelVisible: syncService.operacionesPendientes > 0,
                label: Text('${syncService.operacionesPendientes}'),
                child: const Icon(Icons.sync),
              ),
              tooltip: 'Sincronizar cola Outbox ahora',
              onPressed: () async {
                final token = authProvider.token;
                await fichaProvider.forzarSincronizacion(token: token);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(syncService.ultimoMensajeSync ?? 'Sincronización procesada.'),
                      backgroundColor: estaOffline ? Colors.orange : Colors.green,
                    ),
                  );
                }
              },
            ),
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Ir al Buscador con IA',
            onPressed: () => context.go('/'),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // =======================================================
            // INDICADOR VISIBLE DE ANTIGÜEDAD Y ESTADO SIN CONEXIÓN
            // =======================================================
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: estaOffline ? Colors.amber.shade100 : Colors.green.shade50,
                border: Border(
                  bottom: BorderSide(
                    color: estaOffline ? Colors.amber.shade700 : Colors.green.shade600,
                    width: 1.5,
                  ),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    estaOffline ? Icons.airplanemode_active : Icons.cloud_done,
                    color: estaOffline ? Colors.deepOrange.shade800 : Colors.green.shade800,
                    size: 26,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          estaOffline
                              ? 'MODO SIN CONEXIÓN (MODO AVIÓN ACTIVO)'
                              : 'CONEXIÓN ESTABLE CON EL SERVIDOR',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: estaOffline ? Colors.deepOrange.shade900 : Colors.green.shade900,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          estaOffline
                              ? 'Mostrando datos almacenados en SQLite local. Antigüedad del catálogo: ${_formatearFecha(fechaSync)}. Advertencia: los datos pueden estar desactualizados.'
                              : 'Base de datos local SQLite sincronizada. Última verificación: ${_formatearFecha(fechaSync)}.',
                          style: TextStyle(
                            fontSize: 11,
                            color: estaOffline ? Colors.brown.shade900 : Colors.green.shade900,
                            height: 1.3,
                          ),
                        ),
                        if (syncService.operacionesPendientes > 0) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade200,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '📦 ${syncService.operacionesPendientes} operación(es) pendiente(s) en la cola Outbox con reintentos crecientes.',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.brown.shade900,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // =======================================================
            // LISTADO DE FICHAS CON LECTURA DESDE SQLITE LOCAL
            // =======================================================
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  await fichaProvider.forzarSincronizacion(token: authProvider.token);
                },
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    if (fichas.isEmpty) {
                      return VistaEstado(
                        tipo: TipoVistaEstado.vacio,
                        mensaje: estaOffline
                            ? 'No hay dispositivos guardados en la memoria local.'
                            : 'No hay dispositivos registrados en el catálogo.',
                        onReintentar: () => context.go('/'),
                      );
                    }

                    final bool esAncho = constraints.maxWidth > 600;

                    return GridView.builder(
                      padding: EdgeInsets.all(tokens.espacioBase * 2),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: esAncho ? 2 : 1,
                        mainAxisExtent: esAncho ? 170 : null,
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
                          sincronizado: ficha.sincronizado,
                          onPulsar: () {
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
            ),
          ],
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
