import 'package:uuid/uuid.dart';

/// Modelo de datos de Ficha Técnica adaptado a la persistencia local y sincronización.
/// Aplica el principio de minimización: almacena solo atributos de visualización y control.
class FichaModel {
  final String idLocal;
  final String? idServidor;
  final String modelo;
  final String? fabricante;
  final String? procesador;
  final String? ram;
  final String? almacenamiento;
  final String? pantalla;
  final String? camaraPrincipal;
  final String? camaraFrontal;
  final String? bateria;
  final String? sistemaOperativo;
  final String? conectividad;
  final String? extras;
  final double? precioOficial;
  final String moneda;
  final String? urlImagen;
  final List<String>? imagenes;
  
  // Capacidades nativas - Semana 14
  final String? rutaImagenLocal;
  final String? ubicacionRegistro;

  // Campos de control de sincronización y resolución de conflictos (LWW)
  final bool sincronizado;
  final String? fechaServidor;
  final String fechaGuardadoLocal;

  FichaModel({
    String? idLocal,
    this.idServidor,
    String? idFicha,
    required this.modelo,
    this.fabricante,
    this.procesador,
    this.ram,
    this.almacenamiento,
    this.pantalla,
    this.camaraPrincipal,
    this.camaraFrontal,
    this.bateria,
    this.sistemaOperativo,
    this.conectividad,
    this.extras,
    this.precioOficial,
    this.moneda = 'USD',
    this.urlImagen,
    this.imagenes,
    this.rutaImagenLocal,
    this.ubicacionRegistro,
    this.sincronizado = true,
    this.fechaServidor,
    String? fechaGuardadoLocal,
  })  : idLocal = idLocal ?? (idFicha ?? const Uuid().v4()),
        fechaGuardadoLocal = fechaGuardadoLocal ?? DateTime.now().toIso8601String();

  /// Getter de compatibilidad con pantallas existentes
  String? get idFicha => idServidor ?? idLocal;

  /// Retorna la lista de todas las fotos oficiales disponibles para la galería interactiva
  List<String> get listaImagenes {
    if (imagenes != null && imagenes!.isNotEmpty) {
      return imagenes!;
    }
    if (urlImagen != null && urlImagen!.trim().isNotEmpty) {
      return [urlImagen!];
    }
    return [];
  }

  FichaModel copyWith({
    String? idLocal,
    String? idServidor,
    String? modelo,
    String? fabricante,
    String? procesador,
    String? ram,
    String? almacenamiento,
    String? pantalla,
    String? camaraPrincipal,
    String? camaraFrontal,
    String? bateria,
    String? sistemaOperativo,
    String? conectividad,
    String? extras,
    double? precioOficial,
    String? moneda,
    String? urlImagen,
    List<String>? imagenes,
    String? rutaImagenLocal,
    String? ubicacionRegistro,
    bool? sincronizado,
    String? fechaServidor,
    String? fechaGuardadoLocal,
  }) {
    return FichaModel(
      idLocal: idLocal ?? this.idLocal,
      idServidor: idServidor ?? this.idServidor,
      modelo: modelo ?? this.modelo,
      fabricante: fabricante ?? this.fabricante,
      procesador: procesador ?? this.procesador,
      ram: ram ?? this.ram,
      almacenamiento: almacenamiento ?? this.almacenamiento,
      pantalla: pantalla ?? this.pantalla,
      camaraPrincipal: camaraPrincipal ?? this.camaraPrincipal,
      camaraFrontal: camaraFrontal ?? this.camaraFrontal,
      bateria: bateria ?? this.bateria,
      sistemaOperativo: sistemaOperativo ?? this.sistemaOperativo,
      conectividad: conectividad ?? this.conectividad,
      extras: extras ?? this.extras,
      precioOficial: precioOficial ?? this.precioOficial,
      moneda: moneda ?? this.moneda,
      urlImagen: urlImagen ?? this.urlImagen,
      imagenes: imagenes ?? this.imagenes,
      rutaImagenLocal: rutaImagenLocal ?? this.rutaImagenLocal,
      ubicacionRegistro: ubicacionRegistro ?? this.ubicacionRegistro,
      sincronizado: sincronizado ?? this.sincronizado,
      fechaServidor: fechaServidor ?? this.fechaServidor,
      fechaGuardadoLocal: fechaGuardadoLocal ?? this.fechaGuardadoLocal,
    );
  }

  /// Deserialización desde la respuesta JSON del servidor backend
  factory FichaModel.fromJson(Map<String, dynamic> json) {
    return FichaModel(
      idLocal: json['id_local']?.toString() ?? const Uuid().v4(),
      idServidor: json['id_ficha']?.toString() ?? json['id_servidor']?.toString(),
      modelo: json['modelo'] ?? 'Dispositivo desconocido',
      fabricante: json['fabricante'],
      procesador: json['procesador'],
      ram: json['ram'],
      almacenamiento: json['almacenamiento'],
      pantalla: json['pantalla'],
      camaraPrincipal: json['camara_principal'],
      camaraFrontal: json['camara_frontal'],
      bateria: json['bateria'],
      sistemaOperativo: json['sistema_operativo'],
      conectividad: json['conectividad'],
      extras: json['extras'],
      precioOficial: json['precio_oficial'] != null
          ? double.tryParse(json['precio_oficial'].toString())
          : null,
      moneda: json['moneda'] ?? 'USD',
      urlImagen: json['url_imagen'],
      imagenes: (json['imagenes'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
      rutaImagenLocal: json['ruta_imagen_local'],
      ubicacionRegistro: json['ubicacion_registro'],
      sincronizado: json['sincronizado'] == null ? true : (json['sincronizado'] == 1 || json['sincronizado'] == true),
      fechaServidor: json['fecha_generacion'] ?? json['fecha_servidor'],
      fechaGuardadoLocal: json['fecha_guardado_local'] ?? DateTime.now().toIso8601String(),
    );
  }

  /// Serialización para enviar al servidor backend
  Map<String, dynamic> toJson() {
    return {
      if (idServidor != null) 'id_ficha': idServidor,
      'id_local': idLocal,
      'modelo': modelo,
      if (fabricante != null) 'fabricante': fabricante,
      if (procesador != null) 'procesador': procesador,
      if (ram != null) 'ram': ram,
      if (almacenamiento != null) 'almacenamiento': almacenamiento,
      if (pantalla != null) 'pantalla': pantalla,
      if (camaraPrincipal != null) 'camara_principal': camaraPrincipal,
      if (camaraFrontal != null) 'camara_frontal': camaraFrontal,
      if (bateria != null) 'bateria': bateria,
      if (sistemaOperativo != null) 'sistema_operativo': sistemaOperativo,
      if (conectividad != null) 'conectividad': conectividad,
      if (extras != null) 'extras': extras,
      if (precioOficial != null) 'precio_oficial': precioOficial,
      'moneda': moneda,
      if (urlImagen != null) 'url_imagen': urlImagen,
      if (imagenes != null) 'imagenes': imagenes,
      if (rutaImagenLocal != null) 'ruta_imagen_local': rutaImagenLocal,
      if (ubicacionRegistro != null) 'ubicacion_registro': ubicacionRegistro,
    };
  }

  /// Serialización para la base de datos local SQLite
  Map<String, dynamic> toMapLocal() {
    return {
      'id_local': idLocal,
      'id_servidor': idServidor,
      'modelo': modelo,
      'fabricante': fabricante,
      'procesador': procesador,
      'ram': ram,
      'almacenamiento': almacenamiento,
      'pantalla': pantalla,
      'camara_principal': camaraPrincipal,
      'camara_frontal': camaraFrontal,
      'bateria': bateria,
      'sistema_operativo': sistemaOperativo,
      'conectividad': conectividad,
      'extras': extras,
      'precio_oficial': precioOficial,
      'moneda': moneda,
      'url_imagen': urlImagen,
      'ruta_imagen_local': rutaImagenLocal,
      'ubicacion_registro': ubicacionRegistro,
      'sincronizado': sincronizado ? 1 : 0,
      'fecha_servidor': fechaServidor,
      'fecha_guardado_local': fechaGuardadoLocal,
    };
  }

  /// Deserialización desde la base de datos local SQLite
  factory FichaModel.fromMapLocal(Map<String, dynamic> map) {
    return FichaModel(
      idLocal: map['id_local'] as String,
      idServidor: map['id_servidor'] as String?,
      modelo: map['modelo'] as String,
      fabricante: map['fabricante'] as String?,
      procesador: map['procesador'] as String?,
      ram: map['ram'] as String?,
      almacenamiento: map['almacenamiento'] as String?,
      pantalla: map['pantalla'] as String?,
      camaraPrincipal: map['camara_principal'] as String?,
      camaraFrontal: map['camara_frontal'] as String?,
      bateria: map['bateria'] as String?,
      sistemaOperativo: map['sistema_operativo'] as String?,
      conectividad: map['conectividad'] as String?,
      extras: map['extras'] as String?,
      precioOficial: map['precio_oficial'] != null
          ? (map['precio_oficial'] as num).toDouble()
          : null,
      moneda: (map['moneda'] as String?) ?? 'USD',
      urlImagen: map['url_imagen'] as String?,
      imagenes: map['url_imagen'] != null ? [map['url_imagen'] as String] : null,
      rutaImagenLocal: map['ruta_imagen_local'] as String?,
      ubicacionRegistro: map['ubicacion_registro'] as String?,
      sincronizado: (map['sincronizado'] as int? ?? 1) == 1,
      fechaServidor: map['fecha_servidor'] as String?,
      fechaGuardadoLocal: map['fecha_guardado_local'] as String?,
    );
  }
}
