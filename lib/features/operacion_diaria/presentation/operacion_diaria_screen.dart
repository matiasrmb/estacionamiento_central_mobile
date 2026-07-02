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
    await _runInlineAction(
      () => _inlineActions.registrarSalidaDesdeBusqueda(record),
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
              OutlinedButton.icon(
                onPressed: null,
                icon: const Icon(Icons.calendar_month),
                label: const Text('Mensualidad (próximo paso)'),
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
                  subtitle: Text(
                    record.enLavado ? 'En lavado' : 'Disponible para salida',
                  ),
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
