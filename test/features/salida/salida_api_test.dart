import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:estacionamiento_central_mobile/core/http_client.dart';
import 'package:estacionamiento_central_mobile/core/storage.dart';
import 'package:estacionamiento_central_mobile/features/salida/data/salida_api.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  test('uses the pending night resolution endpoints', () async {
    final adapter = _RecordingAdapter();
    final client = ApiClient(store: SecureStore())
      ..dio.options.baseUrl = 'http://example.test/api/v1'
      ..dio.httpClientAdapter = adapter;
    final api = SalidaApi(client);

    await api.finalizarNoche(idIngreso: 12);
    await api.convertirNoche(idIngreso: 12);

    expect(adapter.requests, [
      ('POST', '/api/v1/salidas/12/noche/finalizar'),
      ('POST', '/api/v1/salidas/12/noche/convertir'),
    ]);
  });

  test('confirms salida without the deprecated Sunmi payload field', () async {
    final adapter = _RecordingAdapter();
    final client = ApiClient(store: SecureStore())
      ..dio.options.baseUrl = 'http://example.test/api/v1'
      ..dio.httpClientAdapter = adapter;
    final api = SalidaApi(client);

    await api.confirmarSalida(idIngreso: 12);

    expect(adapter.requests, [('POST', '/api/v1/salidas/confirm')]);
    expect(adapter.requestBodies, [{'id_ingreso': 12}]);
  });
}

class _RecordingAdapter implements HttpClientAdapter {
  final requests = <(String, String)>[];
  final requestBodies = <Map<String, dynamic>>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add((options.method, options.uri.path));
    if (options.data is Map) {
      requestBodies.add(Map<String, dynamic>.from(options.data as Map));
    }
    return ResponseBody.fromString(
      jsonEncode({}),
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
