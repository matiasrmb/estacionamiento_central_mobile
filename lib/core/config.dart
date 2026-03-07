import 'storage.dart';

class AppConfig {
  // Default conservador (si no existe aún en SecureStore)
  // Puedes dejar aquí tu IP de “desarrollo” como fallback.
  // Server desarrollo : 192.168.1.13
  static const String defaultApiBaseUrl = 'http://192.168.100.1:8000/api/v1';

  // Timeouts (los mantienes igual)
  static const Duration connectTimeout = Duration(seconds: 5);
  static const Duration receiveTimeout = Duration(seconds: 10);

  final SecureStore store;
  AppConfig({required this.store});

  /// Obtiene baseUrl desde storage. Si no existe, usa defaultApiBaseUrl.
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