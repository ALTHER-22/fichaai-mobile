import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/tokens_app.dart';
import '../components/boton_primario.dart';

class LoginScreen extends StatefulWidget {
  final String? redirectTo;
  const LoginScreen({super.key, this.redirectTo});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _correoController = TextEditingController(text: 'admin@fichaai.com');
  final _claveController = TextEditingController(text: 'admin1234');
  bool _ocultarClave = true;

  @override
  void dispose() {
    _correoController.dispose();
    _claveController.dispose();
    super.dispose();
  }

  Future<void> _iniciarSesion() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final exito = await auth.login(
      _correoController.text.trim(),
      _claveController.text.trim(),
    );

    if (!mounted) return;

    if (exito) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('¡Bienvenido, ${auth.usuario}!'),
          backgroundColor: Colors.green,
        ),
      );
      context.go(widget.redirectTo ?? '/');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.mensajeError ?? 'Error al iniciar sesión'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<TokensApp>()!;
    final tema = Theme.of(context);
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Iniciar Sesión'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(tokens.espacioBase * 3),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.lock_person_outlined,
                    size: 72,
                    color: tema.colorScheme.primary,
                  ),
                  SizedBox(height: tokens.espacioBase * 2),
                  Text(
                    'Acceso a FichaAI',
                    textAlign: TextAlign.center,
                    style: tema.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: tokens.espacioBase),
                  Text(
                    'Inicia sesión para gestionar y publicar nuevas fichas técnicas oficiales.',
                    textAlign: TextAlign.center,
                    style: tema.textTheme.bodyMedium?.copyWith(
                      color: tema.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  SizedBox(height: tokens.espacioBase * 3),

                  // Campo Correo
                  TextFormField(
                    controller: _correoController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Correo Electrónico',
                      prefixIcon: const Icon(Icons.email_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(tokens.radioTarjeta),
                      ),
                    ),
                    validator: (valor) {
                      if (valor == null || valor.trim().isEmpty) {
                        return 'El correo es obligatorio';
                      }
                      if (!valor.contains('@') || !valor.contains('.')) {
                        return 'Ingrese un correo electrónico válido';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: tokens.espacioBase * 2),

                  // Campo Contraseña
                  TextFormField(
                    controller: _claveController,
                    obscureText: _ocultarClave,
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_ocultarClave ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _ocultarClave = !_ocultarClave),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(tokens.radioTarjeta),
                      ),
                    ),
                    validator: (valor) {
                      if (valor == null || valor.isEmpty) {
                        return 'La contraseña es obligatoria';
                      }
                      if (valor.length < 4) {
                        return 'Mínimo 4 caracteres';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: tokens.espacioBase * 3),

                  // Botón Iniciar Sesión
                  BotonPrimario(
                    texto: 'Entrar al Sistema',
                    cargando: auth.cargando,
                    onPulsar: _iniciarSesion,
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
