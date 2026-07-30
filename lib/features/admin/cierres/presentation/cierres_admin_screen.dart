import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/app_services.dart';
import '../data/cierres_api.dart';

class CierresAdminScreen extends StatefulWidget {
  const CierresAdminScreen({super.key});

  @override
  State<CierresAdminScreen> createState() => _CierresAdminScreenState();
}

class _CierresAdminScreenState extends State<CierresAdminScreen> {
  late final CierresApi _api;
  bool _loading = true;
  bool _closing = false;
  String? _error;
  Map<String, dynamic>? _pendiente;
  List<Map<String, dynamic>> _historial = [];

  @override
  void initState() {
    super.initState();
    _api = CierresApi(AppServices.I.client);
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final pendiente = await _api.pendiente();
      final historial = await _api.listar();
      if (!mounted) return;
      setState(() {
        _pendiente = pendiente;
        _historial = historial;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'No se pudieron cargar cierres: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _crearCierre() async {
    final pendiente = _pendiente;
    if (pendiente == null || pendiente['hay_pendiente'] != true) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar cierre'),
        content: const Text(
          'Esto marcará como cerradas todas las salidas pendientes hasta ahora. ¿Continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Realizar cierre'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() {
      _closing = true;
      _error = null;
    });
    try {
      final cierre = await _api.crear();
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Cierre realizado. Total: ${_money(cierre['total_general'])}',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'No se pudo realizar el cierre: $e');
    } finally {
      if (mounted) setState(() => _closing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pendiente = _pendiente;
    final hasPending = pendiente?['hay_pendiente'] == true;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cierres'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_error != null) ...[
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 12),
                ],
                Text(
                  'Cierre pendiente',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: pendiente == null || !hasPending
                        ? const Text('No hay salidas pendientes para cerrar.')
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _kv('Desde', _text(pendiente['fecha_inicio'])),
                              _kv('Hasta', _text(pendiente['fecha_cierre'])),
                              _kv('Salidas', _text(pendiente['total_salidas'])),
                              _kv(
                                'Vehículos',
                                _money(pendiente['total_recaudado']),
                              ),
                              _kv(
                                'Baños',
                                '${pendiente['total_banos'] ?? 0} / ${_money(pendiente['total_banos_monto'])}',
                              ),
                              if (pendiente.containsKey('total_mensualidades'))
                                _kv(
                                  'Mensualidades',
                                  '${pendiente['total_mensualidades'] ?? 0} / ${_money(pendiente['total_mensualidades_monto'])}',
                                ),
                              const Divider(),
                              _kv(
                                'Total general',
                                _money(pendiente['total_general']),
                              ),
                              _kv('Gastos', _money(pendiente['total_gastos'])),
                              _kv(
                                'Total neto',
                                _money(pendiente['total_neto']),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: _closing ? null : _crearCierre,
                                  icon: _closing
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(Icons.lock_clock),
                                  label: const Text('Realizar cierre'),
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Últimos cierres',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                if (_historial.isEmpty)
                  const Text('Todavía no hay cierres registrados.'),
                for (final item in _historial)
                  Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      title: Text(
                        'Total general: ${_money(item['total_general'])}',
                      ),
                      subtitle: Text(_historySubtitle(item)),
                      isThreeLine:
                          item.containsKey('total_gastos') &&
                              item.containsKey('total_neto') ||
                          item.containsKey('total_mensualidades'),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _kv(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _money(dynamic value) {
    final n = value is num ? value.toInt() : int.tryParse('${value ?? 0}') ?? 0;
    return '\$${n.toString()}';
  }

  String _text(dynamic value) => value == null ? '-' : '$value';

  String _historySubtitle(Map<String, dynamic> item) {
    final financialTotals =
        item.containsKey('total_gastos') && item.containsKey('total_neto')
        ? '\nGastos: ${_money(item['total_gastos'])} • Total neto: ${_money(item['total_neto'])}'
        : '';
    final monthlyTotals = item.containsKey('total_mensualidades')
        ? ' • Mensualidades: ${item['total_mensualidades'] ?? 0} / ${_money(item['total_mensualidades_monto'])}'
        : '';
    return '${_text(item['fecha_inicio'])} → ${_text(item['fecha_cierre'])}'
        '$financialTotals\n'
        'Salidas: ${item['total_salidas'] ?? 0} • Baños: ${item['total_banos'] ?? 0}$monthlyTotals';
  }
}
