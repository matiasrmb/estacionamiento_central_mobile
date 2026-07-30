import 'package:dio/dio.dart';

import '../../../../core/api_error.dart';
import '../../../../core/http_client.dart';

class GastosApi {
  final ApiClient client;

  GastosApi(this.client);

  Future<Map<String, dynamic>> listarPendientes() async {
    try {
      final Response res = await client.dio.get('/gastos/pendientes');
      final data = res.data;
      if (data is Map && data['items'] is List) {
        return Map<String, dynamic>.from(data);
      }
      throw ApiException('Formato inesperado de gastos pendientes.');
    } on DioException catch (e) {
      throw ApiErrorMapper.fromDio(e);
    }
  }

  Future<void> crear({
    required String categoria,
    required String descripcion,
    required int monto,
  }) async {
    try {
      await client.dio.post(
        '/gastos',
        data: {
          'categoria': categoria,
          'descripcion': descripcion,
          'monto': monto,
        },
      );
    } on DioException catch (e) {
      throw ApiErrorMapper.fromDio(e);
    }
  }
}
