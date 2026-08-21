import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/app_services.dart';
import '../../../core/roles.dart';
import '../../../core/storage.dart';
import '../../../ui/theme.dart';
import '../../auth/data/auth_api.dart';
import '../../auth/data/auth_repository.dart';
import '../data/shift_summary_api.dart';

class HomeScreen extends StatefulWidget {
  final ShiftSummaryApi? shiftSummaryApi;

  const HomeScreen({super.key, this.shiftSummaryApi});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _store = SecureStore();
  late final AuthRepository _authRepo;
  late final ShiftSummaryApi _shiftSummaryApi;
  String _user = '';
  String _role = '';
  ShiftSummary? _shiftSummary;
  String? _shiftSummaryError;
  bool _loadingShiftSummary = false;
  bool _metricsPrivacyModeEnabled = false;

  @override
  void initState() {
    super.initState();
    _authRepo = AuthRepository(
      api: AuthApi(AppServices.I.client),
      store: _store,
    );
    _shiftSummaryApi =
        widget.shiftSummaryApi ?? ShiftSummaryApi(AppServices.I.client);
    _loadSession();
  }

  Future<void> _loadSession() async {
    final u = await _store.readUser() ?? '';
    final r = await _store.readRole() ?? '';
    final metricsPrivacyModeEnabled = await _store
        .readMetricsPrivacyModeEnabled();
    if (!mounted) return;
    setState(() {
      _user = u;
      _role = r;
      _metricsPrivacyModeEnabled = metricsPrivacyModeEnabled;
    });
    if (AppRoles.isOperatorOrAdmin(r)) {
      _loadShiftSummary();
    }
  }

  Future<void> _loadShiftSummary() async {
    if (_loadingShiftSummary) return;
    setState(() {
      _loadingShiftSummary = true;
      _shiftSummaryError = null;
    });
    try {
      final summary = await _shiftSummaryApi.obtenerResumen();
      if (!mounted) return;
      setState(() => _shiftSummary = summary);
    } catch (_) {
      if (!mounted) return;
      setState(
        () => _shiftSummaryError = 'No se pudo cargar el resumen del turno.',
      );
    } finally {
      if (mounted) setState(() => _loadingShiftSummary = false);
    }
  }

  Future<void> _logout() async {
    await _authRepo.logout();
    if (!mounted) return;
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = AppRoles.isAdmin(_role);
    final canViewShiftSummary =
        _role.isNotEmpty && AppRoles.isOperatorOrAdmin(_role);
    final canManageCierresYGastos =
        _role.isNotEmpty && AppRoles.isOperatorOrAdmin(_role);
    final canManageMensuales =
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
          if (canViewShiftSummary)
            IconButton(
              onPressed: _loadingShiftSummary ? null : _loadShiftSummary,
              icon: const Icon(Icons.refresh),
              tooltip: 'Actualizar resumen',
            ),
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: canViewShiftSummary ? _loadShiftSummary : () async {},
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
              if (canViewShiftSummary) ...[
                _ShiftSummarySection(
                  summary: _shiftSummary,
                  loading: _loadingShiftSummary,
                  error: _shiftSummaryError,
                  onRetry: _loadShiftSummary,
                  privacyModeEnabled: _metricsPrivacyModeEnabled,
                ),
                const SizedBox(height: 16),
              ],
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
              if (canManageMensuales) ...[
                const SizedBox(height: 16),
                _SectionCard(
                  title: 'Clientes mensuales',
                  subtitle: 'Gestión de clientes y pagos mensuales.',
                  children: [
                    _HomeActionButton(
                      label: 'Mensuales',
                      icon: Icons.calendar_month,
                      onPressed: () => context.go('/admin/mensuales'),
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
      ),
    );
  }
}

class _ShiftSummarySection extends StatelessWidget {
  final ShiftSummary? summary;
  final bool loading;
  final String? error;
  final Future<void> Function() onRetry;
  final bool privacyModeEnabled;

  const _ShiftSummarySection({
    required this.summary,
    required this.loading,
    required this.error,
    required this.onRetry,
    required this.privacyModeEnabled,
  });

  @override
  Widget build(BuildContext context) {
    if (loading && summary == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(14),
          child: Row(
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 10),
              Text('Cargando resumen del turno...'),
            ],
          ),
        ),
      );
    }

    if (error != null && summary == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              const Expanded(
                child: Text('No se pudo cargar el resumen del turno.'),
              ),
              IconButton(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                tooltip: 'Reintentar',
              ),
            ],
          ),
        ),
      );
    }

    final data = summary;
    if (data == null) return const SizedBox.shrink();
    return _SectionCard(
      title: 'Resumen del turno',
      subtitle: loading
          ? 'Actualizando...'
          : 'Información al ${data.consultadoA.replaceFirst('T', ' ')}.',
      children: [
        Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _ShiftMetricCard(
                    label: 'Vehículos activos',
                    value: '${data.vehiculosActivos}',
                    icon: Icons.directions_car,
                    privacyModeEnabled: privacyModeEnabled,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ShiftMetricCard(
                    label: 'Usos de baños',
                    value: '${data.usosBanos} · ${_money(data.usosBanosMonto)}',
                    icon: Icons.wc,
                    privacyModeEnabled: privacyModeEnabled,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _ShiftMetricCard(
                    label: 'Total turno',
                    value: _money(data.totalTurno),
                    icon: Icons.payments,
                    privacyModeEnabled: privacyModeEnabled,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ShiftMetricCard(
                    label: 'Total proyectado',
                    value: data.totalProyectado == null
                        ? 'No disponible'
                        : _money(data.totalProyectado!),
                    icon: Icons.account_balance_wallet,
                    privacyModeEnabled: privacyModeEnabled,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _ShiftMetricCard(
              label: 'Neto en caja',
              value: _money(data.netoCaja),
              icon: Icons.account_balance,
              privacyModeEnabled: privacyModeEnabled,
            ),
          ],
        ),
        if (error != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              const Expanded(child: Text('No se pudo actualizar el resumen.')),
              TextButton(onPressed: onRetry, child: const Text('Reintentar')),
            ],
          ),
        ],
      ],
    );
  }

  static String _money(int amount) => '\$${amount.toString()}';
}

class _ShiftMetricCard extends StatefulWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool privacyModeEnabled;

  const _ShiftMetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.privacyModeEnabled,
  });

  @override
  State<_ShiftMetricCard> createState() => _ShiftMetricCardState();
}

class _ShiftMetricCardState extends State<_ShiftMetricCard> {
  bool _revealed = false;

  @override
  Widget build(BuildContext context) {
    final valueVisible = !widget.privacyModeEnabled || _revealed;
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: AppColors.border),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: widget.privacyModeEnabled
              ? () => setState(() => _revealed = !_revealed)
              : null,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (valueVisible) ...[
                      Icon(widget.icon, size: 18),
                      const SizedBox(width: 6),
                    ],
                    Expanded(
                      child: Text(
                        widget.label,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    if (widget.privacyModeEnabled && valueVisible)
                      Icon(Icons.visibility, size: 18),
                  ],
                ),
                const SizedBox(height: 4),
                if (valueVisible)
                  Text(
                    widget.value,
                    style: Theme.of(context).textTheme.titleMedium,
                  )
                else
                  Icon(
                    widget.icon,
                    key: ValueKey('shift-metric-hidden-${widget.label}'),
                    size: 32,
                  ),
              ],
            ),
          ),
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
