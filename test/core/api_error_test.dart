import 'package:dio/dio.dart';
import 'package:estacionamiento_central_mobile/core/api_error.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('surfaces backend solo lavado active price configuration message', () {
    final requestOptions = RequestOptions(path: '/lavados/solo/tipos-vehiculo');
    final error = DioException(
      requestOptions: requestOptions,
      response: Response(
        requestOptions: requestOptions,
        statusCode: 409,
        data: {
          'detail':
              'Solo lavado no tiene precios activos configurados. Configurá o activá un precio/tipo de lavado en Configuración para Solo lavado.',
        },
      ),
      type: DioExceptionType.badResponse,
    );

    final mapped = ApiErrorMapper.fromDio(error);

    expect(mapped.statusCode, 409);
    expect(
      mapped.message,
      'Solo lavado no tiene precios activos configurados. Configurá o activá un precio/tipo de lavado en Configuración para Solo lavado.',
    );
  });
}
