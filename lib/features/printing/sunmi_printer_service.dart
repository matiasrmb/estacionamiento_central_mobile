import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:sunmi_printer_plus/sunmi_printer_plus.dart';

class SunmiPrinterService {
  bool get _isAndroid => !kIsWeb && Platform.isAndroid;

  bool _ready = false;
  bool get isReady => _ready;

  String? _lastError;
  String? get lastError => _lastError;

  bool _isMissingSunmiPrinter(Object error) {
    final message = error.toString().toLowerCase();
    return message.contains('sunmiprinter') ||
        message.contains('sunmi printer') ||
        message.contains('lateinit property sunmiprinter') ||
        message.contains('not been initialized');
  }

  Future<void> init() async {
    if (!_isAndroid) {
      _ready = false;
      _lastError =
          'La impresión Sunmi solo está disponible en equipos Android Sunmi.';
      debugPrint('SUNMI init -> $_lastError');
      return;
    }

    try {
      debugPrint('SUNMI init -> getStatus()');
      await SunmiConfig.getStatus();

      _ready = true;
      _lastError = null;
      debugPrint('SUNMI init -> OK');
    } on PlatformException catch (e, st) {
      _ready = false;
      _lastError = _isMissingSunmiPrinter(e)
          ? 'Este dispositivo no tiene impresora Sunmi integrada.'
          : e.message ?? e.toString();
      debugPrint('SUNMI init -> ERROR: $_lastError');
      debugPrint('$st');
    } catch (e, st) {
      _ready = false;
      _lastError = e.toString();
      debugPrint('SUNMI init -> ERROR: $e');
      debugPrint('$st');
    }
  }

  Future<void> printLines(List<String> lines) async {
    if (!_isAndroid) {
      throw Exception(
        'La impresión Sunmi solo está disponible en equipos Android Sunmi.',
      );
    }

    if (!_ready) {
      await init();
    }

    if (!_ready) {
      throw Exception(
        'No se pudo inicializar impresora Sunmi. ${_lastError ?? ""}',
      );
    }

    try {
      debugPrint('SUNMI print -> líneas: ${lines.length}');
      for (final line in lines) {
        if (line.trim().isEmpty) {
          await SunmiPrinter.lineWrap(1);
          continue;
        }

        final isCentered =
            line == 'ESTACIONAMIENTO CENTRAL' ||
            line.startsWith('TICKET') ||
            line.startsWith('TOTAL') ||
            line.startsWith('Gracias');
        final isBold = isCentered || line.startsWith('PATENTE');
        await SunmiPrinter.printText(
          line,
          style: SunmiTextStyle(
            fontSize: isCentered ? 30 : 28,
            bold: isBold,
            align: isCentered ? SunmiPrintAlign.CENTER : SunmiPrintAlign.LEFT,
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
      _ready = !_isMissingSunmiPrinter(e);
      _lastError = _isMissingSunmiPrinter(e)
          ? 'Este dispositivo no tiene impresora Sunmi integrada.'
          : e.toString();
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
