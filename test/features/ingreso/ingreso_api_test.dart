import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:estacionamiento_central_mobile/core/http_client.dart';
import 'package:estacionamiento_central_mobile/core/storage.dart';
import 'package:estacionamiento_central_mobile/features/ingreso/data/ingreso_api.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  test('sends the prepaid nights ingreso contract when selected', () async {
    final adapter = _RecordingAdapter();
    final client = ApiClient(store: SecureStore())
      ..dio.options.baseUrl = 'http://example.test/api/v1'
      ..dio.httpClientAdapter = adapter;

    await IngresoApi(
      client,
    ).registrarIngreso(patente: 'ABCD12', nochesPrepagadas: true);

    expect(adapter.request!.uri.path, '/api/v1/ingresos');
    expect(adapter.request!.method, 'POST');
    expect(adapter.body, {'patente': 'ABCD12', 'noches_prepagadas': true});
  });
}

class _RecordingAdapter implements HttpClientAdapter {
  RequestOptions? request;
  dynamic body;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    request = options;
    final bytes = requestStream == null
        ? Uint8List(0)
        : await requestStream.fold<Uint8List>(Uint8List(0), (buffer, chunk) {
            return Uint8List.fromList([...buffer, ...chunk]);
          });
    body = bytes.isEmpty ? null : jsonDecode(utf8.decode(bytes));
    return ResponseBody.fromString(
      jsonEncode({
        'ingreso': {'id_ingreso': 1},
      }),
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
