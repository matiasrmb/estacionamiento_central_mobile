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
}
