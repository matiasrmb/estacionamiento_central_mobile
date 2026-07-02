import 'storage.dart';

class AppConfig {
  // Production builds must not fall back to a developer LAN IP.
  // The server URL is configured by scanning the installer guidance QR/file
  // or by entering the server LAN IP manually in Settings.
  static const String defaultApiBaseUrl = '';

  // Timeouts (los mantienes igual)
  static const Duration connectTimeout = Duration(seconds: 5);
  static const Duration receiveTimeout = Duration(seconds: 10);

  final SecureStore store;
  AppConfig({required this.store});

  /// Obtiene baseUrl desde storage. Si no existe, queda sin configurar.
  Future<String> getApiBaseUrl() async {
    final saved = await store.readBaseUrl();
    final v = (saved ?? '').trim();
    if (v.isEmpty) return defaultApiBaseUrl;
    return v;
  }

  /// Guarda baseUrl en storage.
  Future<void> setApiBaseUrl(String url) async {
    await store.saveBaseUrl(url);
  }
}
