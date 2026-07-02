import 'package:estacionamiento_central_mobile/core/config.dart';
import 'package:estacionamiento_central_mobile/core/storage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  test('does not fall back to a development LAN IP when no server is saved', () async {
    final config = AppConfig(store: SecureStore());

    final baseUrl = await config.getApiBaseUrl();

    expect(baseUrl, isEmpty);
    expect(AppConfig.defaultApiBaseUrl, isEmpty);
    expect(baseUrl, isNot(contains('192.168.')));
  });

  test('keeps a saved QR or manual server URL as the active base URL', () async {
    final config = AppConfig(store: SecureStore());
    const savedUrl = 'http://10.10.0.25:8000/api/v1';

    await config.setApiBaseUrl(savedUrl);

    expect(await config.getApiBaseUrl(), savedUrl);
  });
}
