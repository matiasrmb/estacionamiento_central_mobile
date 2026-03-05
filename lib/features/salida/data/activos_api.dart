import 'package:dio/dio.dart';
import '../../../core/http_client.dart';

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

      throw Exception('Formato inesperado: $data');
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final body = e.response?.data;
      throw Exception('HTTP $status - $body');
    }
  }
}