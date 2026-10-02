import 'package:json_annotation/json_annotation.dart';

part 'usuario_dto.g.dart';

/// DTO de Usuario y Respuesta de Autenticación para comunicación con el backend.
/// Emplea conversión de tipos generada con `json_serializable`.
///
/// TABLA DE DIVERGENCIAS DE NOMENCLATURA (Servidor snake_case vs Cliente camelCase):
/// - Servidor: `id_usuario`          <-> Cliente: `idUsuario`
/// - Servidor: `token_acceso`        <-> Cliente: `tokenAcceso`
/// - Servidor: `token_actualizacion` <-> Cliente: `tokenActualizacion`
@JsonSerializable(explicitToJson: true)
class UsuarioDto {
  @JsonKey(name: 'id_usuario')
  final String? idUsuario;

  final String email;
  final String? rol;

  @JsonKey(name: 'token_acceso')
  final String? tokenAcceso;

  @JsonKey(name: 'token_actualizacion')
  final String? tokenActualizacion;

  const UsuarioDto({
    this.idUsuario,
    required this.email,
    this.rol,
    this.tokenAcceso,
    this.tokenActualizacion,
  });

  factory UsuarioDto.fromJson(Map<String, dynamic> json) => _$UsuarioDtoFromJson(json);

  Map<String, dynamic> toJson() => _$UsuarioDtoToJson(this);
}
