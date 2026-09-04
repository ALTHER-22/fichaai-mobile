import 'dart:math';

/// Representa una operación en la cola de salida (Outbox Pattern)
/// para escrituras resilientes fuera de línea.
class OperacionPendienteModel {
  final String idOperacion; // UUID único para idempotencia en el servidor
  final String tipoOperacion; // 'CREAR_FICHA', 'ACTUALIZAR_FICHA', 'ELIMINAR_FICHA'
  final String idEntidadLocal;
  final String payload; // JSON con los datos de la entidad
  final int intentos;
  final int maxIntentos;
  final String estado; // 'pendiente', 'en_proceso', 'fallido'
  final String creadoEn;
  final String? ultimoError;

  OperacionPendienteModel({
    required this.idOperacion,
    required this.tipoOperacion,
    required this.idEntidadLocal,
    required this.payload,
    this.intentos = 0,
    this.maxIntentos = 5,
    this.estado = 'pendiente',
    required this.creadoEn,
    this.ultimoError,
  });

  /// Calcula el tiempo de espera exponencial creciente (Exponential Backoff):
  /// intento 0 -> 1s, intento 1 -> 2s, intento 2 -> 4s, intento 3 -> 8s... max 30s.
  Duration get tiempoEsperaReintento {
    final segundos = min(30, pow(2, intentos).toInt());
    return Duration(seconds: segundos);
  }

  bool get puedeReintentar => intentos < maxIntentos && estado != 'completado';

  OperacionPendienteModel copyWith({
    String? idOperacion,
    String? tipoOperacion,
    String? idEntidadLocal,
    String? payload,
    int? intentos,
    int? maxIntentos,
    String? estado,
    String? creadoEn,
    String? ultimoError,
  }) {
    return OperacionPendienteModel(
      idOperacion: idOperacion ?? this.idOperacion,
      tipoOperacion: tipoOperacion ?? this.tipoOperacion,
      idEntidadLocal: idEntidadLocal ?? this.idEntidadLocal,
      payload: payload ?? this.payload,
      intentos: intentos ?? this.intentos,
      maxIntentos: maxIntentos ?? this.maxIntentos,
      estado: estado ?? this.estado,
      creadoEn: creadoEn ?? this.creadoEn,
      ultimoError: ultimoError ?? this.ultimoError,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id_operacion': idOperacion,
      'tipo_operacion': tipoOperacion,
      'id_entidad_local': idEntidadLocal,
      'payload': payload,
      'intentos': intentos,
      'max_intentos': maxIntentos,
      'estado': estado,
      'creado_en': creadoEn,
      'ultimo_error': ultimoError,
    };
  }

  factory OperacionPendienteModel.fromMap(Map<String, dynamic> map) {
    return OperacionPendienteModel(
      idOperacion: map['id_operacion'] as String,
      tipoOperacion: map['tipo_operacion'] as String,
      idEntidadLocal: map['id_entidad_local'] as String,
      payload: map['payload'] as String,
      intentos: map['intentos'] as int? ?? 0,
      maxIntentos: map['max_intentos'] as int? ?? 5,
      estado: map['estado'] as String? ?? 'pendiente',
      creadoEn: map['creado_en'] as String,
      ultimoError: map['ultimo_error'] as String?,
    );
  }
}
