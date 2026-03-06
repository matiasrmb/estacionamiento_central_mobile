import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/storage.dart';
import '../../../core/config.dart';

class ServerSettingsScreen extends StatefulWidget {
  const ServerSettingsScreen({super.key});

  @override
  State<ServerSettingsScreen> createState() => _ServerSettingsScreenState();
}

class _ServerSettingsScreenState extends State<ServerSettingsScreen> {
  final _ctrl = TextEditingController();
  bool _loading = true;
  String? _error;

  late final SecureStore _store;
  late final AppConfig _cfg;

  @override
  void initState() {
    super.initState();
    _store = SecureStore();
    _cfg = AppConfig(store: _store);
    _load();
  }

  Future<void> _load() async {
    final current = await _cfg.getApiBaseUrl();
    _ctrl.text = current;
    if (!mounted) return;
    setState(() => _loading = false);
  }

  bool _isValidBaseUrl(String s) {
    // MVP: exigimos http://IP:PUERTO/api/v1
    // (Luego podemos permitir hostnames o https)
    return s.startsWith('http://') && s.endsWith('/api/v1') && s.contains(':');
  }

  Future<void> _save() async {
    setState(() => _error = null);

    final v = _ctrl.text.trim();
    if (!_isValidBaseUrl(v)) {
      setState(() => _error = 'Formato esperado: http://IP:PUERTO/api/v1');
      return;
    }

    await _cfg.setApiBaseUrl(v);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Servidor guardado')),
    );
    context.pop();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Servidor (LAN)'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Si hay stack, pop. Si no, vuelve a /home.
            if (Navigator.of(context).canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Base URL FastAPI (incluye /api/v1)'),
            const SizedBox(height: 8),
            TextField(
              controller: _ctrl,
              decoration: const InputDecoration(
                hintText: 'http://192.168.100.10:8000/api/v1',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            if (_error != null) ...[
              Text(_error!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 10),
            ],
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                child: const Text('Guardar'),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Tip: si cambia la IP del PC servidor, actualízala aquí.\n'
              'Luego vuelve a Login/Ingreso/Activos para que ApiClient.init() la lea.',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}