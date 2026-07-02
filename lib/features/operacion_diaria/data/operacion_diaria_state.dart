enum OperacionDiariaAction {
  ingreso,
  salida,
  salidaBloqueadaPorLavado,
  sinBusqueda,
}

typedef RegistrarIngresoFn =
    Future<Map<String, dynamic>> Function(String patente);
typedef PreviewSalidaFn = Future<Map<String, dynamic>> Function(int idIngreso);
typedef ConfirmarSalidaFn =
    Future<Map<String, dynamic>> Function(int idIngreso);
typedef IniciarLavadoFn =
    Future<void> Function(int idIngreso, String categoriaLavado);
typedef FinalizarLavadoFn = Future<void> Function(int idIngreso);
typedef PrintIngresoFn =
    Future<void> Function({
      required String patente,
      required Map<String, dynamic> response,
    });
typedef PrintSalidaFn =
    Future<void> Function({
      required String patente,
      required Map<String, dynamic> confirm,
      required Map<String, dynamic>? previewFallback,
      required String? horaIngreso,
    });

class OperacionDiariaInlineResult {
  final String message;
  final bool shouldClearPlate;

  const OperacionDiariaInlineResult({
    required this.message,
    required this.shouldClearPlate,
  });
}

class OperacionDiariaInlineActions {
  final RegistrarIngresoFn registrarIngreso;
  final PreviewSalidaFn previewSalida;
  final ConfirmarSalidaFn confirmarSalida;
  final IniciarLavadoFn iniciarLavado;
  final FinalizarLavadoFn finalizarLavado;
  final PrintIngresoFn? printIngreso;
  final PrintSalidaFn? printSalida;
  final bool Function()? isPrinterAvailable;
  final Future<void> Function() refresh;

  const OperacionDiariaInlineActions({
    required this.registrarIngreso,
    required this.previewSalida,
    required this.confirmarSalida,
    required this.iniciarLavado,
    required this.finalizarLavado,
    this.printIngreso,
    this.printSalida,
    this.isPrinterAvailable,
    required this.refresh,
  });

  Future<OperacionDiariaInlineResult> registrarIngresoDesdeBusqueda(
    String plateInput,
  ) async {
    final patente = normalizePlateInput(plateInput);
    if (patente.isEmpty) {
      return const OperacionDiariaInlineResult(
        message: 'Ingresá una patente para registrar ingreso.',
        shouldClearPlate: false,
      );
    }

    final response = await registrarIngreso(patente);
    var message = 'Ingreso registrado';
    if (isPrinterAvailable?.call() == true && printIngreso != null) {
      try {
        await printIngreso!(patente: patente, response: response);
      } catch (e) {
        message = 'Ingreso OK, pero Sunmi falló: $e';
      }
    }
    await refresh();
    return OperacionDiariaInlineResult(
      message: message,
      shouldClearPlate: true,
    );
  }

  Future<OperacionDiariaInlineResult> registrarSalidaDesdeBusqueda(
    OperacionDiariaRecord record,
  ) async {
    final preview = await previewSalida(record.idIngreso);
    final confirm = await confirmarSalida(record.idIngreso);
    var message = 'Salida confirmada';
    if (isPrinterAvailable?.call() == true && printSalida != null) {
      try {
        await printSalida!(
          patente: record.patente,
          confirm: confirm,
          previewFallback: preview,
          horaIngreso: record.fechaHoraIngreso.toString(),
        );
      } catch (e) {
        message = 'Salida OK, pero Sunmi falló: $e';
      }
    }
    await refresh();
    return OperacionDiariaInlineResult(
      message: message,
      shouldClearPlate: true,
    );
  }

  Future<OperacionDiariaInlineResult> iniciarLavadoDesdeRegistro(
    OperacionDiariaRecord record,
    String? categoriaLavado,
  ) async {
    if (categoriaLavado == null || categoriaLavado.trim().isEmpty) {
      return const OperacionDiariaInlineResult(
        message: 'Seleccioná un tipo de lavado.',
        shouldClearPlate: false,
      );
    }

    await iniciarLavado(record.idIngreso, categoriaLavado);
    await refresh();
    return const OperacionDiariaInlineResult(
      message: 'Lavado iniciado',
      shouldClearPlate: false,
    );
  }

  Future<OperacionDiariaInlineResult> finalizarLavadoDesdeRegistro(
    OperacionDiariaRecord record,
  ) async {
    if (!canFinalizeActiveWash(record)) {
      return const OperacionDiariaInlineResult(
        message: 'El registro no tiene lavado activo.',
        shouldClearPlate: false,
      );
    }

    await finalizarLavado(record.idIngreso);
    await refresh();
    return const OperacionDiariaInlineResult(
      message: 'Lavado finalizado',
      shouldClearPlate: false,
    );
  }
}

bool canFinalizeActiveWash(OperacionDiariaRecord record) => record.enLavado;

class OperacionDiariaRecord {
  final int idIngreso;
  final String patente;
  final DateTime fechaHoraIngreso;
  final bool enLavado;

  const OperacionDiariaRecord({
    required this.idIngreso,
    required this.patente,
    required this.fechaHoraIngreso,
    this.enLavado = false,
  });

  factory OperacionDiariaRecord.fromMap(Map<dynamic, dynamic> item) {
    final id = item['id_ingreso'] ?? item['idIngreso'] ?? item['id'];
    final rawDate =
        item['fecha_hora_ingreso'] ??
        item['hora_ingreso'] ??
        item['horaIngreso'] ??
        item['ingreso_at'];
    final lavado = item['en_lavado'];

    return OperacionDiariaRecord(
      idIngreso: id is int ? id : int.tryParse('$id') ?? 0,
      patente:
          '${item['patente'] ?? item['placa'] ?? item['license_plate'] ?? ''}',
      fechaHoraIngreso:
          DateTime.tryParse('$rawDate') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      enLavado: lavado == true || lavado == 1 || lavado == '1',
    );
  }
}

class PlateSearchDecision {
  final String normalizedPlate;
  final OperacionDiariaAction primaryAction;
  final OperacionDiariaRecord? activeRecord;
  final String message;

  const PlateSearchDecision({
    required this.normalizedPlate,
    required this.primaryAction,
    required this.message,
    this.activeRecord,
  });
}

String normalizePlateInput(String input) =>
    input.trim().toUpperCase().replaceAll(' ', '');

List<OperacionDiariaRecord> recordsFromActivos(List<dynamic> items) {
  return orderOperationRecordsNewestFirst(
    items
        .whereType<Map<dynamic, dynamic>>()
        .map(OperacionDiariaRecord.fromMap)
        .where(
          (record) => record.idIngreso > 0 && record.patente.trim().isNotEmpty,
        )
        .toList(),
  );
}

List<OperacionDiariaRecord> orderOperationRecordsNewestFirst(
  List<OperacionDiariaRecord> records,
) {
  final ordered = List<OperacionDiariaRecord>.from(records);
  ordered.sort((a, b) => b.fechaHoraIngreso.compareTo(a.fechaHoraIngreso));
  return ordered;
}

List<OperacionDiariaRecord> filterOperationRecordsByPlate(
  List<OperacionDiariaRecord> records,
  String query,
) {
  final normalizedQuery = normalizePlateInput(query);
  if (normalizedQuery.isEmpty) return List<OperacionDiariaRecord>.from(records);

  return records
      .where(
        (record) =>
            normalizePlateInput(record.patente).contains(normalizedQuery),
      )
      .toList();
}

PlateSearchDecision decidePlateSearchAction({
  required String plateInput,
  required List<OperacionDiariaRecord> records,
}) {
  final normalizedPlate = normalizePlateInput(plateInput);
  if (normalizedPlate.isEmpty) {
    return const PlateSearchDecision(
      normalizedPlate: '',
      primaryAction: OperacionDiariaAction.sinBusqueda,
      message: 'Ingresá una patente para buscar.',
    );
  }

  final activeRecord = records.cast<OperacionDiariaRecord?>().firstWhere(
    (record) => normalizePlateInput(record?.patente ?? '') == normalizedPlate,
    orElse: () => null,
  );

  if (activeRecord == null) {
    return PlateSearchDecision(
      normalizedPlate: normalizedPlate,
      primaryAction: OperacionDiariaAction.ingreso,
      message: '$normalizedPlate sin ingreso activo. Podés registrar ingreso.',
    );
  }

  if (activeRecord.enLavado) {
    return PlateSearchDecision(
      normalizedPlate: normalizedPlate,
      primaryAction: OperacionDiariaAction.salidaBloqueadaPorLavado,
      activeRecord: activeRecord,
      message: 'Finalizá el lavado antes de registrar la salida.',
    );
  }

  return PlateSearchDecision(
    normalizedPlate: normalizedPlate,
    primaryAction: OperacionDiariaAction.salida,
    activeRecord: activeRecord,
    message: '$normalizedPlate tiene ingreso activo. Podés registrar salida.',
  );
}
