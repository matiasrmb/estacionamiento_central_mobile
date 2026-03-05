import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/storage.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _store = SecureStore();
  String _user = '';
  String _role = '';

  @override
  void initState() {
    super.initState();
    _loadSession();
  }

  Future<void> _loadSession() async {
    final u = await _store.readUser() ?? '';
    final r = await _store.readRole() ?? '';
    if (!mounted) return;
    setState(() {
      _user = u;
      _role = r;
    });
  }

  Future<void> _logout() async {
    await _store.clear();
    if (!mounted) return;
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Estacionamiento Central'),
        actions: [
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Usuario: $_user', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text('Rol: $_role'),
            const SizedBox(height: 24),

            // MVP: botones placeholder (en el siguiente paso los implementamos)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => context.go('/ingreso'),
                child: const Text('Ingreso (MVP)'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => context.go('/activos'),
                child: const Text('Activos / Salida (MVP)'),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Nota: estos módulos se implementan en el próximo paso.',
            ),
          ],
        ),
      ),
    );
  }
}