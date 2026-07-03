import 'package:estacionamiento_central_mobile/features/operacion_diaria/domain/cotizacion_time.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CotizacionTime', () {
    test('calcula minutos usando HH:MM', () {
      expect(CotizacionTime.calcularMinutosPorHorarios('13:00', '19:00'), 360);
    });

    test('calcula minutos usando HHMM compacto', () {
      expect(CotizacionTime.calcularMinutosPorHorarios('1300', '1900'), 360);
    });

    test('normaliza hora compacta de tres digitos', () {
      expect(CotizacionTime.parseHora('900', 'ingreso'), 9 * 60);
    });

    test('rechaza horarios invalidos con mensaje amigable', () {
      expect(
        () => CotizacionTime.parseHora('24:00', 'salida'),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            'Ingresá una hora de salida válida.',
          ),
        ),
      );
    });
  });
}
