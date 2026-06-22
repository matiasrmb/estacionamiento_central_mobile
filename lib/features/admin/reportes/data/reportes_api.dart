import 'package:dio/dio.dart';

import '../../../../core/api_error.dart';
import '../../../../core/http_client.dart';

class ReportesApi {
  final ApiClient client;

  ReportesApi(this.client);

  Future<Map<String, dynamic>> movimientos({
    required DateTime fechaInicio,
    required DateTime fechaFin,
    String patente = '',
  }) async {
    try {
      final Response res = await client.dio.get(
        '/reportes/movimientos',
        queryParameters: {
          'fecha_inicio': _date(fechaInicio),
          'fecha_fin': _date(fechaFin),
          if (patente.trim().isNotEmpty)
            'patente': patente.trim().toUpperCase(),
        },
      );
      final data = res.data;
      if (data is Map) return Map<String, dynamic>.from(data);
      throw ApiException('Formato inesperado de reportes.');
    } on DioException catch (e) {
      throw ApiErrorMapper.fromDio(e);
    }
  }

  String _date(DateTime value) {
    final year = value.year.toString().padLeft(4, '0');
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}
