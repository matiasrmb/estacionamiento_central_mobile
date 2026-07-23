import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/storage.dart';

String resolveBootstrapRoute({
  required String? baseUrl,
  required String? token,
  required String? role,
}) {
  if (baseUrl == null || baseUrl.trim().isEmpty) {
    return '/settings';
  }

  if (token != null && token.isNotEmpty && role != null && role.isNotEmpty) {
    return '/home';
  }

  return '/login';
}

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
    final store = SecureStore();
    final baseUrl = await store.readBaseUrl();
    final token = await store.readToken();
    final role = await store.readRole();
    if (!mounted) return;
    context.go(
      resolveBootstrapRoute(baseUrl: baseUrl, token: token, role: role),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
