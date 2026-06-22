import 'package:dio/dio.dart';

import '../../../../core/api_error.dart';
import '../../../../core/http_client.dart';

class CierresApi {
  final ApiClient client;

  CierresApi(this.client);

  Future<Map<String, dynamic>> pendiente() async {
    try {
      final Response res = await client.dio.get('/cierres/pendiente');
      final data = res.data;
      if (data is Map) return Map<String, dynamic>.from(data);
      throw ApiException('Formato inesperado de cierre pendiente.');
    } on DioException catch (e) {
      throw ApiErrorMapper.fromDio(e);
    }
  }

  Future<List<Map<String, dynamic>>> listar() async {
    try {
      final Response res = await client.dio.get('/cierres');
      final data = res.data;
      if (data is Map && data['items'] is List) {
        return List<Map<String, dynamic>>.from(
          data['items'].map((item) => Map<String, dynamic>.from(item as Map)),
        );
      }
      throw ApiException('Formato inesperado de cierres.');
    } on DioException catch (e) {
      throw ApiErrorMapper.fromDio(e);
    }
  }

  Future<Map<String, dynamic>> crear() async {
    try {
      final Response res = await client.dio.post('/cierres');
      final data = res.data;
      if (data is Map) return Map<String, dynamic>.from(data);
      throw ApiException('Formato inesperado al crear cierre.');
    } on DioException catch (e) {
      throw ApiErrorMapper.fromDio(e);
    }
  }
}
