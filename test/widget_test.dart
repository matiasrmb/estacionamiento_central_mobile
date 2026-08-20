import 'package:estacionamiento_central_mobile/app.dart';
import 'package:estacionamiento_central_mobile/features/bootstrap/presentation/bootstrap_screen.dart';
import 'package:estacionamiento_central_mobile/features/settings/presentation/server_settings_screen.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  testWidgets('starts the app at the bootstrap route', (tester) async {
    await tester.pumpWidget(App());

    expect(find.byType(BootstrapScreen), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 151));
    await tester.pump();

    expect(find.byType(ServerSettingsScreen), findsOneWidget);
  });
}
