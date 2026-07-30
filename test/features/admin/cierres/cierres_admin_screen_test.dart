import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:estacionamiento_central_mobile/core/app_services.dart';
import 'package:estacionamiento_central_mobile/features/admin/cierres/presentation/cierres_admin_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  testWidgets('operator can create a pending cierre and refresh its history', (
    tester,
  ) async {
    await AppServices.I.init();
    await AppServices.I.store.saveSession(
      token: 'token',
      user: 'operador',
      role: 'operador',
    );
    final adapter = _CierresAdapter();
    AppServices.I.client.dio.httpClientAdapter = adapter;

    await tester.pumpWidget(const MaterialApp(home: CierresAdminScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Cierre pendiente'), findsOneWidget);
    expect(find.text('Realizar cierre'), findsOneWidget);
    expect(adapter.requests, [
      ('GET', '/cierres/pendiente'),
      ('GET', '/cierres'),
    ]);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Realizar cierre'));
    await tester.pumpAndSettle();

    expect(find.text('Confirmar cierre'), findsOneWidget);
    await tester.tap(
      find.widgetWithText(ElevatedButton, 'Realizar cierre').last,
    );
    await tester.pumpAndSettle();

    expect(adapter.requests, [
      ('GET', '/cierres/pendiente'),
      ('GET', '/cierres'),
      ('POST', '/cierres'),
      ('GET', '/cierres/pendiente'),
      ('GET', '/cierres'),
    ]);
    expect(find.text('No hay salidas pendientes para cerrar.'), findsOneWidget);
    expect(find.text('Total general: \$1500'), findsOneWidget);
  });
}

class _CierresAdapter implements HttpClientAdapter {
  final List<(String, String)> requests = [];
  var _pendingRequests = 0;
  var _historyRequests = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add((options.method, options.path));
    final response = switch ((options.method, options.path)) {
      ('GET', '/cierres/pendiente') => _pendingResponse(),
      ('GET', '/cierres') => _historyResponse(),
      ('POST', '/cierres') => {'total_general': 1500},
      _ => <String, dynamic>{},
    };
    return ResponseBody.fromString(
      jsonEncode(response),
      options.method == 'POST' ? 201 : 200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}

  Map<String, dynamic> _pendingResponse() {
    _pendingRequests++;
    return _pendingRequests == 1
        ? {
            'hay_pendiente': true,
            'fecha_inicio': '2026-07-30 08:00',
            'fecha_cierre': '2026-07-30 18:00',
            'total_salidas': 3,
            'total_recaudado': 1500,
            'total_banos': 0,
            'total_banos_monto': 0,
            'total_general': 1500,
            'total_gastos': 0,
            'total_neto': 1500,
          }
        : {'hay_pendiente': false};
  }

  Map<String, dynamic> _historyResponse() {
    _historyRequests++;
    return _historyRequests == 1
        ? {'items': <Map<String, dynamic>>[]}
        : {
            'items': [
              {
                'fecha_inicio': '2026-07-30 08:00',
                'fecha_cierre': '2026-07-30 18:00',
                'total_salidas': 3,
                'total_banos': 0,
                'total_general': 1500,
              },
            ],
          };
  }
}
