import 'package:dio/dio.dart';

import '../../../../core/api_error.dart';
import '../../../../core/http_client.dart';

class MensualesApi {
  final ApiClient client;

  MensualesApi(this.client);

  Future<List<Map<String, dynamic>>> listar() async {
    try {
      final Response res = await client.dio.get('/mensuales');
      final data = res.data;
      if (data is Map && data['items'] is List) {
        return List<Map<String, dynamic>>.from(
          data['items'].map((item) => Map<String, dynamic>.from(item as Map)),
        );
      }
      throw ApiException('Formato inesperado de mensuales.');
    } on DioException catch (e) {
      throw ApiErrorMapper.fromDio(e);
    }
  }

  Future<void> crear({required String patente, int? tarifaMensual}) async {
    await _send(() {
      final data = <String, dynamic>{'patente': patente};
      if (tarifaMensual != null) {
        data['tarifa_mensual'] = tarifaMensual;
      }
      return client.dio.post(
        '/mensuales',
        data: data,
      );
    });
  }

  Future<void> actualizarTarifa({
    required int idVehiculo,
    required int tarifaMensual,
  }) async {
    await _send(() {
      return client.dio.put(
        '/mensuales/$idVehiculo/tarifa',
        data: {'tarifa_mensual': tarifaMensual},
      );
    });
  }

  Future<void> eliminar(int idVehiculo) async {
    await _send(() => client.dio.delete('/mensuales/$idVehiculo'));
  }

  Future<void> _send(Future<Response<dynamic>> Function() request) async {
    try {
      await request();
    } on DioException catch (e) {
      throw ApiErrorMapper.fromDio(e);
    }
  }
}
