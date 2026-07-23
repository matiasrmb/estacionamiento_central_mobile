import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:estacionamiento_central_mobile/core/http_client.dart';
import 'package:estacionamiento_central_mobile/core/storage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  test(
    '401 clears session, preserves baseUrl, calls callback, and rejects',
    () async {
      final store = SecureStore();
      await store.saveSession(token: 'token', user: 'user', role: 'admin');
      await store.saveBaseUrl('http://example.test/api');

      var unauthorizedCalls = 0;
      final client = ApiClient(
        store: store,
        onUnauthorized: () async {
          unauthorizedCalls++;
        },
      )..dio.httpClientAdapter = _StatusAdapter(401);
      client.dio.options.baseUrl = 'http://example.test/api';

      await expectLater(
        client.dio.get('/protected'),
        throwsA(
          isA<DioException>().having(
            (e) => e.response?.statusCode,
            'statusCode',
            401,
          ),
        ),
      );

      expect(await store.readToken(), isNull);
      expect(await store.readUser(), isNull);
      expect(await store.readRole(), isNull);
      expect(await store.readBaseUrl(), 'http://example.test/api');
      expect(unauthorizedCalls, 1);
    },
  );

  test('non-401 does not clear session or call callback', () async {
    final store = SecureStore();
    await store.saveSession(token: 'token', user: 'user', role: 'admin');
    await store.saveBaseUrl('http://example.test/api');

    var unauthorizedCalls = 0;
    final client = ApiClient(
      store: store,
      onUnauthorized: () async {
        unauthorizedCalls++;
      },
    )..dio.httpClientAdapter = _StatusAdapter(500);
    client.dio.options.baseUrl = 'http://example.test/api';

    await expectLater(
      client.dio.get('/failed'),
      throwsA(
        isA<DioException>().having(
          (e) => e.response?.statusCode,
          'statusCode',
          500,
        ),
      ),
    );

    expect(await store.readToken(), 'token');
    expect(await store.readUser(), 'user');
    expect(await store.readRole(), 'admin');
    expect(await store.readBaseUrl(), 'http://example.test/api');
    expect(unauthorizedCalls, 0);
  });
}

class _StatusAdapter implements HttpClientAdapter {
  _StatusAdapter(this.statusCode);

  final int statusCode;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      '{"error":"test"}',
      statusCode,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
