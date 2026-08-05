import 'package:dio/dio.dart';
import '../../../core/http_client.dart';
import '../../../core/api_error.dart';

class AuthApi {
  final ApiClient client;
  AuthApi(this.client);

  Future<Map<String, dynamic>> login({
    required String usuario,
    required String clave,
    required String deviceId,
  }) async {
    try {
      final Response res = await client.dio.post(
        '/auth/login',
        data: {'usuario': usuario, 'clave': clave, 'device_id': deviceId},
      );
      return Map<String, dynamic>.from(res.data);
    } on DioException catch (e) {
      throw ApiErrorMapper.fromDio(e);
    }
  }

  Future<void> logout() async {
    try {
      await client.dio.post('/auth/logout');
    } on DioException catch (e) {
      throw ApiErrorMapper.fromDio(e);
    }
  }
}
