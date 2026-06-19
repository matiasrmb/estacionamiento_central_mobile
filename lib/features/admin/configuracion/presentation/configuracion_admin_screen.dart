import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/app_services.dart';
import '../data/configuracion_api.dart';

class ConfiguracionAdminScreen extends StatefulWidget {
  const ConfiguracionAdminScreen({super.key});

  @override
  State<ConfiguracionAdminScreen> createState() => _ConfiguracionAdminScreenState();
}

class _ConfiguracionAdminScreenState extends State<ConfiguracionAdminScreen> {
  late final ConfiguracionApi _api;
  final _controllers = <String, TextEditingController>{};
  bool _loading = true;
  bool _saving = false;
  String? _error;

  static const _fields = <String, String>{
    'modo_cobro': 'Modo de cobro',
    'tarifa_minima': 'Tarifa mínima',
    'valor_minuto': 'Valor minuto',
    'tarifa_hora': 'Tarifa hora',
    'valor_bano': 'Valor baño',
    'lavado_citycar': 'Lavado CityCar',
    'lavado_suv': 'Lavado SUV',
    'lavado_camioneta': 'Lavado Camioneta',
    'lavado_furgon': 'Lavado Furgón',
    'lavado_minibus': 'Lavado Mini bus',
  };

  @override
  void initState() {
    super.initState();
    _api = ConfiguracionApi(AppServices.I.client);
    _load();
  }

  Future<void> _load() async {
    try {
      final config = await _api.obtener();
      for (final entry in _fields.entries) {
        _controllers[entry.key] = TextEditingController(text: config[entry.key] ?? '');
      }
      if (!mounted) return;
      setState(() => _loading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'No se pudo cargar configuración: $e';
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });

    final values = <String, String>{
      for (final key in _fields.keys) key: _controllers[key]!.text.trim(),
    };

    try {
      await _api.actualizar(values);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Configuración guardada')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'No se pudo guardar: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
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
                for (final entry in _fields.entries) ...[
                  TextField(
                    controller: _controllers[entry.key],
                    keyboardType: entry.key == 'modo_cobro' ? TextInputType.text : TextInputType.number,
                    decoration: InputDecoration(
                      labelText: entry.value,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save),
                    label: const Text('Guardar'),
                  ),
                ),
              ],
            ),
    );
  }
}
