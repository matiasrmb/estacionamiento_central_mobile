import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/app_services.dart';
import '../../../ui/theme.dart';
import '../../salida/data/activos_api.dart';
import '../../operacion_diaria/data/operacion_diaria_state.dart';
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
  List<Map<String, dynamic>> _soloLavados = [];
  List<Map<String, dynamic>> _categorias = [];
  List<Map<String, dynamic>> _tiposVehiculoLavado = [];
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final client = AppServices.I.client;
    _api = OperacionesApi(client);
    _activosApi = ActivosApi(client);
    _load();
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
      final categorias = await _api.listarCategoriasLavado();
      final soloLavados = await _api.listarSoloLavadosActivos();
      final tiposVehiculoLavado = await _api.listarTiposVehiculoLavado();
      if (!mounted) return;
      setState(() {
        _activos = activos;
        _soloLavados = soloLavados;
        _categorias = categorias;
        _tiposVehiculoLavado = tiposVehiculoLavado;
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

  String _patente(dynamic item) =>
      item is Map ? '${item['patente'] ?? ''}' : '';
  bool _enLavado(dynamic item) =>
      item is Map && (item['en_lavado'] == true || item['en_lavado'] == 1);

  List<dynamic> get _filteredActivos {
    final query = normalizePlateInput(_searchCtrl.text);
    if (query.isEmpty) return _activos;
    return _activos
        .where((item) => normalizePlateInput(_patente(item)).contains(query))
        .toList();
  }

  List<Map<String, dynamic>> get _filteredSoloLavados {
    final query = normalizePlateInput(_searchCtrl.text);
    if (query.isEmpty) return _soloLavados;
    return _soloLavados
        .where(
          (item) =>
              normalizePlateInput('${item['patente'] ?? ''}').contains(query),
        )
        .toList();
  }

  bool get _hasExactActivePlate {
    final plate = normalizePlateInput(_searchCtrl.text);
    if (plate.isEmpty) return false;
    return _activos.any(
          (item) => normalizePlateInput(_patente(item)) == plate,
        ) ||
        _soloLavados.any(
          (item) => normalizePlateInput('${item['patente'] ?? ''}') == plate,
        );
  }

  Future<void> _registrarBano() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar baño'),
        content: const Text(
          '¿Registrar un uso de baño con el valor configurado?',
        ),
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
              onPressed: () =>
                  Navigator.of(context).pop('${categoria['clave']}'),
              child: Text('${categoria['label']} - ${categoria['valor']}'),
            ),
        ],
      ),
    );
    if (categoria == null) return;
    try {
      await _api.iniciarLavado(
        idIngreso: idIngreso,
        categoriaLavado: categoria,
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('No se pudo iniciar lavado: $e')));
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo finalizar lavado: $e')),
      );
    }
  }

  Future<Map<String, dynamic>?> _seleccionarTipoVehiculoLavado() async {
    final activos = _tiposVehiculoLavado
        .where((tipo) => tipo['activo'] == true || tipo['activo'] == 1)
        .toList();
    if (activos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay tipos de vehículo lavado activos.'),
        ),
      );
      return null;
    }
    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Seleccionar solo lavado'),
        children: [
          for (final tipo in activos)
            SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop(tipo),
              child: Text('${tipo['nombre']} - ${tipo['valor_lavado']}'),
            ),
        ],
      ),
    );
  }

  Future<void> _iniciarSoloLavado() async {
    final patente = normalizePlateInput(_searchCtrl.text);
    if (patente.isEmpty || _hasExactActivePlate) return;
    final tipo = await _seleccionarTipoVehiculoLavado();
    if (tipo == null) return;
    final id = tipo['id_tipo_vehiculo_lavado'];
    final idTipo = id is int ? id : int.tryParse('$id');
    if (idTipo == null) return;
    try {
      await _api.iniciarSoloLavado(
        patente: patente,
        idTipoVehiculoLavado: idTipo,
      );
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Solo lavado iniciado')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo iniciar solo lavado: $e')),
      );
    }
  }

  Future<void> _finalizarSoloLavado(Map<String, dynamic> item) async {
    final id = item['id_operacion_servicio'];
    final idOperacion = id is int ? id : int.tryParse('$id');
    if (idOperacion == null) return;
    final accion = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Finalizar solo lavado'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.of(context).pop('cobrar'),
            child: const Text('Cobrar ahora'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.of(context).pop('convertir'),
            child: const Text('Convertir a estadía'),
          ),
        ],
      ),
    );
    if (accion == null) return;
    try {
      if (accion == 'cobrar') {
        await _api.cobrarSoloLavado(idOperacionServicio: idOperacion);
      } else {
        await _api.convertirSoloLavado(idOperacionServicio: idOperacion);
      }
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo finalizar solo lavado: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lavados / Baño'),
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
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Operaciones rápidas',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Gestiona lavados, solo lavados y usos de baño.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (_error != null) ...[
                  _MessageBox(text: _error!, isError: true),
                  const SizedBox(height: 12),
                ],
                TextField(
                  controller: _searchCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Buscar patente para lavado',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _hasExactActivePlate
                            ? null
                            : _iniciarSoloLavado,
                        icon: const Icon(Icons.local_car_wash),
                        label: const Text('Iniciar solo lavado'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_filteredSoloLavados.isNotEmpty) ...[
                  Text(
                    'Solo lavados activos',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  for (final item in _filteredSoloLavados)
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.local_car_wash),
                        title: Text('${item['patente'] ?? ''}'),
                        subtitle: Text(
                          '${item['tipo_vehiculo_lavado_snapshot'] ?? 'Lavado'} • ${item['duracion_minutos'] ?? 0} min',
                        ),
                        trailing: Text('${item['valor_lavado_snapshot'] ?? 0}'),
                        onTap: () => _finalizarSoloLavado(item),
                      ),
                    ),
                  const SizedBox(height: 12),
                ],
                if (_filteredActivos.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'No hay vehículos activos.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ),
                for (final item in _filteredActivos)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: _enLavado(item)
                                      ? const Color(0xFFFEF3C7)
                                      : const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.local_car_wash,
                                  color: _enLavado(item)
                                      ? const Color(0xFF92400E)
                                      : AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _patente(item),
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleMedium,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _enLavado(item)
                                          ? 'En lavado'
                                          : 'Disponible para lavado',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: () => _enLavado(item)
                                ? _finalizarLavado(item)
                                : _iniciarLavado(item),
                            child: Text(
                              _enLavado(item) ? 'Finalizar' : 'Iniciar',
                            ),
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
