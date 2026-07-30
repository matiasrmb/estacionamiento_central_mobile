import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/app_services.dart';
import '../../../../core/api_error.dart';
import '../../../../core/roles.dart';
import '../../../../core/storage.dart';
import '../data/mensuales_api.dart';

class MensualesAdminScreen extends StatefulWidget {
  const MensualesAdminScreen({super.key});

  @override
  State<MensualesAdminScreen> createState() => _MensualesAdminScreenState();
}

class _MensualesAdminScreenState extends State<MensualesAdminScreen> {
  late final MensualesApi _api;
  bool _loading = true;
  bool _canManageMensuales = false;
  String? _error;
  List<Mensual> _items = [];

  @override
  void initState() {
    super.initState();
    _api = MensualesApi(AppServices.I.client);
    _loadSessionAndData();
  }

  Future<void> _loadSessionAndData() async {
    final role = await SecureStore().readRole() ?? '';
    if (!mounted) return;
    final canManageMensuales =
        role.isNotEmpty && AppRoles.isOperatorOrAdmin(role);
    setState(() => _canManageMensuales = canManageMensuales);
    if (!canManageMensuales) {
      setState(() => _loading = false);
      return;
    }
    await _load();
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

  Future<void> _openForm([Mensual? item]) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => _MensualFormDialog(api: _api, item: item),
    );
    if (saved == true) await _load();
  }

  Future<void> _delete(Mensual item) async {
    try {
      await _api.eliminar(item.idVehiculo);
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

  Future<void> _registrarPago(Mensual item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar pago'),
        content: Text(
          'Se registrará el pago de ${item.patente} para ${item.periodoActual ?? 'el periodo actual'} por ${_money(item.tarifaMensual)}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Registrar pago'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await _api.registrarPago(idVehiculo: item.idVehiculo);
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Pago registrado.')));
    } on ApiException catch (e) {
      await _load();
      if (!mounted) return;
      final message = e.statusCode == 409
          ? 'El pago de este periodo ya fue registrado.'
          : 'No se pudo registrar el pago: $e';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo registrar el pago: $e')),
      );
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
          if (_canManageMensuales)
            IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      floatingActionButton: _canManageMensuales
          ? FloatingActionButton(
              onPressed: () => _openForm(),
              child: const Icon(Icons.add),
            )
          : null,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : !_canManageMensuales
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('No tienes permisos para administrar mensuales.'),
              ),
            )
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
                      title: Text(item.patente),
                      subtitle: Text(_mensualDetalle(item)),
                      isThreeLine: item.pagado,
                      trailing: Wrap(
                        children: [
                          if (!item.pagado)
                            IconButton(
                              tooltip: 'Registrar pago',
                              icon: const Icon(Icons.payments),
                              onPressed: () => _registrarPago(item),
                            ),
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

  String _mensualDetalle(Mensual item) {
    final lines = [
      'Tarifa mensual: ${_money(item.tarifaMensual)}${item.telefono?.trim().isNotEmpty ?? false ? ' · Teléfono: ${item.telefono}' : ''}',
      'Vence el día: ${item.diaVencimiento ?? '-'} · ${item.estadoPagoTexto}',
    ];
    if (item.pagado) {
      lines.add(
        'Pago: ${item.montoPago == null ? 'Monto no disponible' : _money(item.montoPago)}${item.fechaPago == null ? '' : ' · ${item.fechaPago!.replaceFirst('T', ' ')}'}',
      );
    }
    return lines.join('\n');
  }

  String _money(dynamic value) {
    final amount = value is num ? value.toInt() : int.tryParse('$value') ?? 0;
    return '\$$amount';
  }
}

class _MensualFormDialog extends StatefulWidget {
  final MensualesApi api;
  final Mensual? item;

  const _MensualFormDialog({required this.api, this.item});

  @override
  State<_MensualFormDialog> createState() => _MensualFormDialogState();
}

class _MensualFormDialogState extends State<_MensualFormDialog> {
  late final TextEditingController _patenteCtrl;
  late final TextEditingController _tarifaCtrl;
  late final TextEditingController _vencimientoCtrl;
  late final TextEditingController _telefonoCtrl;
  bool _saving = false;
  String? _error;

  bool get _editing => widget.item != null;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _patenteCtrl = TextEditingController(text: item?.patente ?? '');
    _tarifaCtrl = TextEditingController(text: '${item?.tarifaMensual ?? ''}');
    _vencimientoCtrl = TextEditingController(
      text: item?.diaVencimiento?.toString() ?? '',
    );
    _telefonoCtrl = TextEditingController(text: item?.telefono ?? '');
  }

  Future<void> _save() async {
    final patente = _patenteCtrl.text.trim().toUpperCase().replaceAll(' ', '');
    final tarifa = int.tryParse(
      _tarifaCtrl.text.trim().isEmpty ? '0' : _tarifaCtrl.text.trim(),
    );
    final vencimiento = int.tryParse(_vencimientoCtrl.text.trim());
    final telefono = _telefonoCtrl.text.trim();
    if (patente.isEmpty || tarifa == null || tarifa <= 0) {
      setState(() => _error = 'Ingresa patente y una tarifa mayor a cero.');
      return;
    }
    if (vencimiento == null || vencimiento < 1 || vencimiento > 31) {
      setState(() => _error = 'Ingresa un día de vencimiento entre 1 y 31.');
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
          patente: patente,
          tarifaMensual: tarifa,
          diaVencimiento: vencimiento,
          telefono: telefono,
        );
      } else {
        await widget.api.actualizarConfiguracion(
          idVehiculo: item.idVehiculo,
          tarifaMensual: tarifa,
          diaVencimiento: vencimiento,
          telefono: telefono,
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
    _vencimientoCtrl.dispose();
    _telefonoCtrl.dispose();
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
            TextFormField(
              controller: _patenteCtrl,
              enabled: !_editing,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(labelText: 'Patente'),
            ),
            TextFormField(
              controller: _tarifaCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Tarifa mensual'),
            ),
            TextFormField(
              controller: _vencimientoCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Día de vencimiento',
              ),
            ),
            TextFormField(
              controller: _telefonoCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Teléfono'),
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
