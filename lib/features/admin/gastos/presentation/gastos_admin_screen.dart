import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/app_services.dart';
import '../../../../core/roles.dart';
import '../../../../core/storage.dart';
import '../data/gastos_api.dart';

class GastosAdminScreen extends StatefulWidget {
  const GastosAdminScreen({super.key});

  @override
  State<GastosAdminScreen> createState() => _GastosAdminScreenState();
}

class _GastosAdminScreenState extends State<GastosAdminScreen> {
  static const _categorias = ['Personal', 'Insumos', 'Servicios', 'Otro'];

  final _formKey = GlobalKey<FormState>();
  final _descripcionCtrl = TextEditingController();
  final _montoCtrl = TextEditingController();
  late final GastosApi _api;

  String _categoria = _categorias.first;
  bool _loading = true;
  bool _hasAccess = false;
  bool _saving = false;
  String? _error;
  List<Map<String, dynamic>> _items = [];
  int _totalGastos = 0;

  @override
  void initState() {
    super.initState();
    _api = GastosApi(AppServices.I.client);
    _loadSessionAndData();
  }

  @override
  void dispose() {
    _descripcionCtrl.dispose();
    _montoCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await _api.listarPendientes();
      final rawItems = response['items'];
      if (!mounted) return;
      setState(() {
        _items = rawItems is List
            ? rawItems
                  .map((item) => Map<String, dynamic>.from(item as Map))
                  .toList()
            : [];
        _totalGastos = _amount(response['total_gastos']);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'No se pudieron cargar gastos: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadSessionAndData() async {
    final role = await SecureStore().readRole() ?? '';
    if (!mounted) return;
    final hasAccess = AppRoles.isOperatorOrAdmin(role);
    setState(() => _hasAccess = hasAccess);
    if (!hasAccess) {
      setState(() => _loading = false);
      return;
    }
    await _load();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await _api.crear(
        categoria: _categoria,
        descripcion: _descripcionCtrl.text.trim(),
        monto: int.parse(_montoCtrl.text.trim()),
      );
      _descripcionCtrl.clear();
      _montoCtrl.clear();
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Gasto registrado.')));
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'No se pudo registrar el gasto: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gastos'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
        actions: [
          if (_hasAccess)
            IconButton(
              onPressed: _loading ? null : _load,
              icon: const Icon(Icons.refresh),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : !_hasAccess
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('No tienes permisos para gestionar gastos.'),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Registrar gasto',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          DropdownButtonFormField<String>(
                            initialValue: _categoria,
                            decoration: const InputDecoration(
                              labelText: 'Categoría',
                            ),
                            items: _categorias
                                .map(
                                  (categoria) => DropdownMenuItem(
                                    value: categoria,
                                    child: Text(categoria),
                                  ),
                                )
                                .toList(),
                            onChanged: _saving
                                ? null
                                : (value) => setState(
                                    () => _categoria = value ?? _categoria,
                                  ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _descripcionCtrl,
                            enabled: !_saving,
                            decoration: const InputDecoration(
                              labelText: 'Descripción',
                            ),
                            textCapitalization: TextCapitalization.sentences,
                            validator: (value) =>
                                value == null || value.trim().isEmpty
                                ? 'Ingresa una descripción.'
                                : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _montoCtrl,
                            enabled: !_saving,
                            decoration: const InputDecoration(
                              labelText: 'Monto',
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              final monto = int.tryParse(value?.trim() ?? '');
                              return monto == null || monto <= 0
                                  ? 'Ingresa un monto entero mayor a cero.'
                                  : null;
                            },
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _saving ? null : _submit,
                              icon: _saving
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.add),
                              label: const Text('Registrar gasto'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: ListTile(
                    title: const Text('Total pendiente'),
                    trailing: Text(
                      _money(_totalGastos),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Gastos pendientes',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                if (_error != null) ...[
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 12),
                ],
                if (_items.isEmpty) const Text('No hay gastos pendientes.'),
                for (final item in _items)
                  Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      title: Text(
                        '${item['categoria'] ?? '-'} · ${_money(item['monto'])}',
                      ),
                      subtitle: Text(
                        '${_text(item['descripcion'])}\n${_dateTime(item['fecha_hora'])}${_user(item)}',
                      ),
                      isThreeLine: true,
                    ),
                  ),
              ],
            ),
    );
  }

  int _amount(dynamic value) =>
      value is num ? value.toInt() : int.tryParse('$value') ?? 0;

  String _money(dynamic value) => '\$${_amount(value)}';

  String _text(dynamic value) => value == null ? '-' : '$value';

  String _dateTime(dynamic value) => _text(value).replaceFirst('T', ' ');

  String _user(Map<String, dynamic> item) {
    final user = item['usuario'];
    return user == null || '$user'.trim().isEmpty ? '' : ' · $user';
  }
}
