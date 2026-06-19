import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:estacionamiento_central_mobile/app.dart';

void main() {
  testWidgets('renders placeholder screen smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: PlaceholderScreen(title: 'Smoke')),
    );

    expect(find.text('Smoke'), findsOneWidget);
    expect(find.text('Pendiente de implementar en el siguiente paso'), findsOneWidget);
  });
}
