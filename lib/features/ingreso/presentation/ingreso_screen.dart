import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/app_services.dart';
import '../data/ingreso_api.dart';
import '../data/ingreso_repository.dart';

class IngresoScreen extends StatefulWidget {
  const IngresoScreen({super.key});

  @override
  State<IngresoScreen> createState() => _IngresoScreenState();
}

class _IngresoScreenState extends State<IngresoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _patenteCtrl = TextEditingController();

  bool _loading = false;
  String? _error;
  Map<String, dynamic>? _result;

  late final IngresoRepository _repo;

  @override
  void initState() {
    super.initState();
    final client = AppServices.I.client;
    _repo = IngresoRepository(api: IngresoApi(client));
  }

  @override
  void dispose() {
    _patenteCtrl.dispose();
    super.dispose();
  }

  String _normalizePatente(String s) => s.trim().toUpperCase().replaceAll(' ', '');

  bool _patenteValidaBasica(String s) {
    if (s.length < 4 || s.length > 8) return false;
    return RegExp(r'^[A-Z0-9]+$').hasMatch(s);
  }

  Future<void> _submit() async {
    setState(() {
      _error = null;
      _result = null;
      _loading = true;
    });

    final patente = _normalizePatente(_patenteCtrl.text);

    try {
      final data = await _repo.registrar(patente);
      if (!mounted) return;

      setState(() => _result = data);
      _patenteCtrl.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingreso registrado')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Ingreso falló: $e');
    } finally {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ingreso'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Form(
              key: _formKey,
              child: TextFormField(
                controller: _patenteCtrl,
                decoration: const InputDecoration(
                  labelText: 'Patente',
                  hintText: 'Ej: ABCD12',
                ),
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) {
                  if (_loading) return;
                  if (_formKey.currentState!.validate()) _submit();
                },
                validator: (v) {
                  final s = _normalizePatente(v ?? '');
                  if (s.isEmpty) return 'Ingresa una patente';
                  if (!_patenteValidaBasica(s)) return 'Patente inválida (MVP)';
                  return null;
                },
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading
                    ? null
                    : () {
                        if (_formKey.currentState!.validate()) {
                          _submit();
                        }
                      },
                child: _loading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Registrar ingreso'),
              ),
            ),
            const SizedBox(height: 12),

            if (_error != null) ...[
              Text(_error!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 8),
            ],

            if (result != null) ...[
              const Divider(),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Resultado', style: Theme.of(context).textTheme.titleMedium),
              ),
              const SizedBox(height: 8),
              _kv('id_ingreso', result['id_ingreso']?.toString() ?? ''),
              _kv('patente', result['patente']?.toString() ?? ''),
              _kv('hora_ingreso', result['hora_ingreso']?.toString() ?? ''),
              if (result['print_jobs'] != null) _kv('print_jobs', result['print_jobs'].toString()),
            ],
          ],
        ),
      ),
    );
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120, child: Text('$k:', style: const TextStyle(fontWeight: FontWeight.w600))),
          Expanded(child: Text(v)),
        ],
      ),
    );
  }
}