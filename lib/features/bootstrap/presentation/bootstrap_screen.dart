import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/storage.dart';

class BootstrapScreen extends StatefulWidget {
  const BootstrapScreen({super.key});

  @override
  State<BootstrapScreen> createState() => _BootstrapScreenState();
}

class _BootstrapScreenState extends State<BootstrapScreen> {
  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    await Future.delayed(const Duration(milliseconds: 150));
    final token = await SecureStore().readToken();
    final role = await SecureStore().readRole();
    if (!mounted) return;
    if (token != null && token.isNotEmpty && role != null && role.isNotEmpty) {
      context.go('/home');
      return;
    }
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
