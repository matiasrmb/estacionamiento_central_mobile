import 'package:dio/dio.dart';
import '../../../core/http_client.dart';

class AuthApi {
  final ApiClient client;
  AuthApi(this.client);

  Future<Map<String, dynamic>> login({
    required String usuario,
    required String clave,
  }) async {
    try {
      final Response res = await client.dio.post(
        '/auth/login',
        data: {'usuario': usuario, 'clave': clave},
      );
      return Map<String, dynamic>.from(res.data);
    } on DioException catch (e) {
      // Esto da status code y body del backend
      final status = e.response?.statusCode;
      final data = e.response?.data;
      throw Exception('HTTP $status - $data');
    }
  }
}