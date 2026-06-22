import 'package:dio/dio.dart';

import '../../../core/api_error.dart';
import '../../../core/http_client.dart';

class OperacionesApi {
  final ApiClient client;

  OperacionesApi(this.client);

  Future<void> registrarBano({int? monto}) async {
    await _send(() => client.dio.post('/banos', data: {'monto': monto}));
  }

  Future<List<Map<String, dynamic>>> listarCategoriasLavado() async {
    try {
      final Response res = await client.dio.get('/lavados/categorias');
      final data = res.data;
      if (data is Map && data['items'] is List) {
        return List<Map<String, dynamic>>.from(
          data['items'].map((item) => Map<String, dynamic>.from(item as Map)),
        );
      }
      throw ApiException('Formato inesperado de categorías de lavado.');
    } on DioException catch (e) {
      throw ApiErrorMapper.fromDio(e);
    }
  }

  Future<void> iniciarLavado({required int idIngreso, required String categoriaLavado}) async {
    await _send(() {
      return client.dio.post(
        '/lavados/iniciar',
        data: {'id_ingreso': idIngreso, 'categoria_lavado': categoriaLavado},
      );
    });
  }

  Future<void> finalizarLavado({required int idIngreso}) async {
    await _send(() => client.dio.post('/lavados/finalizar', data: {'id_ingreso': idIngreso}));
  }

  Future<void> _send(Future<Response<dynamic>> Function() request) async {
    try {
      await request();
    } on DioException catch (e) {
      throw ApiErrorMapper.fromDio(e);
    }
  }
}
