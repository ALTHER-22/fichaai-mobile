// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ficha_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FichaDto _$FichaDtoFromJson(Map<String, dynamic> json) => FichaDto(
  idFicha: json['id_ficha'] as String?,
  idDispositivo: json['id_dispositivo'] as String?,
  modelo: json['modelo'] as String,
  fabricante: json['fabricante'] as String?,
  procesador: json['procesador'] as String?,
  ram: json['ram'] as String?,
  almacenamiento: json['almacenamiento'] as String?,
  pantalla: json['pantalla'] as String?,
  camaraPrincipal: json['camara_principal'] as String?,
  camaraFrontal: json['camara_frontal'] as String?,
  bateria: json['bateria'] as String?,
  sistemaOperativo: json['sistema_operativo'] as String?,
  conectividad: json['conectividad'] as String?,
  extras: json['extras'] as String?,
  precioOficial: (json['precio_oficial'] as num?)?.toDouble(),
  moneda: json['moneda'] as String? ?? 'USD',
  urlImagen: json['url_imagen'] as String?,
  imagenes: (json['imagenes'] as List<dynamic>?)?.map((e) => e as String).toList(),
  fechaGeneracion: json['fecha_generacion'] as String?,
);

Map<String, dynamic> _$FichaDtoToJson(FichaDto instance) => <String, dynamic>{
  'id_ficha': instance.idFicha,
  'id_dispositivo': instance.idDispositivo,
  'modelo': instance.modelo,
  'fabricante': instance.fabricante,
  'procesador': instance.procesador,
  'ram': instance.ram,
  'almacenamiento': instance.almacenamiento,
  'pantalla': instance.pantalla,
  'camara_principal': instance.camaraPrincipal,
  'camara_frontal': instance.camaraFrontal,
  'bateria': instance.bateria,
  'sistema_operativo': instance.sistemaOperativo,
  'conectividad': instance.conectividad,
  'extras': instance.extras,
  'precio_oficial': instance.precioOficial,
  'moneda': instance.moneda,
  'url_imagen': instance.urlImagen,
  'imagenes': instance.imagenes,
  'fecha_generacion': instance.fechaGeneracion,
};
