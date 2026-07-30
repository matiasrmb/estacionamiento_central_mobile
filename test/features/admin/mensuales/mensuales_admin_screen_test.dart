import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:estacionamiento_central_mobile/core/app_services.dart';
import 'package:estacionamiento_central_mobile/features/admin/mensuales/presentation/mensuales_admin_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  testWidgets('shows paid details and does not offer another payment', (
    tester,
  ) async {
    await _setAdmin();
    AppServices.I.client.dio.httpClientAdapter = _MonthlyScreenAdapter(
      paid: true,
    );

    await tester.pumpWidget(const MaterialApp(home: MensualesAdminScreen()));
    await tester.pumpAndSettle();

    expect(find.textContaining('Pagado'), findsOneWidget);
    expect(find.textContaining(r'Pago: $25000'), findsOneWidget);
    expect(find.textContaining(r'Tarifa mensual: $35000'), findsOneWidget);
    expect(find.byTooltip('Registrar pago'), findsNothing);
  });

  testWidgets('confirms an unpaid payment and refreshes its status', (
    tester,
  ) async {
    await _setAdmin();
    final adapter = _MonthlyScreenAdapter();
    AppServices.I.client.dio.httpClientAdapter = adapter;

    await tester.pumpWidget(const MaterialApp(home: MensualesAdminScreen()));
    await tester.pumpAndSettle();
    expect(find.textContaining('Pendiente'), findsOneWidget);

    await tester.tap(find.byTooltip('Registrar pago'));
    await tester.pumpAndSettle();
    expect(find.text('Confirmar pago'), findsOneWidget);
    await tester.tap(find.widgetWithText(ElevatedButton, 'Registrar pago'));
    await tester.pumpAndSettle();

    expect(adapter.paymentRequests, 1);
    expect(adapter.listRequests, 2);
    expect(find.textContaining('Pagado'), findsOneWidget);
    expect(find.byTooltip('Registrar pago'), findsNothing);
  });

  testWidgets('shows a placeholder when a paid amount is absent', (
    tester,
  ) async {
    await _setAdmin();
    AppServices.I.client.dio.httpClientAdapter = _MonthlyScreenAdapter(
      paid: true,
      missingPaidAmount: true,
    );

    await tester.pumpWidget(const MaterialApp(home: MensualesAdminScreen()));
    await tester.pumpAndSettle();

    expect(find.textContaining('Pago: Monto no disponible'), findsOneWidget);
    expect(find.textContaining(r'Pago: $35000'), findsNothing);
  });

  testWidgets('validates positive fee and due day when editing', (
    tester,
  ) async {
    await _setAdmin();
    AppServices.I.client.dio.httpClientAdapter = _MonthlyScreenAdapter();

    await tester.pumpWidget(const MaterialApp(home: MensualesAdminScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.edit));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(1), '0');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Guardar'));
    await tester.pump();
    expect(
      find.text('Ingresa patente y una tarifa mayor a cero.'),
      findsOneWidget,
    );

    await tester.enterText(find.byType(TextFormField).at(1), '35000');
    await tester.enterText(find.byType(TextFormField).at(2), '32');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Guardar'));
    await tester.pump();
    expect(
      find.text('Ingresa un día de vencimiento entre 1 y 31.'),
      findsOneWidget,
    );
  });
}

Future<void> _setAdmin() async {
  await AppServices.I.init();
  await AppServices.I.store.saveSession(
    token: 'token',
    user: 'admin',
    role: 'admin',
  );
}

class _MonthlyScreenAdapter implements HttpClientAdapter {
  _MonthlyScreenAdapter({this.paid = false, this.missingPaidAmount = false});

  bool paid;
  final bool missingPaidAmount;
  int listRequests = 0;
  int paymentRequests = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.method == 'POST' && options.path.endsWith('/pagos')) {
      paymentRequests++;
      paid = true;
    }
    if (options.method == 'GET') listRequests++;
    return ResponseBody.fromString(
      jsonEncode({
        'items': [
          {
            'id_vehiculo': 12,
            'patente': 'AB123CD',
            'tarifa_mensual': 35000,
            'dia_vencimiento': 5,
            'periodo_actual': '2026-07',
            'estado_pago': paid ? 'pagado' : 'pendiente',
            'pagado_periodo_actual': paid,
            'fecha_pago': paid ? '2026-07-29T10:30:00' : null,
            'monto_snapshot': paid && !missingPaidAmount ? 25000 : null,
          },
        ],
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
