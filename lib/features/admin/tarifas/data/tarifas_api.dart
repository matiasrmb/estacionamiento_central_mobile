import 'package:dio/dio.dart';

import '../../../../core/api_error.dart';
import '../../../../core/http_client.dart';

class TarifasApi {
  final ApiClient client;

  TarifasApi(this.client);

  Future<List<Map<String, dynamic>>> listarPersonalizadas() async {
    try {
      final Response res = await client.dio.get('/tarifas/personalizadas');
      final data = res.data;
      if (data is Map && data['items'] is List) {
        return List<Map<String, dynamic>>.from(
          data['items'].map((item) => Map<String, dynamic>.from(item as Map)),
        );
      }
      throw ApiException('Formato inesperado de tarifas personalizadas.');
    } on DioException catch (e) {
      throw ApiErrorMapper.fromDio(e);
    }
  }

  Future<void> crear({
    required int minutoInicio,
    required int minutoFin,
    required int valor,
  }) async {
    await _send(() {
      return client.dio.post(
        '/tarifas/personalizadas',
        data: {
          'minuto_inicio': minutoInicio,
          'minuto_fin': minutoFin,
          'valor': valor,
        },
      );
    });
  }

  Future<void> actualizar({
    required int idTarifa,
    required int minutoInicio,
    required int minutoFin,
    required int valor,
  }) async {
    await _send(() {
      return client.dio.put(
        '/tarifas/personalizadas/$idTarifa',
        data: {
          'minuto_inicio': minutoInicio,
          'minuto_fin': minutoFin,
          'valor': valor,
        },
      );
    });
  }

  Future<void> eliminar(int idTarifa) async {
    await _send(() => client.dio.delete('/tarifas/personalizadas/$idTarifa'));
  }

  Future<void> _send(Future<Response<dynamic>> Function() request) async {
    try {
      await request();
    } on DioException catch (e) {
      throw ApiErrorMapper.fromDio(e);
    }
  }
}
