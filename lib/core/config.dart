class AppConfig {
  // Base URL del backend en LAN.
  // Ejemplo: http://192.168.1.13:8000/api/v1
  // 192.168.100.28 - ESTACIONAMIENTO
  // 192.168.1.13 - DESARROLLO
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://192.168.1.13:8000/api/v1',
  );

  static const Duration connectTimeout = Duration(seconds: 5);
  static const Duration receiveTimeout = Duration(seconds: 10);
}