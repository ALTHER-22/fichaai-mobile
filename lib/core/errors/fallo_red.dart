/// Representación tipada de las 4 familias de fallo de red
/// según el marco arquitectónico de la Semana 13.
sealed class FalloRed implements Exception {
  final String mensaje;
  final int? codigoEstado;

  const FalloRed(this.mensaje, {this.codigoEstado});

  @override
  String toString() => mensaje;
}

/// 1. Sin Conexión: Dispositivo fuera de línea o interfaz física inalcanzable
class FalloSinConexion extends FalloRed {
  const FalloSinConexion([super.mensaje = 'Sin conexión a Internet. Mostrando datos locales de SQLite.'])
      : super(codigoEstado: null);
}

/// 2. Tiempos de Espera Agotados: Conexión o recepción excedió el límite configurado (10s/15s)
class FalloTimeout extends FalloRed {
  const FalloTimeout([super.mensaje = 'El servidor tardó demasiado en responder. La operación pudo haberse ejecutado.'])
      : super(codigoEstado: 408);
}

/// 3. Errores del Cliente (4xx): Rechazo por validación, credenciales o recursos inexistentes
class FalloCliente extends FalloRed {
  final Map<String, String> erroresPorCampo;

  const FalloCliente(
    super.mensaje, {
    super.codigoEstado,
    this.erroresPorCampo = const {},
  });

  bool get es422Validacion => codigoEstado == 422;
  bool get es401NoAutorizado => codigoEstado == 401;
  bool get es404NoEncontrado => codigoEstado == 404;
}

/// 4. Errores del Servidor (5xx): Fallas internas en el backend o pasarelas intermedias
class FalloServidor extends FalloRed {
  const FalloServidor([
    super.mensaje = 'Error interno temporal del servidor. Reintentando con espera creciente...',
    int? codigo = 500,
  ]) : super(codigoEstado: codigo);
}

/// Error desconocido o de conversión
class FalloInesperado extends FalloRed {
  const FalloInesperado([super.mensaje = 'Ocurrió un error inesperado al procesar la solicitud.'])
      : super(codigoEstado: null);
}
