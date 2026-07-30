import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:estacionamiento_central_mobile/core/app_services.dart';
import 'package:estacionamiento_central_mobile/features/admin/gastos/presentation/gastos_admin_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  testWidgets(
    'operator direct navigation to gastos can validate, create, and refresh',
    (tester) async {
      await AppServices.I.init();
      await AppServices.I.store.saveSession(
        token: 'token',
        user: 'operador',
        role: 'operador',
      );
      final adapter = _CountingAdapter();
      AppServices.I.client.dio.httpClientAdapter = adapter;
      final router = GoRouter(
        initialLocation: '/admin/gastos',
        routes: [
          GoRoute(
            path: '/admin/gastos',
            builder: (context, state) => const GastosAdminScreen(),
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      final submitButton = find.widgetWithText(
        ElevatedButton,
        'Registrar gasto',
      );
      expect(find.text('Registrar gasto'), findsNWidgets(2));
      expect(adapter.requestCount, 1);

      await tester.enterText(find.byType(TextFormField).at(0), 'Agua');
      await tester.enterText(find.byType(TextFormField).at(1), '250');
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      expect(adapter.requestCount, 3);
    },
  );

  testWidgets('administrator can validate, create, and refresh gastos', (
    tester,
  ) async {
    await AppServices.I.init();
    await AppServices.I.store.saveSession(
      token: 'token',
      user: 'admin',
      role: 'admin',
    );
    final adapter = _CountingAdapter();
    AppServices.I.client.dio.httpClientAdapter = adapter;

    await tester.pumpWidget(const MaterialApp(home: GastosAdminScreen()));
    await tester.pumpAndSettle();

    final submitButton = find.widgetWithText(ElevatedButton, 'Registrar gasto');
    expect(find.text('Registrar gasto'), findsNWidgets(2));
    expect(adapter.requestCount, 1);

    await tester.tap(submitButton);
    await tester.pump();
    expect(find.text('Ingresa una descripción.'), findsOneWidget);
    expect(find.text('Ingresa un monto entero mayor a cero.'), findsOneWidget);
    expect(adapter.requestCount, 1);

    await tester.enterText(find.byType(TextFormField).at(0), 'Agua');
    await tester.enterText(find.byType(TextFormField).at(1), '250');
    await tester.tap(submitButton);
    await tester.pumpAndSettle();

    expect(adapter.requestCount, 3);
    expect(find.text('Gasto registrado.'), findsOneWidget);
    expect(find.text('Agua'), findsNothing);
    expect(find.text('250'), findsNothing);
  });
}

class _CountingAdapter implements HttpClientAdapter {
  int requestCount = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requestCount++;
    final response = options.method == 'GET'
        ? {'items': <Map<String, dynamic>>[], 'total_gastos': 0}
        : {'id_gasto': 1};
    return ResponseBody.fromString(
      jsonEncode(response),
      options.method == 'GET' ? 200 : 201,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
