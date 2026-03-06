import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/storage.dart';
import '../../../core/http_client.dart';
import '../data/auth_api.dart';
import '../data/auth_repository.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usuarioCtrl = TextEditingController();
  final _claveCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _loading = false;
  String? _error;

  late final AuthRepository _repo;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final store = SecureStore();
    final client = ApiClient(store: store);

    await client.init();

    _repo = AuthRepository(api: AuthApi(client), store: store);

    if (!mounted) return;
    setState(() => _ready = true);
  }

  @override
  void dispose() {
    _usuarioCtrl.dispose();
    _claveCtrl.dispose();
    super.dispose();
  }

  Future<void> _doLogin() async {
    if (!_ready) return;

    setState(() {
      _error = null;
      _loading = true;
    });

    try {
      await _repo.login(_usuarioCtrl.text.trim(), _claveCtrl.text);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login OK')),
      );

      context.go('/home');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Login falló: $e';
      });
    } finally {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _usuarioCtrl,
                decoration: const InputDecoration(labelText: 'Usuario'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Ingresa usuario' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _claveCtrl,
                decoration: const InputDecoration(labelText: 'Clave'),
                obscureText: true,
                validator: (v) => (v == null || v.isEmpty) ? 'Ingresa clave' : null,
              ),
              const SizedBox(height: 16),
              if (_error != null) ...[
                Text(_error!, style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 8),
              ],
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading
                      ? null
                      : () {
                          if (_formKey.currentState!.validate()) {
                            _doLogin();
                          }
                        },
                  child: _loading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Entrar'),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}