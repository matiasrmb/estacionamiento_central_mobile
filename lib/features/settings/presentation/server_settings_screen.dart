import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';

import '../../../core/storage.dart';
import '../../../core/config.dart';
import '../../../core/app_services.dart';
import 'qr_server_scanner_screen.dart';

class ServerSettingsScreen extends StatefulWidget {
  const ServerSettingsScreen({super.key});

  @override
  State<ServerSettingsScreen> createState() => _ServerSettingsScreenState();
}

class _ServerSettingsScreenState extends State<ServerSettingsScreen> {
  final _ctrl = TextEditingController();
  final _ipCtrl = TextEditingController();
  final _portCtrl = TextEditingController(text: '8000');
  bool _loading = true;
  bool _testing = false;
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
    final parsed = Uri.tryParse(current);
    if (parsed != null) {
      _ipCtrl.text = parsed.host;
      if (parsed.hasPort) _portCtrl.text = '${parsed.port}';
    }
    if (!mounted) return;
    setState(() => _loading = false);
  }

  bool _isValidBaseUrl(String s) {
    return s.startsWith('http://') && s.endsWith('/api/v1') && s.contains(':');
  }

  Future<bool> _checkHealth(String baseUrl) async {
    try {
      final dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 3),
          receiveTimeout: const Duration(seconds: 3),
        ),
      );
      final res = await dio.get('$baseUrl/health');
      return res.statusCode != null && res.statusCode! >= 200 && res.statusCode! < 300;
    } catch (_) {
      return false;
    }
  }

  Future<void> _scanQr() async {
    final value = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const QrServerScannerScreen()),
    );
    if (value == null || value.isEmpty) return;
    _ctrl.text = value;
    await _save();
  }

  void _buildUrlFromIpPort() {
    final ip = _ipCtrl.text.trim();
    final port = _portCtrl.text.trim().isEmpty ? '8000' : _portCtrl.text.trim();
    if (ip.isEmpty) {
      setState(() => _error = 'Ingresa la IP que muestra run.ps1.');
      return;
    }
    _ctrl.text = 'http://$ip:$port/api/v1';
    setState(() => _error = null);
  }

  Future<void> _save() async {
    setState(() {
      _error = null;
      _testing = true;
    });

    final v = _ctrl.text.trim();
    if (!_isValidBaseUrl(v)) {
      setState(() {
        _error = 'Formato esperado: http://IP:PUERTO/api/v1';
        _testing = false;
      });
      return;
    }

    final ok = await _checkHealth(v);
    if (!ok) {
      if (!mounted) return;
      setState(() {
        _error = 'No se pudo conectar con $v/health. Verificá que run.ps1 esté activo y que el teléfono esté en la misma red.';
        _testing = false;
      });
      return;
    }

    await _cfg.setApiBaseUrl(v);

    // CLAVE: aplica el cambio al client vivo
    await AppServices.I.reloadClient();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Servidor guardado')),
    );
    setState(() => _testing = false);
    context.pop();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _ipCtrl.dispose();
    _portCtrl.dispose();
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
            if (Navigator.of(context).canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
            const Text('Entrada rápida para Sunmi'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _ipCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'IP',
                      hintText: '192.168.1.8',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _portCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Puerto',
                      hintText: '8000',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _testing ? null : _buildUrlFromIpPort,
                child: const Text('Armar URL con IP y puerto'),
              ),
            ),
            const SizedBox(height: 20),
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
                onPressed: _testing ? null : _save,
                child: Text(_testing ? 'Probando conexión...' : 'Probar y guardar'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _testing ? null : _scanQr,
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text('Escanear QR de run.ps1'),
              ),
            ),
        ],
      ),
    );
  }
}
