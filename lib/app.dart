import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'features/ingreso/presentation/ingreso_screen.dart';
import 'features/salida/presentation/activos_salida_screen.dart';
import 'features/bootstrap/presentation/bootstrap_screen.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/home/presentation/home_screen.dart';
import 'features/settings/presentation/server_settings_screen.dart';
import 'ui/theme.dart';

class PlaceholderScreen extends StatelessWidget {
  final String title;
  const PlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: const Center(child: Text('Pendiente de implementar en el siguiente paso')),
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
      GoRoute(path: '/ingreso', builder: (context, state) => const IngresoScreen()),
      GoRoute(path: '/activos', builder: (context, state) => const ActivosSalidaScreen()),
      GoRoute(path: '/settings', builder: (context, state) => const ServerSettingsScreen()),
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