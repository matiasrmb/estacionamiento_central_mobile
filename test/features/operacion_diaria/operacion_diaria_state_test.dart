import 'package:estacionamiento_central_mobile/features/operacion_diaria/data/operacion_diaria_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('operación diaria state', () {
    test('orders operation records newest-first by ingreso timestamp', () {
      final records = orderOperationRecordsNewestFirst([
        OperacionDiariaRecord(
          idIngreso: 1,
          patente: 'AAA111',
          fechaHoraIngreso: DateTime.parse('2026-07-01T08:00:00'),
        ),
        OperacionDiariaRecord(
          idIngreso: 2,
          patente: 'BBB222',
          fechaHoraIngreso: DateTime.parse('2026-07-01T10:30:00'),
        ),
        OperacionDiariaRecord(
          idIngreso: 3,
          patente: 'CCC333',
          fechaHoraIngreso: DateTime.parse('2026-07-01T09:15:00'),
        ),
      ]);

      expect(records.map((item) => item.patente), [
        'BBB222',
        'CCC333',
        'AAA111',
      ]);
    });

    test('offers ingreso when plate search has no active ingreso', () {
      final decision = decidePlateSearchAction(
        plateInput: 'zzz999',
        records: [
          OperacionDiariaRecord(
            idIngreso: 10,
            patente: 'ABC123',
            fechaHoraIngreso: DateTime.parse('2026-07-01T09:00:00'),
          ),
        ],
      );

      expect(decision.normalizedPlate, 'ZZZ999');
      expect(decision.primaryAction, OperacionDiariaAction.ingreso);
      expect(decision.activeRecord, isNull);
      expect(decision.message, contains('sin ingreso activo'));
    });

    test('offers salida for active ingreso unless the record is in lavado', () {
      final available = decidePlateSearchAction(
        plateInput: 'abc123',
        records: [
          OperacionDiariaRecord(
            idIngreso: 10,
            patente: 'ABC123',
            fechaHoraIngreso: DateTime.parse('2026-07-01T09:00:00'),
          ),
        ],
      );
      final blocked = decidePlateSearchAction(
        plateInput: 'abc123',
        records: [
          OperacionDiariaRecord(
            idIngreso: 10,
            patente: 'ABC123',
            fechaHoraIngreso: DateTime.parse('2026-07-01T09:00:00'),
            enLavado: true,
          ),
        ],
      );

      expect(available.primaryAction, OperacionDiariaAction.salida);
      expect(available.activeRecord?.idIngreso, 10);
      expect(
        blocked.primaryAction,
        OperacionDiariaAction.salidaBloqueadaPorLavado,
      );
      expect(blocked.message, contains('Finalizá el lavado'));
    });

    test(
      'filters Lavados/Baño active records by normalized plate fragment',
      () {
        final records = [
          OperacionDiariaRecord(
            idIngreso: 1,
            patente: 'AA 123 BB',
            fechaHoraIngreso: DateTime.parse('2026-07-01T08:00:00'),
          ),
          OperacionDiariaRecord(
            idIngreso: 2,
            patente: 'CC999DD',
            fechaHoraIngreso: DateTime.parse('2026-07-01T10:00:00'),
          ),
        ];

        expect(
          filterOperationRecordsByPlate(
            records,
            'a123',
          ).map((item) => item.patente),
          ['AA 123 BB'],
        );
        expect(
          filterOperationRecordsByPlate(
            records,
            '',
          ).map((item) => item.patente),
          ['AA 123 BB', 'CC999DD'],
        );
      },
    );

    test(
      'registers ingreso inline and refreshes records without navigation',
      () async {
        var registeredPlate = '';
        var printedPlate = '';
        Map<String, dynamic>? printedResponse;
        var refreshed = false;
        final actions = OperacionDiariaInlineActions(
          registrarIngreso: (patente) async {
            registeredPlate = patente;
            return {
              'ingreso': {'patente': patente},
            };
          },
          previewSalida: (_) async => <String, dynamic>{},
          confirmarSalida: (_) async => <String, dynamic>{},
          iniciarLavado: (idIngreso, categoria) async {},
          finalizarLavado: (_) async {},
          printIngreso: ({required patente, required response}) async {
            printedPlate = patente;
            printedResponse = response;
          },
          printSalida:
              ({
                required patente,
                required confirm,
                required previewFallback,
                required horaIngreso,
              }) async {},
          isPrinterAvailable: () => true,
          refresh: () async => refreshed = true,
        );

        final result = await actions.registrarIngresoDesdeBusqueda(
          ' ab 123 cd ',
        );

        expect(registeredPlate, 'AB123CD');
        expect(printedPlate, 'AB123CD');
        expect(printedResponse?['ingreso']['patente'], 'AB123CD');
        expect(refreshed, isTrue);
        expect(
          result.message,
          'Ingreso registrado. Comprobante durable enviado a PC / Print Agent. Copia local Sunmi impresa.',
        );
        expect(result.shouldClearPlate, isTrue);
      },
    );

    test('previews salida inline without confirming or refreshing', () async {
      var previewedId = 0;
      var confirmedId = 0;
      var refreshed = false;
      final actions = OperacionDiariaInlineActions(
        registrarIngreso: (_) async => <String, dynamic>{},
        previewSalida: (idIngreso) async {
          previewedId = idIngreso;
          return {'monto': 1200, 'minutos': 45, 'detalle': 'Estadía'};
        },
        confirmarSalida: (idIngreso) async {
          confirmedId = idIngreso;
          return {'ok': true};
        },
        iniciarLavado: (idIngreso, categoria) async {},
        finalizarLavado: (_) async {},
        refresh: () async => refreshed = true,
      );

      final preview = await actions.previsualizarSalidaDesdeBusqueda(
        OperacionDiariaRecord(
          idIngreso: 77,
          patente: 'ABC123',
          fechaHoraIngreso: DateTime.parse('2026-07-01T09:00:00'),
        ),
      );

      expect(previewedId, 77);
      expect(preview['monto'], 1200);
      expect(confirmedId, 0);
      expect(refreshed, isFalse);
    });

    test(
      'confirms salida inline only after preview is explicitly accepted',
      () async {
        var confirmedId = 0;
        var printedPlate = '';
        Map<String, dynamic>? printedConfirm;
        Map<String, dynamic>? printedPreview;
        String? printedHoraIngreso;
        var refreshed = false;
        final actions = OperacionDiariaInlineActions(
          registrarIngreso: (_) async => <String, dynamic>{},
          previewSalida: (_) async => throw StateError('preview already shown'),
          confirmarSalida: (idIngreso) async {
            confirmedId = idIngreso;
            return {'ok': true};
          },
          iniciarLavado: (idIngreso, categoria) async {},
          finalizarLavado: (_) async {},
          printIngreso: ({required patente, required response}) async {},
          printSalida:
              ({
                required patente,
                required confirm,
                required previewFallback,
                required horaIngreso,
              }) async {
                printedPlate = patente;
                printedConfirm = confirm;
                printedPreview = previewFallback;
                printedHoraIngreso = horaIngreso;
              },
          isPrinterAvailable: () => true,
          refresh: () async => refreshed = true,
        );

        final preview = {'monto': 1200};
        final result = await actions.confirmarSalidaDesdeBusqueda(
          OperacionDiariaRecord(
            idIngreso: 77,
            patente: 'ABC123',
            fechaHoraIngreso: DateTime.parse('2026-07-01T09:00:00'),
          ),
          preview,
        );

        expect(confirmedId, 77);
        expect(printedPlate, 'ABC123');
        expect(printedConfirm?['ok'], isTrue);
        expect(printedPreview?['monto'], 1200);
        expect(printedHoraIngreso, '2026-07-01 09:00:00.000');
        expect(refreshed, isTrue);
        expect(
          result.message,
          'Salida confirmada. Comprobante durable enviado a PC / Print Agent. Copia local Sunmi impresa.',
        );
        expect(result.shouldClearPlate, isTrue);
      },
    );

    test(
      'starts lavado inline only after a wash category is selected',
      () async {
        var startedId = 0;
        var startedCategory = '';
        var refreshed = false;
        final actions = OperacionDiariaInlineActions(
          registrarIngreso: (_) async => <String, dynamic>{},
          previewSalida: (_) async => <String, dynamic>{},
          confirmarSalida: (_) async => <String, dynamic>{},
          iniciarLavado: (idIngreso, categoria) async {
            startedId = idIngreso;
            startedCategory = categoria;
          },
          finalizarLavado: (_) async {},
          refresh: () async => refreshed = true,
        );

        final missingCategory = await actions.iniciarLavadoDesdeRegistro(
          OperacionDiariaRecord(
            idIngreso: 88,
            patente: 'WASH01',
            fechaHoraIngreso: DateTime.parse('2026-07-01T09:00:00'),
          ),
          null,
        );
        final started = await actions.iniciarLavadoDesdeRegistro(
          OperacionDiariaRecord(
            idIngreso: 88,
            patente: 'WASH01',
            fechaHoraIngreso: DateTime.parse('2026-07-01T09:00:00'),
          ),
          'premium',
        );

        expect(missingCategory.message, 'Seleccioná un tipo de lavado.');
        expect(startedId, 88);
        expect(startedCategory, 'premium');
        expect(refreshed, isTrue);
        expect(started.message, 'Lavado iniciado');
        expect(started.shouldClearPlate, isFalse);
      },
    );

    test(
      'finalizes active lavado inline only for records currently in lavado',
      () async {
        var finalizedId = 0;
        var refreshed = false;
        final actions = OperacionDiariaInlineActions(
          registrarIngreso: (_) async => <String, dynamic>{},
          previewSalida: (_) async => <String, dynamic>{},
          confirmarSalida: (_) async => <String, dynamic>{},
          iniciarLavado: (_, _) async {},
          finalizarLavado: (idIngreso) async => finalizedId = idIngreso,
          refresh: () async => refreshed = true,
        );

        final activeWash = OperacionDiariaRecord(
          idIngreso: 91,
          patente: 'WASH91',
          fechaHoraIngreso: DateTime.parse('2026-07-01T09:00:00'),
          enLavado: true,
        );
        final notInWash = OperacionDiariaRecord(
          idIngreso: 92,
          patente: 'WASH92',
          fechaHoraIngreso: DateTime.parse('2026-07-01T10:00:00'),
        );

        expect(canFinalizeActiveWash(activeWash), isTrue);
        expect(canFinalizeActiveWash(notInWash), isFalse);

        final result = await actions.finalizarLavadoDesdeRegistro(activeWash);

        expect(finalizedId, 91);
        expect(refreshed, isTrue);
        expect(result.message, 'Lavado finalizado');
        expect(result.shouldClearPlate, isFalse);
      },
    );

    test('reports Sunmi as a non-durable local copy when it fails', () async {
      final unavailablePrinter = OperacionDiariaInlineActions(
        registrarIngreso: (patente) async => {
          'ingreso': {'patente': patente},
        },
        previewSalida: (_) async => <String, dynamic>{},
        confirmarSalida: (_) async => <String, dynamic>{},
        iniciarLavado: (_, _) async {},
        finalizarLavado: (_) async {},
        printIngreso: ({required patente, required response}) async {
          throw Exception('should not print');
        },
        isPrinterAvailable: () => false,
        refresh: () async {},
      );
      final failingPrinter = OperacionDiariaInlineActions(
        registrarIngreso: (patente) async => {
          'ingreso': {'patente': patente},
        },
        previewSalida: (_) async => <String, dynamic>{},
        confirmarSalida: (_) async => <String, dynamic>{},
        iniciarLavado: (_, _) async {},
        finalizarLavado: (_) async {},
        printIngreso: ({required patente, required response}) async {
          throw Exception('printer offline');
        },
        isPrinterAvailable: () => true,
        refresh: () async {},
      );

      final unavailable = await unavailablePrinter
          .registrarIngresoDesdeBusqueda('abc123');
      final failed = await failingPrinter.registrarIngresoDesdeBusqueda(
        'abc123',
      );

      expect(
        unavailable.message,
        'Ingreso registrado. Comprobante durable enviado a PC / Print Agent.',
      );
      expect(
        failed.message,
        contains('No se pudo imprimir la copia local Sunmi'),
      );
      expect(failed.shouldClearPlate, isTrue);
    });
  });
}
