import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:estacionamiento_central_mobile/core/http_client.dart';
import 'package:estacionamiento_central_mobile/core/storage.dart';
import 'package:estacionamiento_central_mobile/features/admin/gastos/data/gastos_api.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  test('maps pending expenses and sends the create contract', () async {
    final adapter = _RecordingAdapter();
    final client = ApiClient(store: SecureStore())
      ..dio.options.baseUrl = 'http://example.test/api/v1'
      ..dio.httpClientAdapter = adapter;
    final api = GastosApi(client);

    final pending = await api.listarPendientes();
    await api.crear(categoria: 'Insumos', descripcion: 'Agua', monto: 250);

    expect(pending['total_gastos'], 250);
    expect(
      (pending['items'] as List).single['fecha_hora'],
      '2026-07-29T10:30:00',
    );
    expect(adapter.requests[0].uri.path, '/api/v1/gastos/pendientes');
    expect(adapter.requests[1].uri.path, '/api/v1/gastos');
    expect(adapter.requests[1].method, 'POST');
    expect(adapter.bodies[1], {
      'categoria': 'Insumos',
      'descripcion': 'Agua',
      'monto': 250,
    });
  });
}

class _RecordingAdapter implements HttpClientAdapter {
  final requests = <RequestOptions>[];
  final bodies = <dynamic>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final bytes = requestStream == null
        ? Uint8List(0)
        : await requestStream.fold<Uint8List>(Uint8List(0), (buffer, chunk) {
            return Uint8List.fromList([...buffer, ...chunk]);
          });
    bodies.add(bytes.isEmpty ? null : jsonDecode(utf8.decode(bytes)));

    final response = options.path.endsWith('/pendientes')
        ? {
            'items': [
              {
                'fecha_hora': '2026-07-29T10:30:00',
                'categoria': 'Insumos',
                'descripcion': 'Agua',
                'monto': 250,
              },
            ],
            'total_gastos': 250,
          }
        : {'id_gasto': 1};
    return ResponseBody.fromString(
      jsonEncode(response),
      options.path.endsWith('/pendientes') ? 200 : 201,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
