import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/app_services.dart';
import '../../../ui/theme.dart';
import '../../ingreso/data/ingreso_api.dart';
import '../../ingreso/data/ingreso_repository.dart';
import '../../operaciones/data/operaciones_api.dart';
import '../../printing/sunmi_printer_service.dart';
import '../../printing/ticket_formatter.dart';
import '../../salida/data/activos_api.dart';
import '../../salida/data/salida_api.dart';
import '../../salida/data/salida_repository.dart';
import '../data/operacion_diaria_state.dart';
import '../domain/cotizacion_time.dart';

class OperacionDiariaScreen extends StatefulWidget {
  const OperacionDiariaScreen({super.key});

  @override
  State<OperacionDiariaScreen> createState() => _OperacionDiariaScreenState();
}

class _OperacionDiariaScreenState extends State<OperacionDiariaScreen> {
  final _searchCtrl = TextEditingController();
  late final ActivosApi _activosApi;
  late final OperacionesApi _operacionesApi;
  late final IngresoRepository _ingresoRepository;
  late final SalidaRepository _salidaRepository;
  late final OperacionDiariaInlineActions _inlineActions;
  final SunmiPrinterService _sunmi = SunmiPrinterService();

  bool _loading = true;
  bool _actionLoading = false;
  bool _sunmiAvailable = false;
  String? _error;
  List<OperacionDiariaRecord> _records = [];
  List<Map<String, dynamic>> _categoriasLavado = [];
  PlateSearchDecision _decision = const PlateSearchDecision(
    normalizedPlate: '',
    primaryAction: OperacionDiariaAction.sinBusqueda,
    message: 'Ingresá una patente para buscar.',
  );

  @override
  void initState() {
    super.initState();
    final client = AppServices.I.client;
    _activosApi = ActivosApi(client);
    _operacionesApi = OperacionesApi(client);
    _ingresoRepository = IngresoRepository(api: IngresoApi(client));
    _salidaRepository = SalidaRepository(
      activosApi: _activosApi,
      salidaApi: SalidaApi(client),
    );
    _inlineActions = OperacionDiariaInlineActions(
      registrarIngreso: _ingresoRepository.registrar,
      previewSalida: _salidaRepository.preview,
      confirmarSalida: (idIngreso) => _salidaRepository.confirmar(idIngreso),
      iniciarLavado: (idIngreso, categoriaLavado) =>
          _operacionesApi.iniciarLavado(
            idIngreso: idIngreso,
            categoriaLavado: categoriaLavado,
          ),
      finalizarLavado: (idIngreso) =>
          _operacionesApi.finalizarLavado(idIngreso: idIngreso),
      printIngreso: ({required patente, required response}) async {
        final lines = TicketFormatter.ingresoFromResponse(
          patente: patente,
          response: response,
        );
        await _sunmi.printLines(lines);
      },
      printSalida:
          ({
            required patente,
            required confirm,
            required previewFallback,
            required horaIngreso,
          }) async {
            final lines = TicketFormatter.salidaFromConfirmResponse(
              patente: patente,
              confirm: confirm,
              previewFallback: previewFallback,
              horaIngreso: horaIngreso,
            );
            await _sunmi.printLines(lines);
          },
      isPrinterAvailable: () => _sunmiAvailable,
      refresh: _load,
    );
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await _sunmi.init();
    if (mounted) {
      setState(() => _sunmiAvailable = _sunmi.isReady);
    }
    await _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final activos = await _activosApi.listarActivos();
      final categorias = await _operacionesApi.listarCategoriasLavado();
      if (!mounted) return;
      setState(() {
        _records = recordsFromActivos(activos);
        _categoriasLavado = categorias;
        _refreshDecision();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'No se pudo cargar operación diaria: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _refreshDecision() {
    _decision = decidePlateSearchAction(
      plateInput: _searchCtrl.text,
      records: _records,
    );
  }

  Future<void> _registrarBano() async {
    try {
      await _operacionesApi.registrarBano();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Baño registrado')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('No se pudo registrar baño: $e')));
    }
  }

  Future<void> _runInlineAction(
    Future<OperacionDiariaInlineResult> Function() action,
  ) async {
    if (_actionLoading) return;
    setState(() {
      _actionLoading = true;
      _error = null;
    });

    try {
      final result = await action();
      if (!mounted) return;
      if (result.shouldClearPlate) {
        _searchCtrl.clear();
        setState(_refreshDecision);
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.message)));
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'No se pudo completar la acción: $e');
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  Future<void> _registrarIngresoInline() async {
    await _runInlineAction(
      () => _inlineActions.registrarIngresoDesdeBusqueda(_searchCtrl.text),
    );
  }

  Future<void> _registrarSalidaInline(OperacionDiariaRecord record) async {
    if (_actionLoading) return;
    setState(() {
      _actionLoading = true;
      _error = null;
    });

    Map<String, dynamic> preview;
    try {
      preview = await _inlineActions.previsualizarSalidaDesdeBusqueda(record);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'No se pudo completar la acción: $e');
      return;
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }

    if (!mounted) return;
    final confirmed = await _confirmarPreviewSalida(record, preview);
    if (!mounted || confirmed != true) return;

    await _runInlineAction(
      () => _inlineActions.confirmarSalidaDesdeBusqueda(record, preview),
    );
  }

  Future<bool?> _confirmarPreviewSalida(
    OperacionDiariaRecord record,
    Map<String, dynamic> preview,
  ) {
    final detalle = (preview['detalle'] ?? '').toString().trim();
    final minutos = preview['minutos'];
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar salida'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SalidaPreviewLine(label: 'Patente', value: record.patente),
            _SalidaPreviewLine(label: 'Monto', value: _money(preview['monto'])),
            if (minutos != null)
              _SalidaPreviewLine(label: 'Minutos', value: '$minutos min'),
            if (detalle.isNotEmpty)
              _SalidaPreviewLine(label: 'Detalle', value: detalle),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirmar salida'),
          ),
        ],
      ),
    );
  }

  Future<String?> _seleccionarCategoriaLavado() async {
    if (_categoriasLavado.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay tipos de lavado disponibles.')),
      );
      return null;
    }

    return showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Seleccionar lavado'),
        children: [
          for (final categoria in _categoriasLavado)
            SimpleDialogOption(
              onPressed: () =>
                  Navigator.of(context).pop('${categoria['clave']}'),
              child: Text('${categoria['label']} - ${categoria['valor']}'),
            ),
        ],
      ),
    );
  }

  Future<void> _iniciarLavadoInline(OperacionDiariaRecord record) async {
    final categoria = await _seleccionarCategoriaLavado();
    if (!mounted) return;
    await _runInlineAction(
      () => _inlineActions.iniciarLavadoDesdeRegistro(record, categoria),
    );
  }

  Future<void> _finalizarLavadoInline(OperacionDiariaRecord record) async {
    await _runInlineAction(
      () => _inlineActions.finalizarLavadoDesdeRegistro(record),
    );
  }

  String _money(dynamic value) {
    final amount = value is num ? value : num.tryParse('$value') ?? 0;
    return '\$${amount.round()}';
  }

  Future<void> _mostrarCotizaciones() async {
    final tipo = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Cotizaciones'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.of(context).pop('estadia'),
            child: const Text('Estadía'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.of(context).pop('lavado'),
            child: const Text('Lavado'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.of(context).pop('mensualidad'),
            child: const Text('Mensualidad'),
          ),
        ],
      ),
    );
    if (tipo == null) return;
    if (tipo == 'estadia') {
      await _cotizarEstadia();
    } else if (tipo == 'lavado') {
      await _cotizarLavado();
    } else {
      await _cotizarMensualidadManual();
    }
  }

  Future<void> _cotizarEstadia() async {
    var horaIngreso = '';
    var horaSalida = '';
    final minutos = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cotizar estadía'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              initialValue: horaIngreso,
              onChanged: (value) => horaIngreso = value,
              keyboardType: TextInputType.datetime,
              decoration: const InputDecoration(
                labelText: 'Hora de ingreso',
                hintText: '13:00 o 1300',
                helperText: 'Podés escribir HH:MM o HHMM.',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: horaSalida,
              onChanged: (value) => horaSalida = value,
              keyboardType: TextInputType.datetime,
              decoration: const InputDecoration(
                labelText: 'Hora de salida',
                hintText: '19:00 o 1900',
                helperText: 'Podés escribir HH:MM o HHMM.',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              try {
                Navigator.of(context).pop(
                  _calcularMinutosPorHorarios(horaIngreso, horaSalida),
                );
              } on FormatException catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(e.message)),
                );
              }
            },
            child: const Text('Cotizar'),
          ),
        ],
      ),
    );
    if (minutos == null) return;
    await _mostrarPreviewCotizacion({
      'estadia': {'minutos': minutos},
    });
  }

  int _calcularMinutosPorHorarios(String ingreso, String salida) {
    return CotizacionTime.calcularMinutosPorHorarios(ingreso, salida);
  }

  Future<void> _cotizarLavado() async {
    try {
      final opciones = await _operacionesApi.listarOpcionesCotizacion();
      final lavados = List<Map<String, dynamic>>.from(
        (opciones['lavados'] as List? ?? const []).map(
          (item) => Map<String, dynamic>.from(item as Map),
        ),
      ).where((item) => int.tryParse('${item['activo'] ?? 1}') != 0).toList();
      if (!mounted) return;
      if (lavados.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${(opciones['messages'] as Map?)?['lavados'] ?? 'No hay precios de lavado configurados para cotizar.'}',
            ),
          ),
        );
        return;
      }
      final elegido = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) => SimpleDialog(
          title: const Text('Cotizar lavado'),
          children: [
            for (final item in lavados)
              SimpleDialogOption(
                onPressed: () => Navigator.of(context).pop(item),
                child: Text('${item['nombre']} - ${_money(item['valor_lavado'])}'),
              ),
          ],
        ),
      );
      if (elegido == null) return;
      await _mostrarPreviewCotizacion({
        'lavado': {
          'tipo_lavado': '${elegido['nombre']}',
          'monto_lavado': int.tryParse('${elegido['valor_lavado']}') ?? 0,
        },
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo cotizar lavado: $e')),
      );
    }
  }

  Future<void> _cotizarMensualidadManual() async {
    var montoText = '';
    final monto = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cotizar mensualidad'),
        content: TextFormField(
          initialValue: montoText,
          onChanged: (value) => montoText = value,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Monto mensual negociado'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(
              context,
            ).pop(int.tryParse(montoText.trim()) ?? 0),
            child: const Text('Cotizar'),
          ),
        ],
      ),
    );
    if (monto == null) return;
    if (monto <= 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresá un monto mensual mayor a cero.')),
      );
      return;
    }
    if (!mounted) return;
    final diario = (monto / 30).round();
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cotización'),
        content: Text(
          'Mensualidad: ${_money(monto)}\nEquivalente diario (30 días): ${_money(diario)}\nTotal estimado: ${_money(monto)}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Future<void> _mostrarPreviewCotizacion(Map<String, dynamic> payload) async {
    try {
      final preview = await _operacionesApi.previewCotizacion(payload);
      if (!mounted) return;
      final lines = <String>['Total estimado: ${_money(preview['total'])}'];
      final items = preview['items'];
      if (items is List) {
        for (final item in items.whereType<Map>()) {
          if (item['tipo'] == 'lavado') {
            lines.add('Lavado ${item['tipo_lavado']}: ${_money(item['monto'])}');
          } else if (item['tipo'] == 'estadia') {
            lines.add('Estadía ${item['minutos']} min: ${_money(item['monto'])}');
          }
        }
      }
      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Cotización'),
          content: Text(lines.join('\n')),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo cotizar: $e')),
      );
    }
  }

  void _openActions(OperacionDiariaRecord record) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                record.patente,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text('Ingreso: ${record.fechaHoraIngreso}'),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: record.enLavado
                    ? null
                    : () {
                        Navigator.of(context).pop();
                        _registrarSalidaInline(record);
                      },
                icon: const Icon(Icons.logout),
                label: Text(
                  record.enLavado
                      ? 'Salida bloqueada por lavado'
                      : 'Registrar salida',
                ),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  if (canFinalizeActiveWash(record)) {
                    _finalizarLavadoInline(record);
                  } else {
                    _iniciarLavadoInline(record);
                  }
                },
                icon: const Icon(Icons.local_car_wash),
                label: Text(
                  record.enLavado ? 'Finalizar lavado' : 'Iniciar lavado',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = filterOperationRecordsByPlate(_records, _searchCtrl.text);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Operación diaria'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _registrarBano,
        icon: const Icon(Icons.wc),
        label: const Text('Baño'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Buscar patente',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _searchCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Patente',
                      prefixIcon: Icon(Icons.search),
                    ),
                    textInputAction: TextInputAction.search,
                    onChanged: (_) => setState(_refreshDecision),
                    onSubmitted: (_) => setState(_refreshDecision),
                  ),
                  const SizedBox(height: 10),
                  Text(_decision.message),
                  const SizedBox(height: 10),
                  if (_decision.primaryAction == OperacionDiariaAction.ingreso)
                    ElevatedButton.icon(
                      onPressed: _actionLoading
                          ? null
                          : _registrarIngresoInline,
                      icon: const Icon(Icons.login),
                      label: _actionLoading
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Registrar ingreso'),
                    )
                  else if (_decision.primaryAction ==
                      OperacionDiariaAction.salida)
                    ElevatedButton.icon(
                      onPressed:
                          _actionLoading || _decision.activeRecord == null
                          ? null
                          : () =>
                                _registrarSalidaInline(_decision.activeRecord!),
                      icon: const Icon(Icons.logout),
                      label: _actionLoading
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Registrar salida'),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _mostrarCotizaciones,
            icon: const Icon(Icons.request_quote),
            label: const Text('Cotizaciones'),
          ),
          const SizedBox(height: 12),
          if (_error != null) _MessageBox(text: _error!, isError: true),
          if (_loading) const Center(child: CircularProgressIndicator()),
          if (!_loading) ...[
            Text(
              'Activos recientes',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            for (final record in filtered)
              Card(
                child: ListTile(
                  leading: Icon(
                    record.enLavado
                        ? Icons.local_car_wash
                        : Icons.directions_car,
                    color: record.enLavado
                        ? const Color(0xFF92400E)
                        : AppColors.primary,
                  ),
                  title: Text(record.patente),
                  subtitle: Text(operationRecordSubtitle(record)),
                  trailing: const Icon(Icons.more_horiz),
                  onTap: () => _openActions(record),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _MessageBox extends StatelessWidget {
  final String text;
  final bool isError;

  const _MessageBox({required this.text, this.isError = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isError ? const Color(0xFFFEF2F2) : AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isError ? const Color(0xFFFCA5A5) : AppColors.border,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(color: isError ? AppColors.danger : AppColors.text),
      ),
    );
  }
}

class _SalidaPreviewLine extends StatelessWidget {
  final String label;
  final String value;

  const _SalidaPreviewLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text('$label: $value'),
    );
  }
}
