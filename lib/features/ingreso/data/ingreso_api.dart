import 'package:dio/dio.dart';
import '../../../core/http_client.dart';
import '../../../core/api_error.dart';

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
      throw ApiErrorMapper.fromDio(e);
    }
  }
}