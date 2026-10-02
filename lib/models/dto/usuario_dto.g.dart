// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'usuario_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UsuarioDto _$UsuarioDtoFromJson(Map<String, dynamic> json) => UsuarioDto(
  idUsuario: json['id_usuario'] as String?,
  email: json['email'] as String,
  rol: json['rol'] as String?,
  tokenAcceso: json['token_acceso'] as String?,
  tokenActualizacion: json['token_actualizacion'] as String?,
);

Map<String, dynamic> _$UsuarioDtoToJson(UsuarioDto instance) =>
    <String, dynamic>{
      'id_usuario': instance.idUsuario,
      'email': instance.email,
      'rol': instance.rol,
      'token_acceso': instance.tokenAcceso,
      'token_actualizacion': instance.tokenActualizacion,
    };
