import 'package:dio/dio.dart';
import '../../../core/http_client.dart';
import '../../../core/api_error.dart';

class ActivosApi {
  final ApiClient client;
  ActivosApi(this.client);

  Future<List<dynamic>> listarActivos() async {
    try {
      final Response res = await client.dio.get('/activos');
      final data = res.data;

      if (data is Map && data['items'] is List) {
        return List<dynamic>.from(data['items']);
      }
      if (data is List) return data;

      throw ApiException('Formato inesperado de respuesta de activos.');
    } on DioException catch (e) {
      throw ApiErrorMapper.fromDio(e);
    }
  }
}