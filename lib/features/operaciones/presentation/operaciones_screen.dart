import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/app_services.dart';
import '../../salida/data/activos_api.dart';
import '../data/operaciones_api.dart';

class OperacionesScreen extends StatefulWidget {
  const OperacionesScreen({super.key});

  @override
  State<OperacionesScreen> createState() => _OperacionesScreenState();
}

class _OperacionesScreenState extends State<OperacionesScreen> {
  late final OperacionesApi _api;
  late final ActivosApi _activosApi;
  bool _loading = true;
  String? _error;
  List<dynamic> _activos = [];
  List<Map<String, dynamic>> _categorias = [];

  @override
  void initState() {
    super.initState();
    final client = AppServices.I.client;
    _api = OperacionesApi(client);
    _activosApi = ActivosApi(client);
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final activos = await _activosApi.listarActivos();
      final categorias = await _api.listarCategoriasLavado();
      if (!mounted) return;
      setState(() {
        _activos = activos;
        _categorias = categorias;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'No se pudieron cargar operaciones: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  int? _id(dynamic item) {
    if (item is Map) {
      final value = item['id_ingreso'];
      if (value is int) return value;
      if (value is String) return int.tryParse(value);
    }
    return null;
  }

  String _patente(dynamic item) => item is Map ? '${item['patente'] ?? ''}' : '';
  bool _enLavado(dynamic item) => item is Map && (item['en_lavado'] == true || item['en_lavado'] == 1);

  Future<void> _registrarBano() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar baño'),
        content: const Text('¿Registrar un uso de baño con el valor configurado?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Registrar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await _api.registrarBano();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Baño registrado')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No se pudo registrar baño: $e')));
    }
  }

  Future<void> _iniciarLavado(dynamic item) async {
    final idIngreso = _id(item);
    if (idIngreso == null || _categorias.isEmpty) return;
    final categoria = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Seleccionar lavado'),
        children: [
          for (final categoria in _categorias)
            SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop('${categoria['clave']}'),
              child: Text('${categoria['label']} - ${categoria['valor']}'),
            ),
        ],
      ),
    );
    if (categoria == null) return;
    try {
      await _api.iniciarLavado(idIngreso: idIngreso, categoriaLavado: categoria);
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No se pudo iniciar lavado: $e')));
    }
  }

  Future<void> _finalizarLavado(dynamic item) async {
    final idIngreso = _id(item);
    if (idIngreso == null) return;
    try {
      await _api.finalizarLavado(idIngreso: idIngreso);
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No se pudo finalizar lavado: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lavados / Baño'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/home')),
        actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _registrarBano,
        icon: const Icon(Icons.wc),
        label: const Text('Baño'),
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
                if (_activos.isEmpty) const Text('No hay vehículos activos.'),
                for (final item in _activos)
                  Card(
                    child: ListTile(
                      title: Text(_patente(item)),
                      subtitle: Text(_enLavado(item) ? 'En lavado' : 'Disponible para lavado'),
                      trailing: _enLavado(item)
                          ? ElevatedButton(
                              onPressed: () => _finalizarLavado(item),
                              child: const Text('Finalizar'),
                            )
                          : ElevatedButton(
                              onPressed: () => _iniciarLavado(item),
                              child: const Text('Iniciar'),
                            ),
                    ),
                  ),
              ],
            ),
    );
  }
}
