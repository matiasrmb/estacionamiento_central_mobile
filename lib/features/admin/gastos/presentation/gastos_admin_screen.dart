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
  String _role = '';
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
    final normalizedRole = AppRoles.normalize(role);
    final hasAccess = AppRoles.isOperatorOrAdmin(role);
    setState(() {
      _role = normalizedRole;
      _hasAccess = hasAccess;
    });
    if (!hasAccess) {
      setState(() => _loading = false);
      return;
    }
    await _load();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final confirmed = await _confirm(
      title: 'Confirmar gasto',
      content: '¿Registrar este gasto operacional?',
    );
    if (!confirmed) return;

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

  Future<void> _edit(Map<String, dynamic> item) async {
    if (!_isAdmin) return;
    final result = await showDialog<_GastoEditResult>(
      context: context,
      builder: (context) => _GastoEditDialog(item: item),
    );
    if (result == null) return;
    final confirmed = await _confirm(
      title: 'Confirmar edición',
      content: '¿Guardar los cambios del gasto?',
    );
    if (!confirmed) return;
    try {
      await _api.editar(
        idGasto: _amount(item['id_gasto']),
        categoria: result.categoria,
        descripcion: result.descripcion,
        monto: result.monto,
      );
      await _load();
    } catch (e) {
      if (mounted) setState(() => _error = 'No se pudo editar el gasto: $e');
    }
  }

  Future<void> _delete(Map<String, dynamic> item) async {
    if (!_isAdmin) return;
    final confirmed = await _confirm(
      title: 'Confirmar eliminación',
      content: '¿Eliminar este gasto operacional?',
    );
    if (!confirmed) return;
    try {
      await _api.eliminar(idGasto: _amount(item['id_gasto']));
      await _load();
    } catch (e) {
      if (mounted) setState(() => _error = 'No se pudo eliminar el gasto: $e');
    }
  }

  Future<bool> _confirm({
    required String title,
    required String content,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    return result == true;
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
                      trailing: _isAdmin
                          ? PopupMenuButton<String>(
                              tooltip: 'Acciones del gasto',
                              onSelected: (value) {
                                if (value == 'edit') _edit(item);
                                if (value == 'delete') _delete(item);
                              },
                              itemBuilder: (context) => const [
                                PopupMenuItem(
                                  value: 'edit',
                                  child: ListTile(
                                    leading: Icon(Icons.edit),
                                    title: Text('Editar gasto'),
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: ListTile(
                                    leading: Icon(Icons.delete),
                                    title: Text('Eliminar gasto'),
                                  ),
                                ),
                              ],
                            )
                          : null,
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

  bool get _isAdmin => AppRoles.isAdmin(_role);
}

class _GastoEditResult {
  final String categoria;
  final String descripcion;
  final int monto;

  const _GastoEditResult({
    required this.categoria,
    required this.descripcion,
    required this.monto,
  });
}

class _GastoEditDialog extends StatefulWidget {
  final Map<String, dynamic> item;

  const _GastoEditDialog({required this.item});

  @override
  State<_GastoEditDialog> createState() => _GastoEditDialogState();
}

class _GastoEditDialogState extends State<_GastoEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _descripcionCtrl;
  late final TextEditingController _montoCtrl;
  late String _categoria;

  @override
  void initState() {
    super.initState();
    final categoria =
        '${widget.item['categoria'] ?? _GastosAdminScreenState._categorias.first}';
    _categoria = _GastosAdminScreenState._categorias.contains(categoria)
        ? categoria
        : _GastosAdminScreenState._categorias.first;
    _descripcionCtrl = TextEditingController(
      text: '${widget.item['descripcion'] ?? ''}',
    );
    _montoCtrl = TextEditingController(text: '${widget.item['monto'] ?? ''}');
  }

  @override
  void dispose() {
    _descripcionCtrl.dispose();
    _montoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editar gasto'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _categoria,
              decoration: const InputDecoration(labelText: 'Categoría'),
              items: _GastosAdminScreenState._categorias
                  .map(
                    (categoria) => DropdownMenuItem(
                      value: categoria,
                      child: Text(categoria),
                    ),
                  )
                  .toList(),
              onChanged: (value) => _categoria = value ?? _categoria,
            ),
            TextFormField(
              controller: _descripcionCtrl,
              decoration: const InputDecoration(labelText: 'Descripción'),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Ingresa una descripción.'
                  : null,
            ),
            TextFormField(
              controller: _montoCtrl,
              decoration: const InputDecoration(labelText: 'Monto'),
              keyboardType: TextInputType.number,
              validator: (value) {
                final monto = int.tryParse(value?.trim() ?? '');
                return monto == null || monto <= 0
                    ? 'Ingresa un monto entero mayor a cero.'
                    : null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            if (!(_formKey.currentState?.validate() ?? false)) return;
            Navigator.of(context).pop(
              _GastoEditResult(
                categoria: _categoria,
                descripcion: _descripcionCtrl.text.trim(),
                monto: int.parse(_montoCtrl.text.trim()),
              ),
            );
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
