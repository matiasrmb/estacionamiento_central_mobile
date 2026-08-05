import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:estacionamiento_central_mobile/core/http_client.dart';
import 'package:estacionamiento_central_mobile/core/storage.dart';
import 'package:estacionamiento_central_mobile/features/auth/data/auth_api.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  test('sends the persisted device id on login', () async {
    final adapter = _RecordingAdapter();
    final client = ApiClient(store: SecureStore())
      ..dio.options.baseUrl = 'http://example.test/api/v1'
      ..dio.httpClientAdapter = adapter;

    await AuthApi(client).login(
      usuario: 'operator',
      clave: 'secret',
      deviceId: 'mobile-install-id',
    );

    expect(adapter.body, {
      'usuario': 'operator',
      'clave': 'secret',
      'device_id': 'mobile-install-id',
    });
  });
}

class _RecordingAdapter implements HttpClientAdapter {
  dynamic body;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final bytes = requestStream == null
        ? Uint8List(0)
        : await requestStream.fold<Uint8List>(Uint8List(0), (buffer, chunk) {
            return Uint8List.fromList([...buffer, ...chunk]);
          });
    body = jsonDecode(utf8.decode(bytes));
    return ResponseBody.fromString(
      jsonEncode(<String, dynamic>{}),
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
