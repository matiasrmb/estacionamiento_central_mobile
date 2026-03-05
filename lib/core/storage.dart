import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStore {
  static const _storage = FlutterSecureStorage();

  static const _kToken = 'jwt_token';
  static const _kUser = 'user_name';
  static const _kRole = 'user_role';

  Future<void> saveSession({
    required String token,
    required String user,
    required String role,
  }) async {
    await _storage.write(key: _kToken, value: token);
    await _storage.write(key: _kUser, value: user);
    await _storage.write(key: _kRole, value: role);
  }

  Future<String?> readToken() => _storage.read(key: _kToken);
  Future<String?> readUser() => _storage.read(key: _kUser);
  Future<String?> readRole() => _storage.read(key: _kRole);

  Future<void> clear() async {
    await _storage.delete(key: _kToken);
    await _storage.delete(key: _kUser);
    await _storage.delete(key: _kRole);
  }
}