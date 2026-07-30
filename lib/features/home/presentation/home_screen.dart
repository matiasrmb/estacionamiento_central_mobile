import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/app_services.dart';
import '../../../core/roles.dart';
import '../../../core/storage.dart';
import '../../../ui/theme.dart';
import '../../auth/data/auth_api.dart';
import '../../auth/data/auth_repository.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _store = SecureStore();
  late final AuthRepository _authRepo;
  String _user = '';
  String _role = '';

  @override
  void initState() {
    super.initState();
    _authRepo = AuthRepository(
      api: AuthApi(AppServices.I.client),
      store: _store,
    );
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
    await _authRepo.logout();
    if (!mounted) return;
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = AppRoles.isAdmin(_role);
    final canManageCierresYGastos =
        _role.isNotEmpty && AppRoles.isOperatorOrAdmin(_role);

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
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.sidebar,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Panel principal',
                    style: Theme.of(
                      context,
                    ).textTheme.titleLarge?.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Usuario: ${_user.isEmpty ? '-' : _user}',
                    style: const TextStyle(color: Color(0xFFF9FAFB)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Rol: ${_role.isEmpty ? '-' : _role}',
                    style: const TextStyle(color: Color(0xFFCBD5E1)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _SectionCard(
              title: 'Operación diaria',
              subtitle: 'Ingresos, salidas y servicios rápidos.',
              children: [
                _HomeActionButton(
                  label: 'Operación diaria unificada',
                  icon: Icons.search,
                  onPressed: () => context.go('/operacion-diaria'),
                ),
                const SizedBox(height: 10),
                _HomeActionButton(
                  label: 'Ingreso',
                  icon: Icons.login,
                  onPressed: () => context.go('/ingreso'),
                ),
                const SizedBox(height: 10),
                _HomeActionButton(
                  label: 'Activos / Salida',
                  icon: Icons.logout,
                  onPressed: () => context.go('/activos'),
                ),
                const SizedBox(height: 10),
                _HomeActionButton(
                  label: 'Lavados / Baño',
                  icon: Icons.local_car_wash,
                  onPressed: () => context.go('/operaciones'),
                ),
              ],
            ),
            if (canManageCierresYGastos) ...[
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Cierres y gastos',
                subtitle: 'Control del cierre diario y gastos operacionales.',
                children: [
                  _HomeActionButton(
                    label: 'Cierres',
                    icon: Icons.lock_clock,
                    onPressed: () => context.go('/admin/cierres'),
                  ),
                  const SizedBox(height: 10),
                  _HomeActionButton(
                    label: 'Gastos',
                    icon: Icons.receipt_long,
                    onPressed: () => context.go('/admin/gastos'),
                  ),
                ],
              ),
            ],
            if (isAdmin) ...[
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Administración',
                subtitle: 'Gestión y control del estacionamiento.',
                children: [
                  _HomeActionButton(
                    label: 'Reportes',
                    icon: Icons.assessment,
                    onPressed: () => context.go('/admin/reportes'),
                  ),
                  const SizedBox(height: 10),
                  _HomeActionButton(
                    label: 'Configuración',
                    icon: Icons.settings,
                    onPressed: () => context.go('/admin/configuracion'),
                  ),
                  const SizedBox(height: 10),
                  _HomeActionButton(
                    label: 'Tarifas',
                    icon: Icons.payments,
                    onPressed: () => context.go('/admin/tarifas'),
                  ),
                  const SizedBox(height: 10),
                  _HomeActionButton(
                    label: 'Mensuales',
                    icon: Icons.calendar_month,
                    onPressed: () => context.go('/admin/mensuales'),
                  ),
                  const SizedBox(height: 10),
                  _HomeActionButton(
                    label: 'Usuarios',
                    icon: Icons.people,
                    onPressed: () => context.go('/admin/usuarios'),
                  ),
                  const SizedBox(height: 10),
                  _HomeActionButton(
                    label: 'Asistencias',
                    icon: Icons.badge,
                    onPressed: () => context.go('/admin/asistencias'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 14),
            ...children,
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
    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(fontSize: 15),
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.mutedText),
            ],
          ),
        ),
      ),
    );
  }
}
