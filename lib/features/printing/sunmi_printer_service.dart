import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:sunmi_printer_plus/sunmi_printer_plus.dart';

class SunmiPrinterService {
  bool get _isAndroid => !kIsWeb && Platform.isAndroid;

  bool _ready = false;
  bool get isReady => _ready;

  String? _lastError;
  String? get lastError => _lastError;

  Future<void> init() async {
    if (!_isAndroid) {
      _ready = false;
      _lastError = 'No es Android.';
      debugPrint('SUNMI init -> $_lastError');
      return;
    }

    try {
      debugPrint('SUNMI init -> bindingPrinter()');
      await SunmiPrinter.bindingPrinter();

      debugPrint('SUNMI init -> initPrinter()');
      await SunmiPrinter.initPrinter();

      _ready = true;
      _lastError = null;
      debugPrint('SUNMI init -> OK');
    } catch (e, st) {
      _ready = false;
      _lastError = e.toString();
      debugPrint('SUNMI init -> ERROR: $e');
      debugPrint('$st');
    }
  }

  Future<void> printLines(List<String> lines) async {
    if (!_isAndroid) {
      throw Exception('SunmiPrinterService: no es Android.');
    }

    if (!_ready) {
      await init();
    }

    if (!_ready) {
      throw Exception('No se pudo inicializar impresora Sunmi. ${_lastError ?? ""}');
    }

    try {
      debugPrint('SUNMI print -> encabezado');
      await SunmiPrinter.printText(
        'ESTACIONAMIENTO CENTRAL',
        style: SunmiTextStyle(
          bold: true,
          align: SunmiPrintAlign.CENTER,
        ),
      );

      await SunmiPrinter.lineWrap(1);

      debugPrint('SUNMI print -> líneas: ${lines.length}');
      for (final line in lines) {
        await SunmiPrinter.printText(
          line,
          style: SunmiTextStyle(
            align: SunmiPrintAlign.LEFT,
          ),
        );
      }

      await SunmiPrinter.lineWrap(2);

      try {
        await SunmiPrinter.cutPaper();
      } catch (e) {
        debugPrint('SUNMI cutPaper -> no soportado o falló: $e');
      }

      debugPrint('SUNMI print -> OK');
    } catch (e, st) {
      _lastError = e.toString();
      debugPrint('SUNMI print -> ERROR: $e');
      debugPrint('$st');
      rethrow;
    }
  }

  Future<void> printTest() async {
    await printLines([
      'PRUEBA SUNMI',
      'Si ves este ticket, la impresora funciona.',
      '------------------------',
      'OK',
    ]);
  }
}