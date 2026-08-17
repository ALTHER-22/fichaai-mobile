import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const FichaAIApp());
}

class FichaAIApp extends StatelessWidget {
  const FichaAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FichaAI',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const LoginTestScreen(),
    );
  }
}

class LoginTestScreen extends StatefulWidget {
  const LoginTestScreen({super.key});

  @override
  State<LoginTestScreen> createState() => _LoginTestScreenState();
}

class _LoginTestScreenState extends State<LoginTestScreen> {
  String _resultado = "Esperando petición...";

  // IMPORTANTE: 10.0.2.2 apunta al localhost de Windows desde el emulador de Android
  // Si usas un dispositivo físico por USB, debes poner la IP de tu PC (ej: 192.168.1.X)
  final String _apiUrl = const String.fromEnvironment(
    'API_URL', 
    defaultValue: 'http://10.0.2.2:5000/api',
  );

  Future<void> _probarConexion() async {
    setState(() => _resultado = "Cargando...");
    try {
      final response = await http.post(
        Uri.parse('$_apiUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        // Enviamos credenciales de prueba que fallarán o pasarán, pero confirmarán la conexión.
        body: jsonEncode({'email': 'test@test.com', 'password': '123'}),
      );
      
      if (response.statusCode == 200 || response.statusCode == 401) {
        setState(() => _resultado = "¡Conexión Exitosa al Backend Local!\n\nStatus: ${response.statusCode}\n\nBody: ${response.body}");
      } else {
        setState(() => _resultado = "Error HTTP: ${response.statusCode}");
      }
    } catch (e) {
      setState(() => _resultado = "Error de red: $e\n\n¿Está el backend corriendo en el puerto 5000?");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('hola como va'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.phone_android, size: 80, color: Colors.blue),
              const SizedBox(height: 20),
              Text(
                'Endpoint configurado:\n$_apiUrl/auth/login',
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(_resultado, textAlign: TextAlign.center),
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: _probarConexion,
                icon: const Icon(Icons.cloud_sync),
                label: const Text('Probar Backend Local'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
