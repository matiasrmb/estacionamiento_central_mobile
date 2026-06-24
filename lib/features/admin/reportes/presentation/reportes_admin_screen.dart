import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/app_services.dart';
import '../data/reportes_api.dart';

class ReportesAdminScreen extends StatefulWidget {
  const ReportesAdminScreen({super.key});

  @override
  State<ReportesAdminScreen> createState() => _ReportesAdminScreenState();
}

class _ReportesAdminScreenState extends State<ReportesAdminScreen> {
  late final ReportesApi _api;
  final _patenteCtrl = TextEditingController();

  bool _loading = false;
  String? _error;
  DateTime _desde = DateTime.now();
  DateTime _hasta = DateTime.now();
  Map<String, dynamic>? _reporte;
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _api = ReportesApi(AppServices.I.client);
    _buscar();
  }

  @override
  void dispose() {
    _patenteCtrl.dispose();
    super.dispose();
  }

  Future<void> _buscar() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final reporte = await _api.movimientos(
        fechaInicio: _desde,
        fechaFin: _hasta,
        patente: _patenteCtrl.text,
      );
      final rawItems = reporte['items'];
      if (!mounted) return;
      setState(() {
        _reporte = reporte;
        _items = rawItems is List
            ? List<Map<String, dynamic>>.from(
                rawItems.map((item) => Map<String, dynamic>.from(item as Map)),
              )
            : [];
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'No se pudo cargar el reporte: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickDesde() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _desde,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (selected == null) return;
    setState(() {
      _desde = selected;
      if (_hasta.isBefore(_desde)) _hasta = selected;
    });
  }

  Future<void> _pickHasta() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _hasta,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (selected == null) return;
    setState(() => _hasta = selected);
  }

  void _limpiar() {
    _patenteCtrl.clear();
    setState(() {
      _desde = DateTime.now();
      _hasta = DateTime.now();
    });
    _buscar();
  }

  @override
  Widget build(BuildContext context) {
    final reporte = _reporte;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportes'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
        actions: [
          IconButton(onPressed: _buscar, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Filtros', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _pickDesde,
                          icon: const Icon(Icons.calendar_today),
                          label: Text('Desde ${_date(_desde)}'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _pickHasta,
                          icon: const Icon(Icons.calendar_today),
                          label: Text('Hasta ${_date(_hasta)}'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _patenteCtrl,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      labelText: 'Patente opcional',
                    ),
                    onSubmitted: (_) => _buscar(),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _loading ? null : _limpiar,
                          child: const Text('Limpiar'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _loading ? null : _buscar,
                          icon: _loading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.search),
                          label: const Text('Buscar'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_error != null) ...[
            Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 12),
          ],
          if (reporte != null) ...[
            Row(
              children: [
                Expanded(
                  child: _SummaryCard(
                    title: 'Movimientos',
                    value: '${reporte['total_movimientos'] ?? 0}',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _SummaryCard(
                    title: 'Total',
                    value: _money(reporte['total_recaudado']),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          Text('Movimientos', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (_items.isEmpty && !_loading)
            const Text('No hay movimientos para esos filtros.'),
          for (final item in _items)
            Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: Icon(
                  item['tipo'] == 'bano' ? Icons.wc : Icons.directions_car,
                ),
                title: Text(
                  '${item['patente'] ?? ''} • ${_money(item['tarifa_aplicada'])}',
                ),
                subtitle: Text(
                  '${_text(item['fecha_hora_ingreso'])} → ${_text(item['fecha_hora_salida'])}\n'
                  'Minutos: ${item['minutos'] ?? 0}',
                ),
                isThreeLine: true,
              ),
            ),
        ],
      ),
    );
  }

  String _date(DateTime value) {
    final year = value.year.toString().padLeft(4, '0');
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  String _money(dynamic value) {
    final n = value is num ? value.toInt() : int.tryParse('${value ?? 0}') ?? 0;
    return '\$${n.toString()}';
  }

  String _text(dynamic value) => value == null ? '-' : '$value';
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;

  const _SummaryCard({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 4),
            Text(value, style: Theme.of(context).textTheme.titleLarge),
          ],
        ),
      ),
    );
  }
}
