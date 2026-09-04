import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/ficha_provider.dart';
import '../models/ficha_model.dart';
import '../routes/app_router.dart';
import '../theme/tokens_app.dart';
import '../components/boton_primario.dart';

class BuscadorScreen extends StatefulWidget {
  const BuscadorScreen({super.key});

  @override
  State<BuscadorScreen> createState() => _BuscadorScreenState();
}

class _BuscadorScreenState extends State<BuscadorScreen> {
  final _busquedaController = TextEditingController();

  @override
  void dispose() {
    _busquedaController.dispose();
    super.dispose();
  }

  void _ejecutarBusqueda(String consulta) {
    if (consulta.trim().isEmpty) return;
    _busquedaController.text = consulta;
    final token = context.read<AuthProvider>().token;
    context.read<FichaProvider>().buscarConIA(consulta, token: token);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<TokensApp>()!;
    final tema = Theme.of(context);
    final auth = context.watch<AuthProvider>();
    final fichaProvider = context.watch<FichaProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.auto_awesome, color: Colors.amber),
            const SizedBox(width: 8),
            Text('FichaAI', style: tema.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.list_alt),
            label: const Text('Catálogo'),
            onPressed: () => context.go('/catalogo'),
          ),
          if (auth.estaAutenticado) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
              child: Chip(
                avatar: CircleAvatar(
                  backgroundColor: tema.colorScheme.primary,
                  child: const Icon(Icons.person, size: 14, color: Colors.white),
                ),
                label: Text(
                  '${auth.usuario} (${auth.rol})',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: tema.colorScheme.primary,
                  ),
                ),
                backgroundColor: tema.colorScheme.primaryContainer.withValues(alpha: 0.3),
                side: BorderSide(color: tema.colorScheme.primary.withValues(alpha: 0.3)),
                padding: const EdgeInsets.symmetric(horizontal: 4),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Cerrar Sesión (${auth.usuario})',
              onPressed: () async {
                await auth.logout();
                if (context.mounted) {
                  context.read<FichaProvider>().limpiarMemoria();
                  rootScaffoldMessengerKey.currentState?.showSnackBar(
                    const SnackBar(
                      content: Text('Sesión cerrada: Credenciales cifradas y almacén SQLite purgados (Normativa LOPDP).'),
                      backgroundColor: Colors.blueGrey,
                      duration: Duration(seconds: 4),
                    ),
                  );
                }
              },
            ),
          ] else
            IconButton(
              icon: const Icon(Icons.account_circle_outlined),
              tooltip: 'Iniciar Sesión',
              onPressed: () => context.go('/login'),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(tokens.espacioBase * 2),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (auth.estaAutenticado) ...[
                  Container(
                    margin: EdgeInsets.only(bottom: tokens.espacioBase * 2),
                    padding: EdgeInsets.symmetric(
                      horizontal: tokens.espacioBase * 2,
                      vertical: tokens.espacioBase * 1.5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(tokens.radioTarjeta),
                      border: Border.all(color: Colors.green.shade300),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.verified_user, color: Colors.green.shade700, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '¡Bienvenido, ${auth.usuario}!',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade900,
                                  fontSize: 15,
                                ),
                              ),
                              Text(
                                'Sesión activa con rol "${auth.rol}". Token seguro almacenado en Keystore / Keychain.',
                                style: TextStyle(
                                  color: Colors.green.shade800,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                SizedBox(height: tokens.espacioBase),
                // Encabezado tipo Google
                Text(
                  'El Buscador Inteligente de Smartphones',
                  textAlign: TextAlign.center,
                  style: tema.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: tema.colorScheme.primary,
                  ),
                ),
                SizedBox(height: tokens.espacioBase),
                Text(
                  'Escribe cualquier modelo y la IA extraerá su ficha técnica oficial al instante.',
                  textAlign: TextAlign.center,
                  style: tema.textTheme.bodyMedium?.copyWith(
                    color: tema.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                SizedBox(height: tokens.espacioBase * 3),

                // Barra de Búsqueda
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.search, color: Colors.blueAccent),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _busquedaController,
                            decoration: const InputDecoration(
                              hintText: 'Ej: Samsung Galaxy A55, Tecno Spark 20...',
                              border: InputBorder.none,
                            ),
                            onSubmitted: _ejecutarBusqueda,
                          ),
                        ),
                        if (_busquedaController.text.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _busquedaController.clear();
                              setState(() {});
                            },
                          ),
                        IconButton(
                          icon: const Icon(Icons.arrow_forward),
                          color: tema.colorScheme.primary,
                          onPressed: () => _ejecutarBusqueda(_busquedaController.text),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: tokens.espacioBase * 1.5),

                // Sugerencias rápidas (Chips)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    _buildChip('Tecno Spark 20 Pro Plus'),
                    _buildChip('Samsung Galaxy A55 5G'),
                    _buildChip('Xiaomi 14 Ultra'),
                    _buildChip('iPhone 16 Pro'),
                  ],
                ),

                SizedBox(height: tokens.espacioBase * 3),

                // Estado de Carga con IA
                if (fichaProvider.buscandoIA) ...[
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(tokens.radioTarjeta),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(tokens.espacioBase * 3),
                      child: Column(
                        children: [
                          const CircularProgressIndicator(),
                          SizedBox(height: tokens.espacioBase * 2),
                          const Text(
                            'Consultando a Google Gemini AI y analizando especificaciones oficiales...',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ),
                ] else if (fichaProvider.resultadoBusquedaIA != null) ...[
                  // Tarjeta con el resultado de la IA
                  _buildResultadoIACard(context, fichaProvider.resultadoBusquedaIA!),
                ],
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Registrar Ficha (Admin)'),
        onPressed: () {
          // Navegar a ruta protegida: Si no está autenticado, go_router redirige a /login
          context.go('/admin/nueva-ficha');
        },
      ),
    );
  }

  Widget _buildChip(String texto) {
    return ActionChip(
      avatar: const Icon(Icons.smartphone, size: 16),
      label: Text(texto),
      onPressed: () => _ejecutarBusqueda(texto),
    );
  }

  Widget _buildResultadoIACard(BuildContext context, FichaModel ficha) {
    final tokens = Theme.of(context).extension<TokensApp>()!;
    final tema = Theme.of(context);

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(tokens.radioTarjeta),
      ),
      child: Padding(
        padding: EdgeInsets.all(tokens.espacioBase * 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome, color: Colors.amber, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Ficha Técnica Extraída por IA',
                  style: tema.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: tema.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const Divider(),
            SizedBox(height: tokens.espacioBase),

            if (ficha.urlImagen != null) ...[
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(tokens.radioTarjeta),
                  child: Image.network(
                    ficha.urlImagen!,
                    height: 140,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.phone_android, size: 60),
                  ),
                ),
              ),
              SizedBox(height: tokens.espacioBase),
            ],

            Text(
              ficha.modelo,
              style: tema.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            if (ficha.precioOficial != null)
              Text(
                'Precio oficial aprox: \$${ficha.precioOficial} ${ficha.moneda}',
                style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
              ),
            SizedBox(height: tokens.espacioBase),

            // Resumen de especificaciones
            _buildMiniSpec('🖥️ Pantalla:', ficha.pantalla),
            _buildMiniSpec('⚡ Procesador:', ficha.procesador),
            _buildMiniSpec('🧠 RAM:', ficha.ram),
            _buildMiniSpec('📸 Cámara:', ficha.camaraPrincipal),
            _buildMiniSpec('🔋 Batería:', ficha.bateria),

            SizedBox(height: tokens.espacioBase * 2),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.visibility),
                    label: const Text('Ver Detalle'),
                    onPressed: () {
                      context.go('/fichas/${ficha.idFicha ?? "temp"}');
                    },
                  ),
                ),
                SizedBox(width: tokens.espacioBase),
                Expanded(
                  child: BotonPrimario(
                    texto: 'Publicar (Admin)',
                    onPulsar: () {
                      context.go('/admin/nueva-ficha');
                    },
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildMiniSpec(String etiqueta, String? valor) {
    if (valor == null || valor.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(etiqueta, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          ),
          Expanded(
            child: Text(valor, style: const TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
