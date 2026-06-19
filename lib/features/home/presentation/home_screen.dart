import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/roles.dart';
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
    final isAdmin = AppRoles.isAdmin(_role);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Estacionamiento Central'),
        actions: [
          IconButton(
            onPressed: () => context.push('/settings'),
            icon: const Icon(Icons.settings),
            tooltip: 'Servidor (LAN)',
          ),
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Usuario: $_user', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text('Rol: $_role'),
            const SizedBox(height: 24),

            _HomeActionButton(
              label: 'Ingreso',
              icon: Icons.login,
              onPressed: () => context.go('/ingreso'),
            ),
            const SizedBox(height: 12),
            _HomeActionButton(
              label: 'Activos / Salida',
              icon: Icons.logout,
              onPressed: () => context.go('/activos'),
            ),
            if (isAdmin) ...[
              const SizedBox(height: 24),
              Text('Administración', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              _HomeActionButton(
                label: 'Reportes',
                icon: Icons.assessment,
                onPressed: () => context.go('/admin/reportes'),
              ),
              const SizedBox(height: 12),
              _HomeActionButton(
                label: 'Configuración',
                icon: Icons.settings,
                onPressed: () => context.go('/admin/configuracion'),
              ),
              const SizedBox(height: 12),
              _HomeActionButton(
                label: 'Tarifas',
                icon: Icons.payments,
                onPressed: () => context.go('/admin/tarifas'),
              ),
              const SizedBox(height: 12),
              _HomeActionButton(
                label: 'Mensuales',
                icon: Icons.calendar_month,
                onPressed: () => context.go('/admin/mensuales'),
              ),
              const SizedBox(height: 12),
              _HomeActionButton(
                label: 'Usuarios',
                icon: Icons.people,
                onPressed: () => context.go('/admin/usuarios'),
              ),
              const SizedBox(height: 12),
              _HomeActionButton(
                label: 'Asistencias',
                icon: Icons.badge,
                onPressed: () => context.go('/admin/asistencias'),
              ),
              const SizedBox(height: 12),
              _HomeActionButton(
                label: 'Cierres',
                icon: Icons.lock_clock,
                onPressed: () => context.go('/admin/cierres'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _HomeActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  const _HomeActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        style: ElevatedButton.styleFrom(
          alignment: Alignment.centerLeft,
          minimumSize: const Size.fromHeight(52),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        label: Text(label),
      ),
    );
  }
}
