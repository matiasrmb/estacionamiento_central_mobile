import 'storage.dart';
import 'http_client.dart';

class AppServices {
  AppServices._();

  static final AppServices I = AppServices._();

  late final SecureStore store;
  late ApiClient client;

  bool _initialized = false;

  /// Inicializa servicios base una sola vez.
  Future<void> init() async {
    if (_initialized) return;

    store = SecureStore();
    client = ApiClient(store: store);
    await client.init();

    _initialized = true;
  }

  /// Relee baseUrl desde storage y lo aplica al Dio del cliente.
  Future<void> reloadClient() async {
    // Si no estaba inicializado, init lo deja listo igual.
    if (!_initialized) {
      await init();
      return;
    }

    await client.init(); // re-lee baseUrl desde store y setea dio.options.baseUrl
  }
}