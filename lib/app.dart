import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'features/ingreso/presentation/ingreso_screen.dart';
import 'features/salida/presentation/activos_salida_screen.dart';
import 'features/bootstrap/presentation/bootstrap_screen.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/home/presentation/home_screen.dart';
import 'features/operaciones/presentation/operaciones_screen.dart';
import 'features/settings/presentation/server_settings_screen.dart';
import 'features/admin/configuracion/presentation/configuracion_admin_screen.dart';
import 'features/admin/asistencias/presentation/asistencias_admin_screen.dart';
import 'features/admin/cierres/presentation/cierres_admin_screen.dart';
import 'features/admin/mensuales/presentation/mensuales_admin_screen.dart';
import 'features/admin/reportes/presentation/reportes_admin_screen.dart';
import 'features/admin/tarifas/presentation/tarifas_admin_screen.dart';
import 'features/admin/usuarios/presentation/usuarios_admin_screen.dart';
import 'ui/theme.dart';

class PlaceholderScreen extends StatelessWidget {
  final String title;
  const PlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: const Center(
        child: Text('Pendiente de implementar en el siguiente paso'),
      ),
    );
  }
}

class App extends StatelessWidget {
  App({super.key});

  final _router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (context, state) => const BootstrapScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
      GoRoute(
        path: '/ingreso',
        builder: (context, state) => const IngresoScreen(),
      ),
      GoRoute(
        path: '/activos',
        builder: (context, state) => const ActivosSalidaScreen(),
      ),
      GoRoute(
        path: '/operaciones',
        builder: (context, state) => const OperacionesScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const ServerSettingsScreen(),
      ),
      GoRoute(
        path: '/admin/reportes',
        builder: (context, state) => const ReportesAdminScreen(),
      ),
      GoRoute(
        path: '/admin/configuracion',
        builder: (context, state) => const ConfiguracionAdminScreen(),
      ),
      GoRoute(
        path: '/admin/tarifas',
        builder: (context, state) => const TarifasAdminScreen(),
      ),
      GoRoute(
        path: '/admin/mensuales',
        builder: (context, state) => const MensualesAdminScreen(),
      ),
      GoRoute(
        path: '/admin/usuarios',
        builder: (context, state) => const UsuariosAdminScreen(),
      ),
      GoRoute(
        path: '/admin/asistencias',
        builder: (context, state) => const AsistenciasAdminScreen(),
      ),
      GoRoute(
        path: '/admin/cierres',
        builder: (context, state) => const CierresAdminScreen(),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Estacionamiento Central',
      theme: AppTheme.light(),
      routerConfig: _router,
    );
  }
}
