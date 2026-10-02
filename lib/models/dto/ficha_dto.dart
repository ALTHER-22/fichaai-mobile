import 'package:json_annotation/json_annotation.dart';
import '../ficha_model.dart';

part 'ficha_dto.g.dart';

/// DTO de Ficha Técnica para comunicación con la API REST Backend.
/// Emplea conversión de tipos generada con `json_serializable`.
///
/// TABLA DE DIVERGENCIAS DE NOMENCLATURA (Servidor snake_case vs Cliente camelCase):
/// - Servidor: `id_ficha`          <-> Cliente: `idFicha`
/// - Servidor: `id_dispositivo`    <-> Cliente: `idDispositivo`
/// - Servidor: `camara_principal`  <-> Cliente: `camaraPrincipal`
/// - Servidor: `camara_frontal`    <-> Cliente: `camaraFrontal`
/// - Servidor: `sistema_operativo` <-> Cliente: `sistemaOperativo`
/// - Servidor: `precio_oficial`    <-> Cliente: `precioOficial`
/// - Servidor: `url_imagen`        <-> Cliente: `urlImagen`
/// - Servidor: `fecha_generacion`  <-> Cliente: `fechaGeneracion`
///
/// Regla de Robustez: Todos los campos opcionales son declarados como anulables (`?`).
@JsonSerializable(explicitToJson: true)
class FichaDto {
  @JsonKey(name: 'id_ficha')
  final String? idFicha;

  @JsonKey(name: 'id_dispositivo')
  final String? idDispositivo;

  final String modelo;

  final String? fabricante;
  final String? procesador;
  final String? ram;
  final String? almacenamiento;
  final String? pantalla;

  @JsonKey(name: 'camara_principal')
  final String? camaraPrincipal;

  @JsonKey(name: 'camara_frontal')
  final String? camaraFrontal;

  final String? bateria;

  @JsonKey(name: 'sistema_operativo')
  final String? sistemaOperativo;

  final String? conectividad;
  final String? extras;

  @JsonKey(name: 'precio_oficial')
  final double? precioOficial;

  @JsonKey(defaultValue: 'USD')
  final String moneda;

  @JsonKey(name: 'url_imagen')
  final String? urlImagen;

  @JsonKey(name: 'imagenes')
  final List<String>? imagenes;

  @JsonKey(name: 'fecha_generacion')
  final String? fechaGeneracion;

  const FichaDto({
    this.idFicha,
    this.idDispositivo,
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
    this.fechaGeneracion,
  });

  factory FichaDto.fromJson(Map<String, dynamic> json) {
    final sanitized = Map<String, dynamic>.from(json);
    if (sanitized['precio_oficial'] != null) {
      if (sanitized['precio_oficial'] is num) {
        sanitized['precio_oficial'] = (sanitized['precio_oficial'] as num).toDouble();
      } else {
        sanitized['precio_oficial'] = double.tryParse(sanitized['precio_oficial'].toString());
      }
    }
    if (sanitized['imagenes'] is List) {
      sanitized['imagenes'] = (sanitized['imagenes'] as List)
          .where((e) => e != null)
          .map((e) => e.toString())
          .toList();
    }
    return _$FichaDtoFromJson(sanitized);
  }

  Map<String, dynamic> toJson() => _$FichaDtoToJson(this);

  /// Conversión al modelo de dominio / base de datos local
  FichaModel toDomain({String? idLocal}) {
    return FichaModel(
      idLocal: idLocal,
      idServidor: idFicha,
      modelo: modelo,
      fabricante: fabricante,
      procesador: procesador,
      ram: ram,
      almacenamiento: almacenamiento,
      pantalla: pantalla,
      camaraPrincipal: camaraPrincipal,
      camaraFrontal: camaraFrontal,
      bateria: bateria,
      sistemaOperativo: sistemaOperativo,
      conectividad: conectividad,
      extras: extras,
      precioOficial: precioOficial,
      moneda: moneda,
      urlImagen: urlImagen,
      imagenes: imagenes,
      sincronizado: true,
      fechaServidor: fechaGeneracion,
    );
  }

  /// Creación desde modelo de dominio
  factory FichaDto.fromDomain(FichaModel model) {
    return FichaDto(
      idFicha: model.idServidor,
      modelo: model.modelo,
      fabricante: model.fabricante,
      procesador: model.procesador,
      ram: model.ram,
      almacenamiento: model.almacenamiento,
      pantalla: model.pantalla,
      camaraPrincipal: model.camaraPrincipal,
      camaraFrontal: model.camaraFrontal,
      bateria: model.bateria,
      sistemaOperativo: model.sistemaOperativo,
      conectividad: model.conectividad,
      extras: model.extras,
      precioOficial: model.precioOficial,
      moneda: model.moneda,
      urlImagen: model.urlImagen,
      imagenes: model.imagenes,
      fechaGeneracion: model.fechaServidor,
    );
  }
}
