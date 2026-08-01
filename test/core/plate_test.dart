import 'package:estacionamiento_central_mobile/core/plate.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('accepts all supported normalized formats', () {
    for (final plate in ['ABCD12', 'ABC12', 'AB123CD', 'ABC123', 'AB1234']) {
      expect(isValidPlate(plate), isTrue);
    }
  });

  test('normalizes lowercase spaces and hyphens only', () {
    expect(normalizePlate('ab-cd 12'), 'ABCD12');
    expect(normalizePlate('ab-123 cd'), 'AB123CD');
  });

  test('rejects special and accented characters', () {
    for (final plate in [
      'AB{CD12',
      'AB[CD12',
      "ABCD1'2",
      'ÁBCD12',
      'ABCD.12',
    ]) {
      expect(isValidPlate(plate), isFalse);
    }
  });
}
