import 'package:dio/dio.dart';

import '../../../../core/api_error.dart';
import '../../../../core/http_client.dart';

class AsistenciasApi {
  final ApiClient client;

  AsistenciasApi(this.client);

  Future<Map<String, dynamic>> listar({
    required DateTime fechaInicio,
    required DateTime fechaFin,
    String usuario = '',
  }) async {
    try {
      final Response res = await client.dio.get(
        '/asistencias',
        queryParameters: {
          'fecha_inicio': _date(fechaInicio),
          'fecha_fin': _date(fechaFin),
          if (usuario.trim().isNotEmpty) 'usuario': usuario.trim(),
        },
      );
      final data = res.data;
      if (data is Map) return Map<String, dynamic>.from(data);
      throw ApiException('Formato inesperado de asistencias.');
    } on DioException catch (e) {
      throw ApiErrorMapper.fromDio(e);
    }
  }

  Future<int> cerrarActivas({String usuario = ''}) async {
    try {
      final Response res = await client.dio.post(
        '/asistencias/cerrar-activas',
        queryParameters: {
          if (usuario.trim().isNotEmpty) 'usuario': usuario.trim(),
        },
      );
      final data = res.data;
      if (data is Map) return (data['cerradas'] as num?)?.toInt() ?? 0;
      throw ApiException('Formato inesperado al cerrar asistencias.');
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
