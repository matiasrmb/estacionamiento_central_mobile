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

  Future<List<Map<String, dynamic>>> listarTiposVehiculoLavado() async {
    try {
      final Response res = await client.dio.get('/lavados/solo/tipos-vehiculo');
      final data = res.data;
      if (data is Map && data['items'] is List) {
        return List<Map<String, dynamic>>.from(
          data['items'].map((item) => Map<String, dynamic>.from(item as Map)),
        );
      }
      throw ApiException('Formato inesperado de tipos de vehículo lavado.');
    } on DioException catch (e) {
      throw ApiErrorMapper.fromDio(e);
    }
  }

  Future<List<Map<String, dynamic>>> listarSoloLavadosActivos({
    String? patente,
  }) async {
    try {
      final Response res = await client.dio.get(
        '/lavados/solo',
        queryParameters: {
          if (patente != null && patente.trim().isNotEmpty)
            'patente': patente.trim().toUpperCase(),
        },
      );
      final data = res.data;
      if (data is Map && data['items'] is List) {
        return List<Map<String, dynamic>>.from(
          data['items'].map((item) => Map<String, dynamic>.from(item as Map)),
        );
      }
      throw ApiException('Formato inesperado de solo lavados.');
    } on DioException catch (e) {
      throw ApiErrorMapper.fromDio(e);
    }
  }

  Future<void> iniciarLavado({
    required int idIngreso,
    required String categoriaLavado,
  }) async {
    await _send(() {
      return client.dio.post(
        '/lavados/iniciar',
        data: {'id_ingreso': idIngreso, 'categoria_lavado': categoriaLavado},
      );
    });
  }

  Future<void> iniciarSoloLavado({
    required String patente,
    required int idTipoVehiculoLavado,
  }) async {
    await _send(() {
      return client.dio.post(
        '/lavados/solo',
        data: {
          'patente': patente,
          'id_tipo_vehiculo_lavado': idTipoVehiculoLavado,
        },
      );
    });
  }

  Future<void> cobrarSoloLavado({required int idOperacionServicio}) async {
    await _send(
      () => client.dio.post('/lavados/solo/$idOperacionServicio/cobrar'),
    );
  }

  Future<void> convertirSoloLavado({required int idOperacionServicio}) async {
    await _send(
      () => client.dio.post(
        '/lavados/solo/$idOperacionServicio/convertir-estadia',
      ),
    );
  }

  Future<Map<String, dynamic>> previewCotizacion(
    Map<String, dynamic> payload,
  ) async {
    try {
      final Response res = await client.dio.post(
        '/cotizaciones/preview',
        data: payload,
      );
      if (res.data is Map) return Map<String, dynamic>.from(res.data as Map);
      throw ApiException('Formato inesperado de cotización.');
    } on DioException catch (e) {
      throw ApiErrorMapper.fromDio(e);
    }
  }

  Future<Map<String, dynamic>> listarOpcionesCotizacion() async {
    try {
      final Response res = await client.dio.get('/cotizaciones/opciones');
      if (res.data is Map) return Map<String, dynamic>.from(res.data as Map);
      throw ApiException('Formato inesperado de opciones de cotización.');
    } on DioException catch (e) {
      throw ApiErrorMapper.fromDio(e);
    }
  }

  Future<void> finalizarLavado({required int idIngreso}) async {
    await _send(
      () => client.dio.post(
        '/lavados/finalizar',
        data: {'id_ingreso': idIngreso},
      ),
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
