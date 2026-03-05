import 'package:dio/dio.dart';
import '../../../core/http_client.dart';

class SalidaApi {
  final ApiClient client;
  SalidaApi(this.client);

  Future<Map<String, dynamic>> previewSalida({required int idIngreso}) async {
    try {
      final Response res = await client.dio.post(
        '/salidas/preview',
        data: {'id_ingreso': idIngreso},
      );
      return Map<String, dynamic>.from(res.data);
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final body = e.response?.data;
      throw Exception('HTTP $status - $body');
    }
  }

  Future<Map<String, dynamic>> confirmarSalida({
    required int idIngreso,
    bool imprimirSunmi = false,
  }) async {
    try {
      final Response res = await client.dio.post(
        '/salidas/confirm',
        data: {'id_ingreso': idIngreso, 'imprimir_sunmi': imprimirSunmi},
      );
      return Map<String, dynamic>.from(res.data);
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final body = e.response?.data;
      throw Exception('HTTP $status - $body');
    }
  }
}