class TicketFormatter {
  static const _separator = '------------------------';
  static const _topMargin = [_separator, _separator];
  static const _bottomMargin = [_separator, _separator, _separator];

  static String _formatDateTime(dynamic value) {
    final text = (value ?? '').toString().trim();
    if (text.isEmpty) return '';

    final parsed = DateTime.tryParse(text);
    if (parsed == null) {
      return text.split('.').first;
    }

    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(parsed.day)}-${two(parsed.month)}-${parsed.year} '
        '${two(parsed.hour)}:${two(parsed.minute)}:${two(parsed.second)}';
  }

  static List<String> ingresoFromResponse({
    required String patente,
    required Map<String, dynamic> response,
  }) {
    final ingreso = response['ingreso'];
    final horaIngreso = _formatDateTime(
      ingreso is Map ? ingreso['hora_ingreso'] : response['hora_ingreso'],
    );

    return [
      ..._topMargin,
      'ESTACIONAMIENTO CENTRAL',
      _separator,
      'TICKET DE INGRESO',
      'PATENTE: $patente',
      if (horaIngreso.isNotEmpty) 'INGRESO: $horaIngreso',
      _separator,
      'Gracias por su visita.',
      ..._bottomMargin,
    ];
  }

  static List<String> salidaFromPreview({
    required String patente,
    required Map<String, dynamic> preview,
    String? horaIngreso,
  }) {
    return _salidaLines(
      patente: patente,
      horaIngreso: horaIngreso,
      horaSalida: null,
      minutos: preview['minutos'],
      monto: preview['monto'],
      detalle: preview['detalle'],
      montoEstacionamiento: preview['monto_estacionamiento'],
      totalLavados: preview['total_lavados'],
      nochesPrepagadas: preview['noches_prepagadas'],
    );
  }

  static List<String> _salidaLines({
    required String patente,
    required dynamic horaIngreso,
    required dynamic horaSalida,
    required dynamic minutos,
    required dynamic monto,
    required dynamic detalle,
    required dynamic montoEstacionamiento,
    required dynamic totalLavados,
    dynamic nochesPrepagadas,
  }) {
    final horaIngresoFmt = _formatDateTime(horaIngreso);
    final horaSalidaFmt = _formatDateTime(horaSalida);
    final detalleText = (detalle ?? '').toString().trim();
    final estacionamientoText = (montoEstacionamiento ?? '').toString().trim();
    final lavadosValue = int.tryParse((totalLavados ?? '0').toString()) ?? 0;

    return [
      ..._topMargin,
      'ESTACIONAMIENTO CENTRAL',
      _separator,
      'TICKET DE SALIDA',
      'PATENTE: $patente',
      if (horaIngresoFmt.isNotEmpty) 'INGRESO: $horaIngresoFmt',
      if (horaSalidaFmt.isNotEmpty) 'SALIDA: $horaSalidaFmt',
      'TIEMPO: ${minutos ?? ''} min',
      _separator,
      if (detalleText.isNotEmpty) 'DETALLE: $detalleText',
      if (estacionamientoText.isNotEmpty)
        'ESTACIONAMIENTO: \$$estacionamientoText',
      if (lavadosValue > 0) 'LAVADOS: \$$lavadosValue',
      for (final noche in nochesPrepagadas is List ? nochesPrepagadas : const [])
        if (noche is Map) ...[
          'NOCHES YA PAGADAS: \$${noche['monto_snapshot'] ?? ''}',
          'HORARIO NOCHES: ${noche['hora_inicio_snapshot'] ?? ''} A ${noche['hora_fin_snapshot'] ?? ''}',
        ],
      _separator,
      'A COBRAR AHORA: \$${monto ?? ''}',
      _separator,
      'Gracias por su visita.',
      ..._bottomMargin,
    ];
  }

  static List<String> salidaFromConfirmResponse({
    required String patente,
    required Map<String, dynamic> confirm,
    Map<String, dynamic>? previewFallback,
    String? horaIngreso,
  }) {
    final t = confirm['ticket_text'];

    if (t is List) {
      return t.map((e) => e.toString()).toList();
    }
    if (t is String && t.trim().isNotEmpty) {
      return t.split('\n');
    }

    if (confirm['fecha_hora_salida'] == null && previewFallback != null) {
      return salidaFromPreview(
        patente: patente,
        preview: previewFallback,
        horaIngreso: horaIngreso,
      );
    }

    return _salidaLines(
      patente: patente,
      horaIngreso: confirm['fecha_hora_ingreso'] ?? horaIngreso,
      horaSalida: confirm['fecha_hora_salida'],
      minutos: confirm['minutos'],
      monto: confirm['monto'],
      detalle: confirm['detalle'],
      montoEstacionamiento: confirm['monto_estacionamiento'],
      totalLavados: confirm['total_lavados'],
      nochesPrepagadas: confirm['noches_prepagadas'],
    );
  }
}
