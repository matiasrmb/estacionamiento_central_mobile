import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:estacionamiento_central_mobile/core/http_client.dart';
import 'package:estacionamiento_central_mobile/core/storage.dart';
import 'package:estacionamiento_central_mobile/features/home/data/shift_summary_api.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  test('loads the shift summary contract', () async {
    final adapter = _SummaryAdapter();
    final client = ApiClient(store: SecureStore())
      ..dio.options.baseUrl = 'http://example.test/api/v1'
      ..dio.httpClientAdapter = adapter;

    final summary = await ShiftSummaryApi(client).obtenerResumen();

    expect(adapter.request?.uri.path, '/api/v1/resumen-turno');
    expect(summary.vehiculosActivos, 12);
    expect(summary.usosBanosMonto, 2100);
    expect(summary.totalTurno, 48200);
    expect(summary.netoCaja, 55600);
  });
}

class _SummaryAdapter implements HttpClientAdapter {
  RequestOptions? request;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    request = options;
    return ResponseBody.fromString(
      jsonEncode({
        'consultado_a': '2026-08-02T21:40:00',
        'vehiculos_activos': 12,
        'usos_banos': 7,
        'usos_banos_monto': 2100,
        'total_turno': 48200,
        'total_actual_caja': 60100,
        'neto_caja': 55600,
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
