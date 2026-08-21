import 'package:dio/dio.dart';

import '../../../core/api_error.dart';
import '../../../core/http_client.dart';

class ShiftSummary {
  final String consultadoA;
  final int vehiculosActivos;
  final int usosBanos;
  final int usosBanosMonto;
  final int totalTurno;
  final int totalActualCaja;
  final int estimadoActivos;
  final int? totalProyectado;
  final int netoCaja;

  const ShiftSummary({
    required this.consultadoA,
    required this.vehiculosActivos,
    required this.usosBanos,
    required this.usosBanosMonto,
    required this.totalTurno,
    required this.totalActualCaja,
    required this.estimadoActivos,
    required this.totalProyectado,
    required this.netoCaja,
  });

  factory ShiftSummary.fromJson(Map<dynamic, dynamic> json) {
    int amount(String key) {
      final value = json[key];
      return value is num ? value.toInt() : int.tryParse('$value') ?? 0;
    }

    int? optionalAmount(String key) {
      if (!json.containsKey(key)) return null;
      final value = json[key];
      return value is num ? value.toInt() : int.tryParse('$value');
    }

    return ShiftSummary(
      consultadoA: '${json['consultado_a'] ?? ''}',
      vehiculosActivos: amount('vehiculos_activos'),
      usosBanos: amount('usos_banos'),
      usosBanosMonto: amount('usos_banos_monto'),
      totalTurno: amount('total_turno'),
      totalActualCaja: amount('total_actual_caja'),
      estimadoActivos: amount('estimado_activos'),
      totalProyectado: optionalAmount('total_proyectado'),
      netoCaja: amount('neto_caja'),
    );
  }
}

class ShiftSummaryApi {
  final ApiClient client;

  ShiftSummaryApi(this.client);

  Future<ShiftSummary> obtenerResumen() async {
    try {
      final Response response = await client.dio.get('/resumen-turno');
      if (response.data is! Map) {
        throw ApiException('Formato inesperado de resumen del turno.');
      }
      return ShiftSummary.fromJson(response.data as Map<dynamic, dynamic>);
    } on DioException catch (error) {
      throw ApiErrorMapper.fromDio(error);
    }
  }
}
