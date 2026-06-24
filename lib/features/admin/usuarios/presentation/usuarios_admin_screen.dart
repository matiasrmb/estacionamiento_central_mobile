import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/app_services.dart';
import '../data/usuarios_api.dart';

class UsuariosAdminScreen extends StatefulWidget {
  const UsuariosAdminScreen({super.key});

  @override
  State<UsuariosAdminScreen> createState() => _UsuariosAdminScreenState();
}

class _UsuariosAdminScreenState extends State<UsuariosAdminScreen> {
  late final UsuariosApi _api;
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _api = UsuariosApi(AppServices.I.client);
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await _api.listar();
      if (!mounted) return;
      setState(() => _items = items);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'No se pudieron cargar usuarios: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openCreate() async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => _UsuarioFormDialog(api: _api),
    );
    if (saved == true) await _load();
  }

  Future<void> _changePassword(Map<String, dynamic> item) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) =>
          _PasswordDialog(api: _api, usuario: '${item['usuario']}'),
    );
    if (saved == true && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Contraseña actualizada')));
    }
  }

  Future<void> _toggleStatus(Map<String, dynamic> item) async {
    final usuario = '${item['usuario']}';
    final activo = item['activo'] == true;
    final newStatus = !activo;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(newStatus ? 'Activar usuario' : 'Desactivar usuario'),
        content: Text(
          '¿Seguro que querés ${newStatus ? 'activar' : 'desactivar'} el usuario "$usuario"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await _api.cambiarEstado(usuario: usuario, activo: newStatus);
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Estado actualizado')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('No se pudo actualizar: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Usuarios'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openCreate,
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_error != null) ...[
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 12),
                ],
                if (_items.isEmpty) const Text('No hay usuarios registrados.'),
                for (final item in _items)
                  Card(
                    child: ListTile(
                      title: Text('${item['usuario']}'),
                      subtitle: Text(
                        '${_roleLabel(item['rol'])} • ${item['activo'] == true ? 'Activo' : 'Inactivo'}',
                      ),
                      trailing: Wrap(
                        children: [
                          IconButton(
                            tooltip: 'Cambiar contraseña',
                            icon: const Icon(Icons.password),
                            onPressed: () => _changePassword(item),
                          ),
                          IconButton(
                            tooltip: item['activo'] == true
                                ? 'Desactivar'
                                : 'Activar',
                            icon: Icon(
                              item['activo'] == true
                                  ? Icons.block
                                  : Icons.check_circle,
                            ),
                            onPressed: () => _toggleStatus(item),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  String _roleLabel(dynamic role) =>
      role == 'admin' ? 'Administrador' : 'Operador';
}

class _UsuarioFormDialog extends StatefulWidget {
  final UsuariosApi api;

  const _UsuarioFormDialog({required this.api});

  @override
  State<_UsuarioFormDialog> createState() => _UsuarioFormDialogState();
}

class _UsuarioFormDialogState extends State<_UsuarioFormDialog> {
  final _usuarioCtrl = TextEditingController();
  final _claveCtrl = TextEditingController();
  String _rol = 'operador';
  bool _saving = false;
  bool _showPassword = false;
  String? _error;

  Future<void> _save() async {
    final usuario = _usuarioCtrl.text.trim();
    final clave = _claveCtrl.text;
    if (usuario.isEmpty || clave.isEmpty) {
      setState(() => _error = 'Ingresa usuario y contraseña.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.api.crear(usuario: usuario, clave: clave, rol: _rol);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'No se pudo crear: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _usuarioCtrl.dispose();
    _claveCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nuevo usuario'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _usuarioCtrl,
              decoration: const InputDecoration(labelText: 'Usuario'),
            ),
            TextField(
              controller: _claveCtrl,
              obscureText: !_showPassword,
              decoration: InputDecoration(
                labelText: 'Contraseña',
                suffixIcon: IconButton(
                  icon: Icon(
                    _showPassword ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () =>
                      setState(() => _showPassword = !_showPassword),
                ),
              ),
            ),
            DropdownButtonFormField<String>(
              initialValue: _rol,
              decoration: const InputDecoration(labelText: 'Rol'),
              items: const [
                DropdownMenuItem(value: 'operador', child: Text('Operador')),
                DropdownMenuItem(value: 'admin', child: Text('Administrador')),
              ],
              onChanged: (value) => setState(() => _rol = value ?? 'operador'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          child: const Text('Crear'),
        ),
      ],
    );
  }
}

class _PasswordDialog extends StatefulWidget {
  final UsuariosApi api;
  final String usuario;

  const _PasswordDialog({required this.api, required this.usuario});

  @override
  State<_PasswordDialog> createState() => _PasswordDialogState();
}

class _PasswordDialogState extends State<_PasswordDialog> {
  final _claveCtrl = TextEditingController();
  bool _saving = false;
  bool _showPassword = false;
  String? _error;

  Future<void> _save() async {
    final clave = _claveCtrl.text;
    if (clave.isEmpty) {
      setState(() => _error = 'Ingresa la nueva contraseña.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.api.cambiarPassword(usuario: widget.usuario, clave: clave);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'No se pudo actualizar: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _claveCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Cambiar contraseña de ${widget.usuario}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _claveCtrl,
            obscureText: !_showPassword,
            decoration: InputDecoration(
              labelText: 'Nueva contraseña',
              suffixIcon: IconButton(
                icon: Icon(
                  _showPassword ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () => setState(() => _showPassword = !_showPassword),
              ),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: Colors.red)),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
