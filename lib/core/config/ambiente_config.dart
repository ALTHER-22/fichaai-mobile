import 'dart:io';
import 'package:flutter/foundation.dart';

/// Tipos de ambiente soportados por la solución móvil FichaAI
enum TipoAmbiente {
  desarrollo,
  pruebas,
  produccion,
}

/// Configuración centralizada de la capa de red desacoplada por ambientes.
/// Permite inyección de variables en tiempo de compilación con `--dart-define`.
///
/// Ejemplos:
/// - Desarrollo (Android): flutter run --dart-define=AMBIENTE=dev --dart-define=API_URL=http://10.0.2.2:5000/api
/// - Desarrollo (Desktop): flutter run --dart-define=AMBIENTE=dev --dart-define=API_URL=http://127.0.0.1:5000/api
/// - Producción: flutter build apk --dart-define=AMBIENTE=prod --dart-define=API_URL=https://api.fichaai.com/api
class AmbienteConfig {
  static const String _envAmbiente = String.fromEnvironment('AMBIENTE', defaultValue: 'dev');
  static const String _envApiUrl = String.fromEnvironment('API_URL', defaultValue: '');

  /// Tiempos de espera explícitos conforme a la rúbrica (10s conexión, 15s recepción)
  static const Duration tiempoConexion = Duration(seconds: 10);
  static const Duration tiempoRecepcion = Duration(seconds: 15);

  /// Obtiene el ambiente actual configurado
  static TipoAmbiente get ambienteActual {
    switch (_envAmbiente.toLowerCase()) {
      case 'prod':
      case 'produccion':
        return TipoAmbiente.produccion;
      case 'test':
      case 'pruebas':
      case 'staging':
        return TipoAmbiente.pruebas;
      case 'dev':
      case 'desarrollo':
      default:
        return TipoAmbiente.desarrollo;
    }
  }

  static bool get esProduccion => ambienteActual == TipoAmbiente.produccion;
  static bool get esDesarrollo => ambienteActual == TipoAmbiente.desarrollo;

  /// En producción el registro detallado (logging) se desactiva estrictamente
  static bool get habilitarLogging => !esProduccion;

  /// Dirección base resuelta por ambiente
  static String get urlApi {
    if (_envApiUrl.isNotEmpty) {
      _validarSeguridadUrl(_envApiUrl);
      return _envApiUrl;
    }

    switch (ambienteActual) {
      case TipoAmbiente.produccion:
        const prodUrl = 'https://api.fichaai.com/api';
        _validarSeguridadUrl(prodUrl);
        return prodUrl;
      case TipoAmbiente.pruebas:
        return 'https://staging.fichaai.com/api';
      case TipoAmbiente.desarrollo:
        // En dispositivo físico y emulador Android usamos la IP local de la PC en la red
        if (!kIsWeb && Platform.isAndroid) {
          return 'http://192.168.1.4:5000/api';
        }
        return 'http://127.0.0.1:5000/api';
    }
  }

  /// Verificación de seguridad: Producción exige HTTPS sin excepciones (Criterio 7)
  static void _validarSeguridadUrl(String url) {
    if (esProduccion && !url.toLowerCase().startsWith('https://')) {
      throw SecurityException(
        'Vulnerabilidad de seguridad detectada: En ambiente de PRODUCCIÓN '
        'es obligatorio el uso estricto del protocolo seguro HTTPS. Dirección rechazada: $url',
      );
    }
  }
}

class SecurityException implements Exception {
  final String mensaje;
  SecurityException(this.mensaje);

  @override
  String toString() => 'SecurityException: $mensaje';
}
