import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:estacionamiento_central_mobile/core/app_services.dart';
import 'package:estacionamiento_central_mobile/core/storage.dart';
import 'package:estacionamiento_central_mobile/features/admin/reportes/data/reportes_api.dart';
import 'package:estacionamiento_central_mobile/features/admin/reportes/presentation/reportes_admin_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  test(
    'client fetches canonical reporting dashboard and 1.3.0 catalog labels',
    () async {
      await AppServices.I.init();
      final adapter = _ReportingAdapter();
      AppServices.I.client.dio.httpClientAdapter = adapter;

      final dashboard = await ReportesApi(AppServices.I.client).dashboard();

      expect(adapter.paths, <String>[
        '/reporting/metric-catalog',
        '/reporting/dashboard',
      ]);
      expect(dashboard.catalogVersion, '2026-09-29');
      expect(dashboard.periodState, 'open');
      expect(dashboard.appVersion, '1.3.0');
      expect(dashboard.cards.map((card) => card.label), <String>[
        'Ingresos operacionales',
        'Gastos operacionales',
        'Neto operacional',
        'Mensualidades comerciales',
        'Movimientos de vehículos',
      ]);
      expect(dashboard.cards.map((card) => card.value), <num>[
        2500,
        300,
        2200,
        70000,
        12,
      ]);
    },
  );

  testWidgets(
    'screen denies report access to non-admin users without loading totals',
    (tester) async {
      await AppServices.I.init();
      await SecureStore().saveSession(
        token: 'operator-token',
        user: 'operator',
        role: 'operador',
      );
      final adapter = _ReportingAdapter();
      AppServices.I.client.dio.httpClientAdapter = adapter;

      await tester.pumpWidget(const MaterialApp(home: ReportesAdminScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Reportes administrativos'), findsOneWidget);
      expect(
        find.text('Solo administradores pueden ver reportes financieros.'),
        findsOneWidget,
      );
      expect(find.text('Ingresos operacionales'), findsNothing);
      expect(adapter.paths, isEmpty);
    },
  );

  testWidgets('screen renders API-backed 1.3.0 dashboard labels for admins', (
    tester,
  ) async {
    await AppServices.I.init();
    await SecureStore().saveSession(
      token: 'admin-token',
      user: 'admin',
      role: 'admin',
    );
    AppServices.I.client.dio.httpClientAdapter = _ReportingAdapter();

    await tester.pumpWidget(const MaterialApp(home: ReportesAdminScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Reportes administrativos'), findsOneWidget);
    expect(find.text('Versión 1.3.0'), findsOneWidget);
    expect(find.text('Catálogo 2026-09-29'), findsOneWidget);
    expect(find.text('Jornada operacional abierta'), findsOneWidget);
    expect(find.text('Ingresos operacionales'), findsOneWidget);
    expect(find.text(r'$2500'), findsOneWidget);
    expect(find.text('Neto operacional'), findsOneWidget);
    expect(find.text(r'$2200'), findsOneWidget);
  });
}

class _ReportingAdapter implements HttpClientAdapter {
  final paths = <String>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    paths.add(options.path);
    final response = switch (options.path) {
      '/reporting/metric-catalog' => _metricCatalog,
      '/reporting/dashboard' => _dashboard,
      _ => <String, Object?>{},
    };

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

const _metricCatalog = {
  'version': '2026-09-29',
  'metrics': [
    {
      'name': 'operational_income_total',
      'meaning': 'Payments collected from operational sources',
      'sign': 'positive',
    },
    {
      'name': 'operational_expense_total',
      'meaning': 'Operational expenses',
      'sign': 'positive_expense_negative_result',
    },
    {
      'name': 'operational_net_total',
      'meaning': 'Income minus expenses',
      'sign': 'signed',
    },
    {
      'name': 'mensualidad_sales_total',
      'meaning': 'Commercial mensualidad activity',
      'sign': 'positive',
    },
    {
      'name': 'vehicle_movement_count',
      'meaning': 'Vehicle entries/exits in the period',
      'sign': 'count',
    },
  ],
};

const _dashboard = {
  'period': {'id': 'open:8', 'state': 'open'},
  'catalog_version': '2026-09-29',
  'metrics': {
    'operational_income_total': 2500,
    'operational_expense_total': 300,
    'operational_net_total': 2200,
    'mensualidad_sales_total': 70000,
    'vehicle_movement_count': 12,
  },
};
