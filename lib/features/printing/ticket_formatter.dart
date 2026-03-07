class TicketFormatter {
  static List<String> ingresoFromResponse({
    required String patente,
    required Map<String, dynamic> response,
  }) {
    final horaIngreso = (response['hora_ingreso'] ?? '').toString();

    return [
      'TIPO: INGRESO',
      'PATENTE: $patente',
      'HORA INGRESO: $horaIngreso',
      '------------------------',
      'Bienvenido.',
    ];
  }

  static List<String> salidaFromPreview({
    required String patente,
    required Map<String, dynamic> preview,
  }) {
    final minutos = (preview['minutos'] ?? '').toString();
    final monto = (preview['monto'] ?? '').toString();
    final detalle = (preview['detalle'] ?? '').toString();

    return [
      'TIPO: SALIDA',
      'PATENTE: $patente',
      'MINUTOS: $minutos',
      'MONTO: $monto',
      if (detalle.isNotEmpty) 'DETALLE: $detalle',
      '------------------------',
      'Gracias.',
    ];
  }

  static List<String> salidaFromConfirmResponse({
    required String patente,
    required Map<String, dynamic> confirm,
    Map<String, dynamic>? previewFallback,
  }) {
    final t = confirm['ticket_text'];

    if (t is List) {
      return t.map((e) => e.toString()).toList();
    }
    if (t is String && t.trim().isNotEmpty) {
      return t.split('\n');
    }

    if (previewFallback != null) {
      return salidaFromPreview(patente: patente, preview: previewFallback);
    }

    return [
      'TIPO: SALIDA',
      'PATENTE: $patente',
      '------------------------',
      'Salida confirmada.',
    ];
  }
}