import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:estacionamiento_central_mobile/features/home/presentation/home_screen.dart';
import 'package:estacionamiento_central_mobile/core/app_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  Future<void> prepareServices({_SummaryAdapter? adapter}) async {
    await AppServices.I.init();
    AppServices.I.client.dio.options.baseUrl = 'http://example.test/api/v1';
    AppServices.I.client.dio.httpClientAdapter = adapter ?? _SummaryAdapter();
  }

  testWidgets(
    'home exposes unified daily operation without removing Lavados/Baño',
    (tester) async {
      await prepareServices();

      await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Operación diaria unificada'), findsOneWidget);
      expect(find.text('Lavados / Baño'), findsOneWidget);
      expect(find.text('Ingreso'), findsOneWidget);
      expect(find.text('Activos / Salida'), findsOneWidget);
    },
  );

  testWidgets('home exposes Gastos for administrators', (tester) async {
    await prepareServices();
    await AppServices.I.store.saveSession(
      token: 'token',
      user: 'admin',
      role: 'admin',
    );
    expect(await AppServices.I.store.readRole(), 'admin');

    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Gastos'),
      200,
      scrollable: find.byType(Scrollable),
    );

    expect(find.text('Gastos'), findsOneWidget);
  });

  testWidgets('home exposes Mensuales, Cierres and Gastos for operators only', (
    tester,
  ) async {
    await prepareServices();
    await AppServices.I.store.saveSession(
      token: 'token',
      user: 'operador',
      role: 'operador',
    );

    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Cierres'),
      200,
      scrollable: find.byType(Scrollable),
    );
    expect(find.text('Cierres'), findsOneWidget);
    expect(find.text('Gastos'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Mensuales'),
      200,
      scrollable: find.byType(Scrollable),
    );

    expect(find.text('Mensuales'), findsOneWidget);
    expect(find.text('Reportes'), findsNothing);
    expect(find.text('Usuarios'), findsNothing);
    expect(find.text('Configuración'), findsNothing);
  });

  testWidgets('home shows the shift summary metrics for operators', (
    tester,
  ) async {
    await prepareServices();
    await AppServices.I.store.saveSession(
      token: 'token',
      user: 'operador',
      role: 'operador',
    );

    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Resumen del turno'), findsOneWidget);
    expect(find.text('Vehículos activos'), findsOneWidget);
    expect(find.text('Usos de baños'), findsOneWidget);
    expect(find.text('Total turno'), findsOneWidget);
    expect(find.text('Actual en caja'), findsNothing);
    expect(find.text('Total proyectado'), findsOneWidget);
    expect(find.text('Neto en caja'), findsOneWidget);
    expect(find.text('7 · \$2100'), findsOneWidget);
    expect(find.text('\$54300'), findsOneWidget);
  });

  testWidgets('privacy mode hides summary values and reveals a card on tap', (
    tester,
  ) async {
    await prepareServices();
    await AppServices.I.store.saveSession(
      token: 'token',
      user: 'operador',
      role: 'operador',
    );
    await AppServices.I.store.saveMetricsPrivacyModeEnabled(true);

    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Oculto'), findsNothing);
    final hiddenPlaceholder = find.byKey(
      const ValueKey('shift-metric-hidden-Total turno'),
    );
    expect(hiddenPlaceholder, findsOneWidget);
    final hiddenCard = find.ancestor(
      of: hiddenPlaceholder,
      matching: find.byType(InkWell),
    );
    expect(
      find.descendant(of: hiddenCard, matching: find.byIcon(Icons.payments)),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.visibility_off), findsNothing);
    expect(find.text('\$48200'), findsNothing);
    await tester.tap(find.text('Total turno'));
    await tester.pump();
    expect(find.text('\$48200'), findsOneWidget);
    await tester.tap(find.text('Total turno'));
    await tester.pump();
    expect(find.text('\$48200'), findsNothing);
  });

  testWidgets('home does not invent a projected total from a legacy response', (
    tester,
  ) async {
    await prepareServices(
      adapter: _SummaryAdapter(includeProjectedTotal: false),
    );
    await AppServices.I.store.saveSession(
      token: 'token',
      user: 'operador',
      role: 'operador',
    );

    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Total proyectado'), findsOneWidget);
    expect(find.text('No disponible'), findsOneWidget);
    expect(find.text('\$60100'), findsNothing);
  });
}

class _SummaryAdapter implements HttpClientAdapter {
  final bool includeProjectedTotal;

  _SummaryAdapter({this.includeProjectedTotal = true});

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      jsonEncode({
        'consultado_a': '2026-08-02T21:40:00',
        'vehiculos_activos': 12,
        'usos_banos': 7,
        'usos_banos_monto': 2100,
        'total_turno': 48200,
        'total_actual_caja': 60100,
        'estimado_activos': 6100,
        'neto_caja': 55600,
        if (includeProjectedTotal) 'total_proyectado': 54300,
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
