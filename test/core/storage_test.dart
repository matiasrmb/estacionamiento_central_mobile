import 'package:estacionamiento_central_mobile/core/storage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  test('persists one device id while clearing only the session', () async {
    final store = SecureStore();
    final deviceId = await store.getOrCreateDeviceId();

    await store.saveSession(token: 'token', user: 'operator', role: 'operador');
    await store.clear();

    expect(await store.getOrCreateDeviceId(), deviceId);
    expect(await store.readToken(), isNull);
  });

  test('separate storage installs generate different device ids', () async {
    final first = SecureStore();
    final firstId = await first.getOrCreateDeviceId();

    FlutterSecureStorage.setMockInitialValues({});
    final secondId = await SecureStore().getOrCreateDeviceId();

    expect(secondId, isNot(firstId));
  });
}
