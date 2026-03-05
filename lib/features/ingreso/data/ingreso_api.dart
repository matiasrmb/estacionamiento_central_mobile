import 'package:dio/dio.dart';
import '../../../core/http_client.dart';

class IngresoApi {
  final ApiClient client;
  IngresoApi(this.client);

  Future<Map<String, dynamic>> registrarIngreso({
    required String patente,
  }) async {
    try {
      final Response res = await client.dio.post(
        '/ingresos',
        data: {'patente': patente},
      );
      return Map<String, dynamic>.from(res.data);
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final data = e.response?.data;
      throw Exception('HTTP $status - $data');
    }
  }
}