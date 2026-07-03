class CotizacionTime {
  const CotizacionTime._();

  static int calcularMinutosPorHorarios(String ingreso, String salida) {
    final ingresoMinutos = parseHora(ingreso, 'ingreso');
    final salidaMinutos = parseHora(salida, 'salida');
    final minutos = salidaMinutos - ingresoMinutos;
    if (minutos == 0) {
      throw const FormatException(
        'La hora de salida debe ser distinta a la hora de ingreso.',
      );
    }
    if (minutos < 0) {
      throw const FormatException(
        'La hora de salida debe ser posterior a la hora de ingreso.',
      );
    }
    return minutos;
  }

  static int parseHora(String value, String campo) {
    final normalized = value.trim();
    final match = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(normalized) ??
        RegExp(r'^(\d{1,2})(\d{2})$').firstMatch(normalized);
    if (match == null) {
      throw FormatException(
        'Ingresá la hora de $campo con formato HH:MM o HHMM.',
      );
    }

    final horas = int.parse(match.group(1)!);
    final minutos = int.parse(match.group(2)!);
    if (horas < 0 || horas > 23 || minutos < 0 || minutos > 59) {
      throw FormatException('Ingresá una hora de $campo válida.');
    }
    return horas * 60 + minutos;
  }
}
