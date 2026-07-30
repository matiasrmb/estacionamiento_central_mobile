import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:estacionamiento_central_mobile/core/http_client.dart';
import 'package:estacionamiento_central_mobile/core/storage.dart';
import 'package:estacionamiento_central_mobile/features/admin/mensuales/data/mensuales_api.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  test(
    'parses backend payment fields and sends config and payment contracts',
    () async {
      final adapter = _MensualesAdapter();
      final client = ApiClient(store: SecureStore())
        ..dio.options.baseUrl = 'http://example.test/api/v1'
        ..dio.httpClientAdapter = adapter;
      final api = MensualesApi(client);

      final mensual = (await api.listar()).single;
      await api.actualizarConfiguracion(
        idVehiculo: 12,
        tarifaMensual: 35000,
        diaVencimiento: 10,
      );
      await api.registrarPago(
        idVehiculo: 12,
        metodoPago: 'efectivo',
        observacion: 'Pago en caja',
      );

      expect(mensual.diaVencimiento, 5);
      expect(mensual.periodoActual, '2026-07');
      expect(mensual.estadoPagoTexto, 'Pagado');
      expect(mensual.pagado, isTrue);
      expect(mensual.fechaPago, '2026-07-01T10:30:00');
      expect(mensual.montoPago, 25000);
      expect(adapter.requests.map((request) => request.uri.path), [
        '/api/v1/mensuales',
        '/api/v1/mensuales/12',
        '/api/v1/mensuales/12/pagos',
      ]);
      expect(adapter.requests[1].method, 'PUT');
      expect(adapter.bodies[1], {
        'tarifa_mensual': 35000,
        'dia_vencimiento': 10,
      });
      expect(adapter.requests[2].method, 'POST');
      expect(adapter.bodies[2], {
        'metodo_pago': 'efectivo',
        'observacion': 'Pago en caja',
      });
    },
  );
}

class _MensualesAdapter implements HttpClientAdapter {
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
    final response = options.method == 'GET'
        ? {
            'items': [
              {
                'id_vehiculo': 12,
                'patente': 'AB123CD',
                'tarifa_mensual': 35000,
                'dia_vencimiento': '5',
                'periodo_actual': '2026-07',
                'estado_pago': 'pagado',
                'pagado_periodo_actual': true,
                'fecha_pago': '2026-07-01T10:30:00',
                'monto_snapshot': 25000,
              },
            ],
          }
        : {'ok': true};
    return ResponseBody.fromString(
      jsonEncode(response),
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
