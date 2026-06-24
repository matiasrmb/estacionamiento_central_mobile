import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/app_services.dart';
import '../data/mensuales_api.dart';

class MensualesAdminScreen extends StatefulWidget {
  const MensualesAdminScreen({super.key});

  @override
  State<MensualesAdminScreen> createState() => _MensualesAdminScreenState();
}

class _MensualesAdminScreenState extends State<MensualesAdminScreen> {
  late final MensualesApi _api;
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _api = MensualesApi(AppServices.I.client);
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await _api.listar();
      if (!mounted) return;
      setState(() => _items = items);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'No se pudieron cargar mensuales: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openForm([Map<String, dynamic>? item]) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => _MensualFormDialog(api: _api, item: item),
    );
    if (saved == true) await _load();
  }

  Future<void> _delete(Map<String, dynamic> item) async {
    final id = item['id_vehiculo'] as int;
    try {
      await _api.eliminar(id);
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cliente mensual eliminado')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('No se pudo eliminar: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mensuales'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(),
        child: const Icon(Icons.add),
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
                if (_items.isEmpty)
                  const Text('No hay clientes mensuales activos.'),
                for (final item in _items)
                  Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      title: Text('${item['patente']}'),
                      subtitle: Text(
                        'Tarifa mensual: ${item['tarifa_mensual'] ?? 0}',
                      ),
                      trailing: Wrap(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _openForm(item),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => _delete(item),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _MensualFormDialog extends StatefulWidget {
  final MensualesApi api;
  final Map<String, dynamic>? item;

  const _MensualFormDialog({required this.api, this.item});

  @override
  State<_MensualFormDialog> createState() => _MensualFormDialogState();
}

class _MensualFormDialogState extends State<_MensualFormDialog> {
  late final TextEditingController _patenteCtrl;
  late final TextEditingController _tarifaCtrl;
  bool _saving = false;
  String? _error;

  bool get _editing => widget.item != null;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _patenteCtrl = TextEditingController(text: '${item?['patente'] ?? ''}');
    _tarifaCtrl = TextEditingController(
      text: '${item?['tarifa_mensual'] ?? ''}',
    );
  }

  Future<void> _save() async {
    final patente = _patenteCtrl.text.trim().toUpperCase().replaceAll(' ', '');
    final tarifa = int.tryParse(
      _tarifaCtrl.text.trim().isEmpty ? '0' : _tarifaCtrl.text.trim(),
    );
    if (patente.isEmpty || tarifa == null) {
      setState(() => _error = 'Ingresa patente y tarifa válida.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final item = widget.item;
      if (item == null) {
        await widget.api.crear(patente: patente, tarifaMensual: tarifa);
      } else {
        await widget.api.actualizarTarifa(
          idVehiculo: item['id_vehiculo'] as int,
          tarifaMensual: tarifa,
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'No se pudo guardar: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _patenteCtrl.dispose();
    _tarifaCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_editing ? 'Editar mensual' : 'Nuevo mensual'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _patenteCtrl,
              enabled: !_editing,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(labelText: 'Patente'),
            ),
            TextField(
              controller: _tarifaCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Tarifa mensual'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
