import 'package:dio/dio.dart';

import '../../../../core/api_error.dart';
import '../../../../core/http_client.dart';

class Mensual {
  final int idVehiculo;
  final String patente;
  final int tarifaMensual;
  final int? diaVencimiento;
  final String? telefono;
  final String? periodoActual;
  final String? estadoPago;
  final bool pagado;
  final String? fechaPago;
  final int? montoPago;

  const Mensual({
    required this.idVehiculo,
    required this.patente,
    required this.tarifaMensual,
    required this.diaVencimiento,
    required this.telefono,
    required this.periodoActual,
    required this.estadoPago,
    required this.pagado,
    required this.fechaPago,
    required this.montoPago,
  });

  factory Mensual.fromJson(Map<String, dynamic> json) {
    final estadoPago = json['estado_pago']?.toString().toLowerCase();
    return Mensual(
      idVehiculo: _int(json['id_vehiculo']),
      patente: json['patente']?.toString() ?? '',
      tarifaMensual: _int(json['tarifa_mensual']),
      diaVencimiento: _nullableInt(json['dia_vencimiento']),
      telefono: json['telefono']?.toString(),
      periodoActual: json['periodo_actual']?.toString(),
      estadoPago: estadoPago,
      pagado: _bool(json['pagado_periodo_actual']) || estadoPago == 'pagado',
      fechaPago: json['fecha_pago']?.toString(),
      montoPago: _nullableInt(json['monto_snapshot']),
    );
  }

  String get estadoPagoTexto {
    if (pagado) return 'Pagado';
    return estadoPago == 'vencido' ? 'Vencido' : 'Pendiente';
  }

  static int _int(dynamic value) => _nullableInt(value) ?? 0;

  static int? _nullableInt(dynamic value) =>
      value is num ? value.toInt() : int.tryParse(value?.toString() ?? '');

  static bool _bool(dynamic value) =>
      value == true || value == 1 || value?.toString().toLowerCase() == 'true';
}

class MensualesApi {
  final ApiClient client;

  MensualesApi(this.client);

  Future<List<Mensual>> listar() async {
    try {
      final Response res = await client.dio.get('/mensuales');
      final data = res.data;
      if (data is Map && data['items'] is List) {
        return data['items']
            .map(
              (item) =>
                  Mensual.fromJson(Map<String, dynamic>.from(item as Map)),
            )
            .cast<Mensual>()
            .toList();
      }
      throw ApiException('Formato inesperado de mensuales.');
    } on DioException catch (e) {
      throw ApiErrorMapper.fromDio(e);
    }
  }

  Future<void> crear({
    required String patente,
    required int tarifaMensual,
    required int diaVencimiento,
    String? telefono,
  }) async {
    await _send(() {
      final data = <String, dynamic>{
        'patente': patente,
        'tarifa_mensual': tarifaMensual,
        'dia_vencimiento': diaVencimiento,
      };
      if (telefono != null && telefono.trim().isNotEmpty) {
        data['telefono'] = telefono.trim();
      }
      return client.dio.post('/mensuales', data: data);
    });
  }

  Future<void> actualizarConfiguracion({
    required int idVehiculo,
    required int tarifaMensual,
    required int diaVencimiento,
    String? telefono,
  }) async {
    await _send(() {
      return client.dio.put(
        '/mensuales/$idVehiculo',
        data: {
          'tarifa_mensual': tarifaMensual,
          'dia_vencimiento': diaVencimiento,
          'telefono': telefono?.trim(),
        },
      );
    });
  }

  Future<void> registrarPago({
    required int idVehiculo,
    String? metodoPago,
    String? observacion,
  }) async {
    await _send(() {
      return client.dio.post(
        '/mensuales/$idVehiculo/pagos',
        data: {
          if (metodoPago != null && metodoPago.trim().isNotEmpty)
            'metodo_pago': metodoPago.trim(),
          if (observacion != null && observacion.trim().isNotEmpty)
            'observacion': observacion.trim(),
        },
      );
    });
  }

  Future<void> eliminar(int idVehiculo) async {
    await _send(() => client.dio.delete('/mensuales/$idVehiculo'));
  }

  Future<void> _send(Future<Response<dynamic>> Function() request) async {
    try {
      await request();
    } on DioException catch (e) {
      throw ApiErrorMapper.fromDio(e);
    }
  }
}
