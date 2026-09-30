import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:estacionamiento_central_mobile/core/app_services.dart';
import 'package:estacionamiento_central_mobile/core/storage.dart';
import 'package:estacionamiento_central_mobile/features/admin/cierres/presentation/cierres_admin_screen.dart';
import 'package:estacionamiento_central_mobile/features/admin/reportes/presentation/reportes_admin_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  testWidgets(
    'shows monthly totals in the reporting dashboard when returned by the API',
    (tester) async {
      await AppServices.I.init();
      await SecureStore().saveSession(
        token: 'admin-token',
        user: 'admin',
        role: 'admin',
      );
      AppServices.I.client.dio.httpClientAdapter = _TotalsAdapter();

      await tester.pumpWidget(const MaterialApp(home: ReportesAdminScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Mensualidades comerciales'), findsOneWidget);
      expect(find.text(r'$70000'), findsOneWidget);
      expect(find.text('Neto operacional'), findsOneWidget);
      expect(find.text(r'$75000'), findsOneWidget);
    },
  );

  testWidgets('shows monthly totals in the pending close when provided', (
    tester,
  ) async {
    await AppServices.I.init();
    AppServices.I.client.dio.httpClientAdapter = _TotalsAdapter();

    await tester.pumpWidget(const MaterialApp(home: CierresAdminScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Mensualidades:'), findsOneWidget);
    expect(find.text(r'2 / $70000'), findsOneWidget);
    expect(find.text('Noches prepagadas:'), findsOneWidget);
    expect(find.text(r'1 / $5000'), findsOneWidget);
  });
}

class _TotalsAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final response = options.path.endsWith('/metric-catalog')
        ? {
            'version': '2026-09-29',
            'metrics': [
              {'name': 'operational_income_total', 'sign': 'positive'},
              {
                'name': 'operational_expense_total',
                'sign': 'positive_expense_negative_result',
              },
              {'name': 'operational_net_total', 'sign': 'signed'},
              {'name': 'mensualidad_sales_total', 'sign': 'positive'},
              {'name': 'vehicle_movement_count', 'sign': 'count'},
            ],
          }
        : options.path.endsWith('/dashboard')
        ? {
            'period': {'id': 'open:1', 'state': 'open'},
            'catalog_version': '2026-09-29',
            'metrics': {
              'operational_income_total': 76000,
              'operational_expense_total': 0,
              'operational_net_total': 75000,
              'mensualidad_sales_total': 70000,
              'vehicle_movement_count': 0,
            },
          }
        : options.path.endsWith('/pendiente')
        ? {
            'hay_pendiente': true,
            'fecha_inicio': '2026-07-29T08:00:00',
            'fecha_cierre': '2026-07-29T18:00:00',
            'total_salidas': 1,
            'total_recaudado': 1000,
            'total_banos': 0,
            'total_banos_monto': 0,
            'total_mensualidades': 2,
            'total_mensualidades_monto': 70000,
            'total_noches': 1,
            'total_noches_monto': 5000,
            'total_general': 76000,
            'total_gastos': 0,
            'total_neto': 76000,
          }
        : {'items': []};
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
