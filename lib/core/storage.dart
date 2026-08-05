import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStore {
  static const _storage = FlutterSecureStorage();

  static const _kToken = 'jwt_token';
  static const _kUser = 'user_name';
  static const _kRole = 'user_role';
  static const _kDeviceId = 'device_id';

  // Config (nuevo)
  static const _kBaseUrl = 'api_base_url';
  static const _kMobileLocalPrintingEnabled = 'mobile_local_printing_enabled';

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

  Future<String> getOrCreateDeviceId() async {
    final existing = await _storage.read(key: _kDeviceId);
    if (existing != null && existing.isNotEmpty) return existing;

    final random = Random.secure();
    final id = List.generate(32, (_) => random.nextInt(16).toRadixString(16)).join();
    await _storage.write(key: _kDeviceId, value: 'mobile-$id');
    return 'mobile-$id';
  }

  Future<String?> readDeviceId() => _storage.read(key: _kDeviceId);

  // --- Config: Base URL (nuevo) ---
  Future<void> saveBaseUrl(String url) =>
      _storage.write(key: _kBaseUrl, value: url.trim());
  Future<String?> readBaseUrl() => _storage.read(key: _kBaseUrl);
  Future<void> clearBaseUrl() => _storage.delete(key: _kBaseUrl);

  Future<void> saveMobileLocalPrintingEnabled(bool enabled) => _storage.write(
    key: _kMobileLocalPrintingEnabled,
    value: enabled.toString(),
  );

  Future<bool> readMobileLocalPrintingEnabled() async =>
      (await _storage.read(key: _kMobileLocalPrintingEnabled)) == 'true';

  // --- Helpers genéricos (opcional pero útil) ---
  Future<void> writeString(String key, String value) =>
      _storage.write(key: key, value: value);
  Future<String?> readString(String key) => _storage.read(key: key);
  Future<void> deleteKey(String key) => _storage.delete(key: key);

  Future<void> clear() async {
    await _storage.delete(key: _kToken);
    await _storage.delete(key: _kUser);
    await _storage.delete(key: _kRole);
    // OJO: NO borramos baseUrl por defecto (para que no se “pierda” al cerrar sesión)
    // Si tú quieres que se borre también, descomenta:
    // await _storage.delete(key: _kBaseUrl);
  }
}
