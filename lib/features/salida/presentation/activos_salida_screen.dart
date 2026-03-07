import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/app_services.dart';
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
      if (!mounted) return;
      setState(() => _loadingList = false);
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
      final v = item['hora_ingreso'] ?? item['horaIngreso'] ?? item['ingreso_at'];
      return (v ?? '').toString();
    }
    return '';
  }

  Future<void> _selectAndPreview(dynamic item) async {
    final idIngreso = _getIdIngreso(item);
    if (idIngreso == null) {
      setState(() {
        _selected = null;
        _preview = null;
        _errorPreview = 'El item no trae id_ingreso (revisa formato de /activos).';
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
      if (!mounted) return;
      setState(() => _loadingPreview = false);
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

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Salida confirmada')),
      );

      setState(() {
        _selected = null;
        _preview = null;
      });

      await _loadActivos();
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorConfirm = 'Confirmación falló: $e');
    } finally {
      if (!mounted) return;
      setState(() => _confirming = false);
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
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Activos (${_activos.length})',
                    style: Theme.of(context).textTheme.titleMedium,
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
            if (_errorList != null) ...[
              const SizedBox(height: 6),
              Text(_errorList!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 8),
            Expanded(
              child: ListView.separated(
                itemCount: _activos.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final item = _activos[i];
                  final patente = _getPatente(item);
                  final hora = _getHoraIngreso(item);
                  final id = _getIdIngreso(item)?.toString() ?? '?';

                  final selected =
                      (sel != null) && (_getIdIngreso(sel) == _getIdIngreso(item));

                  return ListTile(
                    selected: selected,
                    title: Text(patente.isEmpty ? '(sin patente)' : patente),
                    subtitle: Text('id_ingreso: $id  •  ingreso: $hora'),
                    onTap: () => _selectAndPreview(item),
                  );
                },
              ),
            ),
            const Divider(),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Salida (preview)',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: 8),
            if (sel == null) ...[
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Selecciona un activo para ver el cálculo preliminar.'),
              ),
              const SizedBox(height: 8),
            ] else ...[
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Seleccionado: ${_getPatente(sel)} (id_ingreso ${_getIdIngreso(sel)})',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 6),
              if (_loadingPreview) ...[
                const Align(
                  alignment: Alignment.centerLeft,
                  child: SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                const SizedBox(height: 6),
              ],
              if (_errorPreview != null) ...[
                Text(_errorPreview!, style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 6),
              ],
              if (preview != null) ...[
                _kv('minutos', (preview['minutos'] ?? '').toString()),
                _kv('monto', (preview['monto'] ?? '').toString()),
                _kv('detalle', (preview['detalle'] ?? '').toString()),
                const SizedBox(height: 8),
              ],
              if (_sunmiAvailable)
                Row(
                  children: [
                    Checkbox(
                      value: _imprimirSunmi,
                      onChanged: (v) {
                        setState(() => _imprimirSunmi = v ?? false);
                      },
                    ),
                    const Expanded(
                      child: Text('Imprimir también en Sunmi'),
                    ),
                  ],
                ),
              if (_errorConfirm != null) ...[
                Text(_errorConfirm!, style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 6),
              ],
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (_confirming || preview == null) ? null : _confirmSalida,
                  child: _confirming
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Confirmar salida (imprime en PC)'),
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