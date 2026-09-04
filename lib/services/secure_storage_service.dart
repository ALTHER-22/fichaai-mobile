import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Servicio de almacenamiento seguro para credenciales y secretos de autenticación.
/// Utiliza el almacenamiento cifrado del sistema operativo:
/// - Android: Android Keystore (vía EncryptedSharedPreferences)
/// - iOS: iOS Keychain
/// - Windows: Windows Data Protection API (DPAPI)
/// 
/// Garantiza que ningún token sensible resida en texto plano ni en SharedPreferences.
class SecureStorageService {
  static const String _keyToken = 'auth_token_jwt';
  static const String _keyUsuario = 'auth_usuario_nombre';
  static const String _keyRol = 'auth_usuario_rol';

  final FlutterSecureStorage _storage;

  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(
                encryptedSharedPreferences: true,
              ),
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock,
              ),
            );

  /// Guarda de forma cifrada el token JWT y los datos esenciales de sesión
  Future<void> guardarSesion({
    required String token,
    required String usuario,
    required String rol,
  }) async {
    await _storage.write(key: _keyToken, value: token);
    await _storage.write(key: _keyUsuario, value: usuario);
    await _storage.write(key: _keyRol, value: rol);
  }

  /// Recupera el token JWT cifrado
  Future<String?> obtenerToken() async {
    return await _storage.read(key: _keyToken);
  }

  /// Recupera el nombre de usuario de la sesión
  Future<String?> obtenerUsuario() async {
    return await _storage.read(key: _keyUsuario);
  }

  /// Recupera el rol del usuario autenticado
  Future<String?> obtenerRol() async {
    return await _storage.read(key: _keyRol);
  }

  /// Verifica si existe un token almacenado para restaurar la sesión
  Future<bool> haySesionActiva() async {
    final token = await obtenerToken();
    return token != null && token.isNotEmpty;
  }

  /// Elimina la totalidad de credenciales del almacenamiento cifrado (Logout / LOPDP)
  Future<void> eliminarSesion() async {
    await _storage.delete(key: _keyToken);
    await _storage.delete(key: _keyUsuario);
    await _storage.delete(key: _keyRol);
    await _storage.deleteAll();
  }
}
