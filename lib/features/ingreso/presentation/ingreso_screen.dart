import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/app_services.dart';
import '../../../ui/theme.dart';
import '../data/ingreso_api.dart';
import '../data/ingreso_repository.dart';
import '../../printing/sunmi_printer_service.dart';
import '../../printing/ticket_formatter.dart';

class IngresoScreen extends StatefulWidget {
  const IngresoScreen({super.key});

  @override
  State<IngresoScreen> createState() => _IngresoScreenState();
}

class _IngresoScreenState extends State<IngresoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _patenteCtrl = TextEditingController();

  bool _loading = false;
  bool _nochesPrepagadas = false;
  String? _error;
  Map<String, dynamic>? _result;

  late final IngresoRepository _repo;
  final SunmiPrinterService _sunmi = SunmiPrinterService();
  bool _sunmiAvailable = false;
  String? _sunmiCopyStatus;

  @override
  void initState() {
    super.initState();
    final client = AppServices.I.client;
    _repo = IngresoRepository(api: IngresoApi(client));
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await _sunmi.init();
    if (!mounted) return;
    setState(() {
      _sunmiAvailable = _sunmi.isReady;
    });
  }

  @override
  void dispose() {
    _patenteCtrl.dispose();
    super.dispose();
  }

  String _normalizePatente(String s) =>
      s.trim().toUpperCase().replaceAll(' ', '');

  bool _patenteValidaBasica(String s) {
    if (s.length < 4 || s.length > 8) return false;
    return RegExp(r'^[A-Z0-9]+$').hasMatch(s);
  }

  Future<void> _submit() async {
    setState(() {
      _error = null;
      _result = null;
      _sunmiCopyStatus = null;
      _loading = true;
    });

    final patente = _normalizePatente(_patenteCtrl.text);

    try {
      final data = await _repo.registrar(
        patente,
        nochesPrepagadas: _nochesPrepagadas,
      );
      if (!mounted) return;

      setState(() {
        _result = data;
        _nochesPrepagadas = false;
      });
      _patenteCtrl.clear();

      // This is a best-effort local copy; the API has already created the durable receipt.
      if (_sunmiAvailable) {
        try {
          final lines = TicketFormatter.ingresoFromResponse(
            patente: patente,
            response: data,
          );
          await _sunmi.printLines(lines);
          if (!mounted) return;
          setState(() => _sunmiCopyStatus = 'Copia local Sunmi impresa.');
        } catch (e) {
          if (!mounted) return;
          setState(
            () => _sunmiCopyStatus =
                'No se pudo imprimir la copia local Sunmi: $e',
          );
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Ingreso registrado. La copia local Sunmi no reemplaza el comprobante de PC.',
              ),
            ),
          );
        }
      } else {
        _sunmiCopyStatus =
            'Copia local Sunmi no disponible en este dispositivo.';
      }

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Ingreso registrado')));
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Ingreso falló: $e');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    final ingreso = result?['ingreso'];
    final ingresoData = ingreso is Map ? ingreso : result;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ingreso'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Registrar ingreso',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Ingresa la patente para abrir una nueva estadía.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _patenteCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Patente',
                          hintText: 'Ej: ABCD12',
                          prefixIcon: Icon(Icons.directions_car_outlined),
                        ),
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) {
                          if (_loading) return;
                          if (_formKey.currentState!.validate()) _submit();
                        },
                        validator: (v) {
                          final s = _normalizePatente(v ?? '');
                          if (s.isEmpty) return 'Ingresa una patente';
                          if (!_patenteValidaBasica(s)) {
                            return 'Patente inválida';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<bool>(
                        key: ValueKey(_nochesPrepagadas),
                        initialValue: _nochesPrepagadas,
                        decoration: const InputDecoration(
                          labelText: 'Tipo de ingreso',
                          prefixIcon: Icon(Icons.nights_stay_outlined),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: false,
                            child: Text('Ingreso normal'),
                          ),
                          DropdownMenuItem(
                            value: true,
                            child: Text('Ingreso en modo Noche'),
                          ),
                        ],
                        onChanged: _loading
                            ? null
                            : (value) {
                                setState(
                                  () => _nochesPrepagadas = value ?? false,
                                );
                              },
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'El modo Noche es prepago y cubre de 19:30 a 09:30, con gracia de 19:00 a 10:00.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: _loading
                            ? null
                            : () {
                                if (_formKey.currentState!.validate()) {
                                  _submit();
                                }
                              },
                        icon: const Icon(Icons.login),
                        label: _loading
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Registrar ingreso'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (_error != null) ...[
              _InfoBox(text: _error!, isError: true),
              const SizedBox(height: 12),
            ],
            if (result != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ingreso registrado',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 10),
                      _kv(
                        'ID ingreso',
                        ingresoData?['id_ingreso']?.toString() ?? '',
                      ),
                      _kv('Patente', ingresoData?['patente']?.toString() ?? ''),
                      _kv(
                        'Hora ingreso',
                        ingresoData?['hora_ingreso']?.toString() ?? '',
                      ),
                      if (result['print'] != null)
                        _kv(
                          'Comprobante durable',
                          'Enviado a PC / Print Agent',
                        ),
                      _kv(
                        'Copia local Sunmi',
                        _sunmiCopyStatus ??
                            (_sunmiAvailable ? 'Pendiente' : 'No disponible'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$k:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(v)),
        ],
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  final String text;
  final bool isError;

  const _InfoBox({required this.text, this.isError = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isError ? const Color(0xFFFEF2F2) : AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isError ? const Color(0xFFFCA5A5) : AppColors.border,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(color: isError ? AppColors.danger : AppColors.text),
      ),
    );
  }
}
