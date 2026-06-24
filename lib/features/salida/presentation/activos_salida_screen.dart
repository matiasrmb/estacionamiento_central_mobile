import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/app_services.dart';
import '../../../ui/theme.dart';
import '../data/activos_api.dart';
import '../data/salida_api.dart';
import '../data/salida_repository.dart';
import '../../printing/sunmi_printer_service.dart';
import '../../printing/ticket_formatter.dart';

class ActivosSalidaScreen extends StatefulWidget {
  const ActivosSalidaScreen({super.key});

  @override
  State<ActivosSalidaScreen> createState() => _ActivosSalidaScreenState();
}

class _ActivosSalidaScreenState extends State<ActivosSalidaScreen> {
  late final SalidaRepository _repo;
  final SunmiPrinterService _sunmi = SunmiPrinterService();

  bool _loadingList = false;
  String? _errorList;
  List<dynamic> _activos = [];

  Map<String, dynamic>? _selected;
  bool _loadingPreview = false;
  String? _errorPreview;
  Map<String, dynamic>? _preview;

  bool _confirming = false;
  String? _errorConfirm;

  bool _sunmiAvailable = false;
  bool _imprimirSunmi = false;

  @override
  void initState() {
    super.initState();

    final client = AppServices.I.client;
    _repo = SalidaRepository(
      activosApi: ActivosApi(client),
      salidaApi: SalidaApi(client),
    );

    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await _sunmi.init();

    if (!mounted) return;
    setState(() {
      _sunmiAvailable = _sunmi.isReady;
      _imprimirSunmi = _sunmiAvailable; // automático si es Sunmi
    });

    await _loadActivos();
  }

  Future<void> _loadActivos() async {
    setState(() {
      _loadingList = true;
      _errorList = null;
    });

    try {
      final items = await _repo.listarActivos();
      if (!mounted) return;
      setState(() => _activos = items);
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorList = 'No se pudo cargar activos: $e');
    } finally {
      if (mounted) {
        setState(() => _loadingList = false);
      }
    }
  }

  int? _getIdIngreso(dynamic item) {
    if (item is Map) {
      final v = item['id_ingreso'] ?? item['idIngreso'] ?? item['id'];
      if (v is int) return v;
      if (v is String) return int.tryParse(v);
    }
    return null;
  }

  String _getPatente(dynamic item) {
    if (item is Map) {
      final v = item['patente'] ?? item['placa'] ?? item['license_plate'];
      return (v ?? '').toString();
    }
    return '';
  }

  String _getHoraIngreso(dynamic item) {
    if (item is Map) {
      final v =
          item['hora_ingreso'] ?? item['horaIngreso'] ?? item['ingreso_at'];
      return (v ?? '').toString();
    }
    return '';
  }

  bool _isEnLavado(dynamic item) {
    if (item is Map) {
      final v = item['en_lavado'];
      return v == true || v == 1 || v == '1';
    }
    return false;
  }

  Future<void> _selectAndPreview(dynamic item) async {
    if (_isEnLavado(item)) {
      setState(() {
        _selected = Map<String, dynamic>.from(item as Map);
        _preview = null;
        _errorPreview =
            'Este vehículo está en lavado. Finaliza el lavado antes de registrar la salida.';
        _errorConfirm = null;
      });
      return;
    }

    final idIngreso = _getIdIngreso(item);
    if (idIngreso == null) {
      setState(() {
        _selected = null;
        _preview = null;
        _errorPreview =
            'El item no trae id_ingreso (revisa formato de /activos).';
      });
      return;
    }

    setState(() {
      _selected = Map<String, dynamic>.from(item as Map);
      _preview = null;
      _errorPreview = null;
      _errorConfirm = null;
      _loadingPreview = true;
    });

    try {
      final data = await _repo.preview(idIngreso);
      if (!mounted) return;
      setState(() => _preview = data);
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorPreview = 'Preview falló: $e');
    } finally {
      if (mounted) {
        setState(() => _loadingPreview = false);
      }
    }
  }

  Future<void> _confirmSalida() async {
    final sel = _selected;
    if (sel == null) return;

    final idIngreso = _getIdIngreso(sel);
    if (idIngreso == null) return;

    setState(() {
      _confirming = true;
      _errorConfirm = null;
    });

    try {
      final confirm = await _repo.confirmar(
        idIngreso,
        imprimirSunmi: _imprimirSunmi,
      );

      if (_imprimirSunmi && _sunmiAvailable) {
        try {
          final patente = _getPatente(sel);
          final lines = TicketFormatter.salidaFromConfirmResponse(
            patente: patente,
            confirm: confirm,
            previewFallback: _preview,
            horaIngreso: _getHoraIngreso(sel),
          );
          await _sunmi.printLines(lines);
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Salida OK, pero Sunmi falló: $e')),
            );
          }
        }
      }

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Salida confirmada')));

      setState(() {
        _selected = null;
        _preview = null;
      });

      await _loadActivos();
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorConfirm = 'Confirmación falló: $e');
    } finally {
      if (mounted) {
        setState(() => _confirming = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final sel = _selected;
    final preview = _preview;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Activos / Salida'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
        actions: [
          IconButton(
            onPressed: _loadingList ? null : _loadActivos,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refrescar',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Vehículos activos',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${_activos.length} vehículo(s) dentro',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    if (_loadingList)
                      const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
              ),
            ),
            if (_errorList != null) ...[
              const SizedBox(height: 10),
              _MessageBox(text: _errorList!, isError: true),
            ],
            const SizedBox(height: 12),
            Expanded(
              child: _activos.isEmpty && !_loadingList
                  ? const Center(child: Text('No hay vehículos activos.'))
                  : ListView.separated(
                      itemCount: _activos.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                        final item = _activos[i];
                        final patente = _getPatente(item);
                        final hora = _getHoraIngreso(item);
                        final id = _getIdIngreso(item)?.toString() ?? '?';
                        final enLavado = _isEnLavado(item);

                        final selected =
                            (sel != null) &&
                            (_getIdIngreso(sel) == _getIdIngreso(item));

                        return Card(
                          color: selected
                              ? const Color(0xFFEFF6FF)
                              : AppColors.surface,
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: enLavado
                                    ? const Color(0xFFFEF3C7)
                                    : const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                enLavado
                                    ? Icons.local_car_wash
                                    : Icons.directions_car,
                                color: enLavado
                                    ? const Color(0xFF92400E)
                                    : AppColors.primary,
                              ),
                            ),
                            title: Text(
                              patente.isEmpty ? '(sin patente)' : patente,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            subtitle: Text(
                              enLavado
                                  ? 'Ingreso: $hora • En lavado'
                                  : 'Ingreso: $hora • ID $id',
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => _selectAndPreview(item),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Salida',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    if (sel == null) ...[
                      Text(
                        'Selecciona un activo para ver el cálculo preliminar.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ] else ...[
                      Text(
                        'Seleccionado: ${_getPatente(sel)}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      if (_loadingPreview) ...[
                        const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(height: 8),
                      ],
                      if (_errorPreview != null) ...[
                        _MessageBox(text: _errorPreview!, isError: true),
                        const SizedBox(height: 8),
                      ],
                      if (preview != null) ...[
                        _kv('Minutos', (preview['minutos'] ?? '').toString()),
                        _kv('Monto', (preview['monto'] ?? '').toString()),
                        _kv('Detalle', (preview['detalle'] ?? '').toString()),
                        const SizedBox(height: 8),
                      ],
                      if (_sunmiAvailable)
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          value: _imprimirSunmi,
                          onChanged: (v) {
                            setState(() => _imprimirSunmi = v ?? false);
                          },
                          title: const Text('Imprimir también en Sunmi'),
                          controlAffinity: ListTileControlAffinity.leading,
                        ),
                      if (_errorConfirm != null) ...[
                        _MessageBox(text: _errorConfirm!, isError: true),
                        const SizedBox(height: 8),
                      ],
                      ElevatedButton.icon(
                        onPressed: (_confirming || preview == null)
                            ? null
                            : _confirmSalida,
                        icon: const Icon(Icons.logout),
                        label: _confirming
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Confirmar salida'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
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

class _MessageBox extends StatelessWidget {
  final String text;
  final bool isError;

  const _MessageBox({required this.text, this.isError = false});

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
