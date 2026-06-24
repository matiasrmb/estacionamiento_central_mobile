import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/app_services.dart';
import '../data/tarifas_api.dart';

class TarifasAdminScreen extends StatefulWidget {
  const TarifasAdminScreen({super.key});

  @override
  State<TarifasAdminScreen> createState() => _TarifasAdminScreenState();
}

class _TarifasAdminScreenState extends State<TarifasAdminScreen> {
  late final TarifasApi _api;
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _api = TarifasApi(AppServices.I.client);
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await _api.listarPersonalizadas();
      if (!mounted) return;
      setState(() => _items = items);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'No se pudieron cargar tarifas: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openForm([Map<String, dynamic>? item]) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => _TarifaFormDialog(api: _api, item: item),
    );
    if (saved == true) await _load();
  }

  Future<void> _delete(Map<String, dynamic> item) async {
    final id = item['id_tarifa'] as int;
    try {
      await _api.eliminar(id);
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Tramo eliminado')));
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
        title: const Text('Tarifas'),
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
                if (_items.isEmpty) const Text('No hay tramos personalizados.'),
                for (final item in _items)
                  Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      title: Text(
                        '${item['minuto_inicio']} - ${item['minuto_fin']} min',
                      ),
                      subtitle: Text('Valor: ${item['valor']}'),
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

class _TarifaFormDialog extends StatefulWidget {
  final TarifasApi api;
  final Map<String, dynamic>? item;

  const _TarifaFormDialog({required this.api, this.item});

  @override
  State<_TarifaFormDialog> createState() => _TarifaFormDialogState();
}

class _TarifaFormDialogState extends State<_TarifaFormDialog> {
  late final TextEditingController _inicioCtrl;
  late final TextEditingController _finCtrl;
  late final TextEditingController _valorCtrl;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _inicioCtrl = TextEditingController(
      text: '${item?['minuto_inicio'] ?? ''}',
    );
    _finCtrl = TextEditingController(text: '${item?['minuto_fin'] ?? ''}');
    _valorCtrl = TextEditingController(text: '${item?['valor'] ?? ''}');
  }

  Future<void> _save() async {
    final inicio = int.tryParse(_inicioCtrl.text.trim());
    final fin = int.tryParse(_finCtrl.text.trim());
    final valor = int.tryParse(_valorCtrl.text.trim());
    if (inicio == null || fin == null || valor == null) {
      setState(() => _error = 'Completa todos los campos con números válidos.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final item = widget.item;
      if (item == null) {
        await widget.api.crear(
          minutoInicio: inicio,
          minutoFin: fin,
          valor: valor,
        );
      } else {
        await widget.api.actualizar(
          idTarifa: item['id_tarifa'] as int,
          minutoInicio: inicio,
          minutoFin: fin,
          valor: valor,
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
    _inicioCtrl.dispose();
    _finCtrl.dispose();
    _valorCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.item == null ? 'Nuevo tramo' : 'Editar tramo'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _inicioCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Minuto inicio'),
            ),
            TextField(
              controller: _finCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Minuto fin'),
            ),
            TextField(
              controller: _valorCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Valor'),
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
