import 'package:dio/dio.dart';

import '../../../../core/api_error.dart';
import '../../../../core/http_client.dart';

class ConfiguracionApi {
  final ApiClient client;

  ConfiguracionApi(this.client);

  Future<Map<String, String>> obtener() async {
    try {
      final Response res = await client.dio.get('/configuracion');
      final data = res.data;
      if (data is Map && data['items'] is Map) {
        return Map<String, String>.from(
          (data['items'] as Map).map((key, value) => MapEntry('$key', '$value')),
        );
      }
      throw ApiException('Formato inesperado de configuración.');
    } on DioException catch (e) {
      throw ApiErrorMapper.fromDio(e);
    }
  }

  Future<Map<String, String>> actualizar(Map<String, String> valores) async {
    try {
      final Response res = await client.dio.put(
        '/configuracion',
        data: {'valores': valores},
      );
      final data = res.data;
      if (data is Map && data['items'] is Map) {
        return Map<String, String>.from(
          (data['items'] as Map).map((key, value) => MapEntry('$key', '$value')),
        );
      }
      throw ApiException('Formato inesperado de configuración actualizada.');
    } on DioException catch (e) {
      throw ApiErrorMapper.fromDio(e);
    }
  }
}
