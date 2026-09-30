import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/app_services.dart';
import '../../../../core/roles.dart';
import '../../../../core/storage.dart';
import '../data/reportes_api.dart';

class ReportesAdminScreen extends StatefulWidget {
  const ReportesAdminScreen({super.key});

  @override
  State<ReportesAdminScreen> createState() => _ReportesAdminScreenState();
}

class _ReportesAdminScreenState extends State<ReportesAdminScreen> {
  late final ReportesApi _api;

  bool _loading = true;
  bool _isAdmin = false;
  String? _error;
  ReportingDashboard? _dashboard;

  @override
  void initState() {
    super.initState();
    _api = ReportesApi(AppServices.I.client);
    _load();
  }

  Future<void> _load() async {
    final role = await SecureStore().readRole() ?? '';
    if (!mounted) return;

    if (!AppRoles.isAdmin(role)) {
      setState(() {
        _isAdmin = false;
        _loading = false;
      });
      return;
    }

    setState(() {
      _isAdmin = true;
      _loading = true;
      _error = null;
    });

    try {
      final dashboard = await _api.dashboard();
      if (!mounted) return;
      setState(() => _dashboard = dashboard);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'No se pudo cargar el reporte: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dashboard = _dashboard;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportes administrativos'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
        actions: [
          IconButton(
            onPressed: _loading || !_isAdmin ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Versión ${ReportingDashboard.appVersionLabel}'),
          const SizedBox(height: 12),
          if (!_isAdmin && !_loading) ...[
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Solo administradores pueden ver reportes financieros.',
                ),
              ),
            ),
          ] else if (_loading) ...[
            const Center(child: CircularProgressIndicator()),
          ] else if (_error != null) ...[
            Text(_error!, style: const TextStyle(color: Colors.red)),
          ] else if (dashboard != null) ...[
            Text('Catálogo ${dashboard.catalogVersion}'),
            Text('Jornada operacional ${_stateLabel(dashboard.periodState)}'),
            const SizedBox(height: 12),
            for (final card in dashboard.cards) ...[
              _SummaryCard(
                title: card.label,
                value: card.metric == 'vehicle_movement_count'
                    ? '${card.value.toInt()}'
                    : _money(card.value),
              ),
              const SizedBox(height: 8),
            ],
          ],
        ],
      ),
    );
  }

  String _stateLabel(String state) => switch (state) {
    'open' => 'abierta',
    'closed' => 'cerrada',
    _ => state,
  };

  String _money(num value) => '\$${value.toInt()}';
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
