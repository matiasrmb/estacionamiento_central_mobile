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

  testWidgets(
    'home exposes unified daily operation without removing Lavados/Baño',
    (tester) async {
      await AppServices.I.init();

      await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
      await tester.pump();

      expect(find.text('Operación diaria unificada'), findsOneWidget);
      expect(find.text('Lavados / Baño'), findsOneWidget);
      expect(find.text('Ingreso'), findsOneWidget);
      expect(find.text('Activos / Salida'), findsOneWidget);
    },
  );

  testWidgets('home exposes Gastos for administrators', (tester) async {
    await AppServices.I.init();
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
}
