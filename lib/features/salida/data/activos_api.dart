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
        return parseItems(data['items']);
      }
      if (data is List) return parseItems(data);

      throw ApiException('Formato inesperado de respuesta de activos.');
    } on DioException catch (e) {
      throw ApiErrorMapper.fromDio(e);
    }
  }

  static List<dynamic> parseItems(List<dynamic> items) {
    return items.map((item) {
      if (item is! Map) return item;

      final parsed = Map<dynamic, dynamic>.from(item);
      parsed.putIfAbsent('monto_acumulado', () => 0);
      parsed.putIfAbsent('minutos_cobrables', () => 0);
      parsed.putIfAbsent('calculado_a', () => null);
      return parsed;
    }).toList();
  }
}
