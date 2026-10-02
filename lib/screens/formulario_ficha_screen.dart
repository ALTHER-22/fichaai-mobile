import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../providers/auth_provider.dart';
import '../providers/ficha_provider.dart';
import '../models/ficha_model.dart';
import '../theme/tokens_app.dart';
import '../components/boton_primario.dart';
import '../services/connectivity_service.dart';

class FormularioFichaScreen extends StatefulWidget {
  const FormularioFichaScreen({super.key});

  @override
  State<FormularioFichaScreen> createState() => _FormularioFichaScreenState();
}

class _FormularioFichaScreenState extends State<FormularioFichaScreen> {
  final _formKey = GlobalKey<FormState>();

  final _modeloController = TextEditingController();
  final _fabricanteController = TextEditingController();
  final _procesadorController = TextEditingController();
  final _ramController = TextEditingController();
  final _almacenamientoController = TextEditingController();
  final _pantallaController = TextEditingController();
  final _camaraPrincipalController = TextEditingController();
  final _camaraFrontalController = TextEditingController();
  final _bateriaController = TextEditingController();
  final _precioController = TextEditingController();
  final _urlImagenController = TextEditingController();

  bool _guardando = false;
  String? _errorPrecioBackend;
  String? _rutaImagenSeleccionada;
  String? _ubicacionActual;

  @override
  void initState() {
    super.initState();
    // Si la IA ya tenía un resultado, precargarlo automáticamente
    final fichaIA = context.read<FichaProvider>().resultadoBusquedaIA;
    if (fichaIA != null) {
      _modeloController.text = fichaIA.modelo;
      _fabricanteController.text = fichaIA.fabricante ?? '';
      _procesadorController.text = fichaIA.procesador ?? '';
      _ramController.text = fichaIA.ram ?? '';
      _almacenamientoController.text = fichaIA.almacenamiento ?? '';
      _pantallaController.text = fichaIA.pantalla ?? '';
      _camaraPrincipalController.text = fichaIA.camaraPrincipal ?? '';
      _camaraFrontalController.text = fichaIA.camaraFrontal ?? '';
      _bateriaController.text = fichaIA.bateria ?? '';
      _precioController.text = fichaIA.precioOficial?.toString() ?? '';
      _urlImagenController.text = fichaIA.urlImagen ?? '';
    }
  }

  @override
  void dispose() {
    _modeloController.dispose();
    _fabricanteController.dispose();
    _procesadorController.dispose();
    _ramController.dispose();
    _almacenamientoController.dispose();
    _pantallaController.dispose();
    _camaraPrincipalController.dispose();
    _camaraFrontalController.dispose();
    _bateriaController.dispose();
    _precioController.dispose();
    _urlImagenController.dispose();
    super.dispose();
  }

  Future<void> _seleccionarImagen() async {
    try {
      // Usamos el selector del sistema sin pedir permiso de galería expresamente
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _rutaImagenSeleccionada = pickedFile.path;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al seleccionar imagen: $e')),
      );
    }
  }

  Future<void> _capturarUbicacion() async {
    bool servicioHabilitado = await Geolocator.isLocationServiceEnabled();
    if (!servicioHabilitado) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El servicio de ubicación (GPS) está desactivado.')),
      );
      return;
    }

    var estadoPermiso = await Permission.locationWhenInUse.status;

    if (estadoPermiso.isDenied) {
      if (!mounted) return;
      // Mostrar explicación antes del diálogo del sistema
      final confirmar = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Permiso de Ubicación'),
          content: const Text('FichaAI necesita acceso a la ubicación para registrar dónde se realizó la inspección del dispositivo. ¿Deseas conceder el permiso?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Ahora no'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Continuar'),
            ),
          ],
        ),
      );
      if (confirmar != true) return;
      estadoPermiso = await Permission.locationWhenInUse.request();
    }

    if (estadoPermiso.isGranted) {
      try {
        final posicion = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
        );
        setState(() {
          _ubicacionActual = '${posicion.latitude}, ${posicion.longitude}';
        });
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('No se pudo obtener la ubicación: $e')),
          );
        }
      }
    } else if (estadoPermiso.isPermanentlyDenied) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Permiso Denegado Permanentemente'),
          content: const Text('Para usar la ubicación debes habilitar el permiso en los Ajustes del sistema.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                openAppSettings();
                Navigator.pop(ctx);
              },
              child: const Text('Abrir Ajustes'),
            ),
          ],
        ),
      );
    } else if (estadoPermiso.isDenied) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permiso de ubicación denegado.')),
      );
    }
  }

  Future<void> _guardarFicha() async {
    setState(() => _errorPrecioBackend = null);

    if (_modeloController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El modelo del celular es obligatorio.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final precio = double.tryParse(_precioController.text.trim());

    setState(() => _guardando = true);

    final nuevaFicha = FichaModel(
      modelo: _modeloController.text.trim(),
      fabricante: _fabricanteController.text.trim().isNotEmpty ? _fabricanteController.text.trim() : null,
      procesador: _procesadorController.text.trim().isNotEmpty ? _procesadorController.text.trim() : null,
      ram: _ramController.text.trim().isNotEmpty ? _ramController.text.trim() : null,
      almacenamiento: _almacenamientoController.text.trim().isNotEmpty ? _almacenamientoController.text.trim() : null,
      pantalla: _pantallaController.text.trim().isNotEmpty ? _pantallaController.text.trim() : null,
      camaraPrincipal: _camaraPrincipalController.text.trim().isNotEmpty ? _camaraPrincipalController.text.trim() : null,
      camaraFrontal: _camaraFrontalController.text.trim().isNotEmpty ? _camaraFrontalController.text.trim() : null,
      bateria: _bateriaController.text.trim().isNotEmpty ? _bateriaController.text.trim() : null,
      precioOficial: precio,
      urlImagen: _urlImagenController.text.trim().isNotEmpty ? _urlImagenController.text.trim() : null,
      rutaImagenLocal: _rutaImagenSeleccionada,
      ubicacionRegistro: _ubicacionActual,
    );

    final auth = context.read<AuthProvider>();
    final fichaProvider = context.read<FichaProvider>();
    final estaConectado = ConnectivityService.instance.estaConectado;

    final exito = await fichaProvider.guardarFicha(nuevaFicha, token: auth.token);

    setState(() => _guardando = false);

    if (!mounted) return;

    if (!exito) {
      // Si el servidor respondió con 422 o error de cliente, asociar el error al campo correspondiente
      if (fichaProvider.erroresValidacion.isNotEmpty) {
        setState(() {
          _errorPrecioBackend = fichaProvider.erroresValidacion['precio_oficial'] ??
              'Error 422: Datos rechazados por el servidor';
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  fichaProvider.erroresValidacion.isNotEmpty
                      ? 'Error 422 (Unprocessable Entity): ${fichaProvider.mensajeError}'
                      : 'Error: ${fichaProvider.mensajeError}',
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red.shade700,
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          estaConectado
              ? '¡Ficha técnica registrada y confirmada por el backend!'
              : '📝 Modo sin conexión: Ficha guardada en SQLite local y encolada en Outbox con UUID único.',
        ),
        backgroundColor: estaConectado ? Colors.green : Colors.orange.shade800,
        duration: const Duration(seconds: 4),
      ),
    );

    context.go('/catalogo');
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<TokensApp>()!;
    final tema = Theme.of(context);
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar Ficha Técnica'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Chip(
              avatar: const Icon(Icons.verified_user, size: 16),
              label: Text(auth.usuario ?? 'Admin', style: const TextStyle(fontSize: 12)),
            ),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(tokens.espacioBase * 2),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Formulario Oficial de Dispositivo',
                    style: tema.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: tokens.espacioBase * 0.5),
                  Text(
                    'Los campos serán validados síncronamente con las reglas del servidor (HTTP 422).',
                    style: tema.textTheme.bodySmall?.copyWith(color: tema.colorScheme.outline),
                  ),
                  SizedBox(height: tokens.espacioBase * 2),

                  if (!ConnectivityService.instance.estaConectado) ...[
                    Container(
                      padding: EdgeInsets.all(tokens.espacioBase),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade100,
                        borderRadius: BorderRadius.circular(tokens.radioTarjeta),
                        border: Border.all(color: Colors.amber.shade700),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.airplanemode_active, color: Colors.deepOrange.shade800),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Modo Sin Conexión: La ficha se guardará en SQLite local y se encolará en Outbox con UUID único para sincronización automática.',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.brown.shade900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: tokens.espacioBase * 1.5),
                  ],

                  // Modelo (Obligatorio)
                  TextFormField(
                    controller: _modeloController,
                    decoration: InputDecoration(
                      labelText: 'Modelo del Celular *',
                      hintText: 'Ej: Samsung Galaxy S24 Ultra',
                      prefixIcon: const Icon(Icons.smartphone),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(tokens.radioTarjeta)),
                    ),
                    validator: (valor) {
                      if (valor == null || valor.trim().isEmpty) {
                        return 'El nombre del modelo es obligatorio';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: tokens.espacioBase * 1.5),

                  // Fabricante y Procesador
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _fabricanteController,
                          decoration: InputDecoration(
                            labelText: 'Fabricante',
                            hintText: 'Samsung / Xiaomi',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(tokens.radioTarjeta)),
                          ),
                        ),
                      ),
                      SizedBox(width: tokens.espacioBase),
                      Expanded(
                        child: TextFormField(
                          controller: _procesadorController,
                          decoration: InputDecoration(
                            labelText: 'Procesador',
                            hintText: 'Snapdragon 8 Gen 3',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(tokens.radioTarjeta)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: tokens.espacioBase * 1.5),

                  // RAM y Almacenamiento
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _ramController,
                          decoration: InputDecoration(
                            labelText: 'Memoria RAM',
                            hintText: '8 GB / 12 GB',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(tokens.radioTarjeta)),
                          ),
                        ),
                      ),
                      SizedBox(width: tokens.espacioBase),
                      Expanded(
                        child: TextFormField(
                          controller: _almacenamientoController,
                          decoration: InputDecoration(
                            labelText: 'Almacenamiento',
                            hintText: '256 GB / 512 GB',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(tokens.radioTarjeta)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: tokens.espacioBase * 1.5),

                  // Pantalla y Batería
                  TextFormField(
                    controller: _pantallaController,
                    decoration: InputDecoration(
                      labelText: 'Pantalla',
                      hintText: '6.7" Dynamic AMOLED 2X 120Hz',
                      prefixIcon: const Icon(Icons.tv),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(tokens.radioTarjeta)),
                    ),
                  ),
                  SizedBox(height: tokens.espacioBase * 1.5),

                  TextFormField(
                    controller: _bateriaController,
                    decoration: InputDecoration(
                      labelText: 'Batería y Carga',
                      hintText: '5000 mAh (45W)',
                      prefixIcon: const Icon(Icons.battery_charging_full),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(tokens.radioTarjeta)),
                    ),
                  ),
                  SizedBox(height: tokens.espacioBase * 1.5),

                  // Cámaras
                  TextFormField(
                    controller: _camaraPrincipalController,
                    decoration: InputDecoration(
                      labelText: 'Cámara Principal',
                      hintText: '200 MP f/1.7 OIS',
                      prefixIcon: const Icon(Icons.camera_alt),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(tokens.radioTarjeta)),
                    ),
                  ),
                  SizedBox(height: tokens.espacioBase * 1.5),

                  // Precio Oficial con validación 422
                  TextFormField(
                    controller: _precioController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Precio Oficial (USD) *',
                      hintText: 'Ej: 799.99',
                      prefixIcon: const Icon(Icons.attach_money),
                      errorText: _errorPrecioBackend,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(tokens.radioTarjeta)),
                    ),
                    validator: (valor) {
                      if (valor == null || valor.trim().isEmpty) {
                        return 'El precio oficial es requerido';
                      }
                      final n = double.tryParse(valor);
                      if (n == null) return 'Ingrese un número válido';
                      if (n <= 0) return 'El precio debe ser estrictamente mayor a 0';
                      return null;
                    },
                  ),
                  SizedBox(height: tokens.espacioBase * 1.5),

                  // Capacidades Nativas (Semana 14)
                  Card(
                    elevation: 0,
                    color: tema.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(tokens.radioTarjeta)),
                    child: Padding(
                      padding: EdgeInsets.all(tokens.espacioBase),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Datos de Inspección Local',
                            style: tema.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: tokens.espacioBase),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _seleccionarImagen,
                                  icon: const Icon(Icons.photo_library),
                                  label: const Text('Adjuntar Foto Local'),
                                ),
                              ),
                              SizedBox(width: tokens.espacioBase),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _capturarUbicacion,
                                  icon: const Icon(Icons.location_on),
                                  label: const Text('Fijar Ubicación'),
                                ),
                              ),
                            ],
                          ),
                          if (_rutaImagenSeleccionada != null || _ubicacionActual != null) ...[
                            SizedBox(height: tokens.espacioBase),
                            if (_rutaImagenSeleccionada != null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: Row(
                                  children: [
                                    const Icon(Icons.check_circle, color: Colors.green, size: 16),
                                    const SizedBox(width: 8),
                                    Expanded(child: Text('Foto seleccionada: ${_rutaImagenSeleccionada!.split('/').last}', style: tema.textTheme.bodySmall)),
                                  ],
                                ),
                              ),
                            if (_ubicacionActual != null)
                              Row(
                                children: [
                                  const Icon(Icons.check_circle, color: Colors.green, size: 16),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text('Ubicación: $_ubicacionActual', style: tema.textTheme.bodySmall)),
                                ],
                              ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: tokens.espacioBase * 1.5),

                  // URL Foto
                  TextFormField(
                    controller: _urlImagenController,
                    decoration: InputDecoration(
                      labelText: 'URL Imagen Oficial',
                      hintText: 'https://...',
                      prefixIcon: const Icon(Icons.image),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(tokens.radioTarjeta)),
                    ),
                  ),
                  SizedBox(height: tokens.espacioBase * 3),

                  BotonPrimario(
                    texto: 'Guardar y Publicar Ficha',
                    cargando: _guardando,
                    onPulsar: _guardarFicha,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
