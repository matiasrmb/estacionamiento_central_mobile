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
      final adapter = _TotalsAdapter();
      AppServices.I.client.dio.httpClientAdapter = adapter;

      await tester.pumpWidget(const MaterialApp(home: ReportesAdminScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Mensualidades comerciales'), findsOneWidget);
      expect(find.text(r'$70000'), findsOneWidget);
      expect(find.text('Neto operacional'), findsOneWidget);
      expect(find.text(r'$75000'), findsOneWidget);
      await tester.drag(find.byType(ListView), const Offset(0, -500));
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Los reportes cerrados y las exportaciones estarán disponibles en una versión 1.3.x posterior.',
        ),
        findsOneWidget,
      );
      expect(find.text('Fecha inicio'), findsNothing);
      expect(find.text('Fecha fin'), findsNothing);
      expect(find.text('Filtrar'), findsNothing);
      expect(find.text('Ordenar'), findsNothing);
      expect(find.text('Página'), findsNothing);
      expect(find.widgetWithText(TextButton, 'Anterior'), findsNothing);
      expect(find.widgetWithText(ElevatedButton, 'Anterior'), findsNothing);
      expect(find.widgetWithText(OutlinedButton, 'Anterior'), findsNothing);
      expect(find.widgetWithText(TextButton, 'Siguiente'), findsNothing);
      expect(find.widgetWithText(ElevatedButton, 'Siguiente'), findsNothing);
      expect(find.widgetWithText(OutlinedButton, 'Siguiente'), findsNothing);
      expect(find.widgetWithText(TextButton, 'Exportar'), findsNothing);
      expect(find.widgetWithText(ElevatedButton, 'Exportar'), findsNothing);
      expect(find.widgetWithText(OutlinedButton, 'Exportar'), findsNothing);
      expect(find.widgetWithText(TextButton, 'Descargar'), findsNothing);
      expect(find.widgetWithText(ElevatedButton, 'Descargar'), findsNothing);
      expect(find.widgetWithText(OutlinedButton, 'Descargar'), findsNothing);
      expect(
        adapter.requestedPaths,
        equals(['/reporting/metric-catalog', '/reporting/dashboard']),
      );
    },
  );

  testWidgets(
    'keeps closed dashboard state deferred without report retrieval flows',
    (tester) async {
      await AppServices.I.init();
      await SecureStore().saveSession(
        token: 'admin-token',
        user: 'admin',
        role: 'admin',
      );
      final adapter = _TotalsAdapter(periodState: 'closed');
      AppServices.I.client.dio.httpClientAdapter = adapter;

      await tester.pumpWidget(const MaterialApp(home: ReportesAdminScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Jornada operacional cerrada'), findsOneWidget);
      await tester.drag(find.byType(ListView), const Offset(0, -500));
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Los reportes cerrados y las exportaciones estarán disponibles en una versión 1.3.x posterior.',
        ),
        findsOneWidget,
      );
      expect(find.text('Reporte cerrado'), findsNothing);
      expect(find.text('Reportes cerrados'), findsNothing);
      expect(
        find.widgetWithText(TextButton, 'Ver reporte cerrado'),
        findsNothing,
      );
      expect(
        find.widgetWithText(ElevatedButton, 'Ver reporte cerrado'),
        findsNothing,
      );
      expect(
        find.widgetWithText(OutlinedButton, 'Ver reporte cerrado'),
        findsNothing,
      );
      expect(
        adapter.requestedPaths,
        equals(['/reporting/metric-catalog', '/reporting/dashboard']),
      );
    },
  );

  testWidgets(
    'ignores closed report and export metadata from dashboard payloads',
    (tester) async {
      await AppServices.I.init();
      await SecureStore().saveSession(
        token: 'admin-token',
        user: 'admin',
        role: 'admin',
      );
      AppServices.I.client.dio.httpClientAdapter = _TotalsAdapter(
        includeOutOfScopeFields: true,
      );

      await tester.pumpWidget(const MaterialApp(home: ReportesAdminScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Mensualidades comerciales'), findsOneWidget);
      expect(find.text('closed-report-available'), findsNothing);
      expect(find.text('csv'), findsNothing);
      expect(find.text('pdf'), findsNothing);
      expect(find.text('xlsx'), findsNothing);
      expect(find.widgetWithText(TextButton, 'CSV'), findsNothing);
      expect(find.widgetWithText(ElevatedButton, 'CSV'), findsNothing);
      expect(find.widgetWithText(OutlinedButton, 'CSV'), findsNothing);
      expect(find.widgetWithText(TextButton, 'PDF'), findsNothing);
      expect(find.widgetWithText(ElevatedButton, 'PDF'), findsNothing);
      expect(find.widgetWithText(OutlinedButton, 'PDF'), findsNothing);
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
  final String periodState;
  final bool includeOutOfScopeFields;
  final List<String> requestedPaths;

  _TotalsAdapter({
    this.periodState = 'open',
    this.includeOutOfScopeFields = false,
  }) : requestedPaths = <String>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requestedPaths.add(options.path);
    final dashboard = {
      'period': {'id': 'open:1', 'state': periodState},
      'catalog_version': '2026-09-29',
      'metrics': {
        'operational_income_total': 76000,
        'operational_expense_total': 0,
        'operational_net_total': 75000,
        'mensualidad_sales_total': 70000,
        'vehicle_movement_count': 0,
      },
      if (includeOutOfScopeFields) ...{
        'closed_reports': [
          {'label': 'closed-report-available', 'download_url': '/reports/1'},
        ],
        'exports': {
          'formats': ['csv', 'pdf', 'xlsx'],
        },
        'download': {'enabled': true},
      },
    };
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
        ? dashboard
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
