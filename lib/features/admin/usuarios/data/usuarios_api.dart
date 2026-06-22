import 'package:dio/dio.dart';

import '../../../../core/api_error.dart';
import '../../../../core/http_client.dart';

class UsuariosApi {
  final ApiClient client;

  UsuariosApi(this.client);

  Future<List<Map<String, dynamic>>> listar() async {
    try {
      final Response res = await client.dio.get('/usuarios');
      final data = res.data;
      if (data is Map && data['items'] is List) {
        return List<Map<String, dynamic>>.from(
          data['items'].map((item) => Map<String, dynamic>.from(item as Map)),
        );
      }
      throw ApiException('Formato inesperado de usuarios.');
    } on DioException catch (e) {
      throw ApiErrorMapper.fromDio(e);
    }
  }

  Future<void> crear({
    required String usuario,
    required String clave,
    required String rol,
  }) async {
    await _send(() {
      return client.dio.post(
        '/usuarios',
        data: {'usuario': usuario, 'clave': clave, 'rol': rol},
      );
    });
  }

  Future<void> cambiarPassword({
    required String usuario,
    required String clave,
  }) async {
    final encoded = Uri.encodeComponent(usuario);
    await _send(
      () =>
          client.dio.put('/usuarios/$encoded/password', data: {'clave': clave}),
    );
  }

  Future<void> cambiarEstado({
    required String usuario,
    required bool activo,
  }) async {
    final encoded = Uri.encodeComponent(usuario);
    await _send(
      () =>
          client.dio.put('/usuarios/$encoded/estado', data: {'activo': activo}),
    );
  }

  Future<void> _send(Future<Response<dynamic>> Function() request) async {
    try {
      await request();
    } on DioException catch (e) {
      throw ApiErrorMapper.fromDio(e);
    }
  }
}
