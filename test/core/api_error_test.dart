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

  test('surfaces unavailable prepaid nights message', () {
    final requestOptions = RequestOptions(path: '/ingresos');
    final error = DioException(
      requestOptions: requestOptions,
      response: Response(
        requestOptions: requestOptions,
        statusCode: 422,
        data: {
          'detail': {
            'error': {'code': 'NOCHES_NOT_AVAILABLE'},
          },
        },
      ),
      type: DioExceptionType.badResponse,
    );

    final mapped = ApiErrorMapper.fromDio(error);

    expect(mapped.statusCode, 422);
    expect(
      mapped.message,
      'No se puede registrar en modo Noche porque no está disponible. Verifica que esté habilitado y tenga un valor mayor que cero.',
    );
  });

  test('surfaces concurrent daily close message', () {
    final requestOptions = RequestOptions(path: '/cierres');
    final error = DioException(
      requestOptions: requestOptions,
      response: Response(
        requestOptions: requestOptions,
        statusCode: 409,
        data: {'detail': 'DAILY_CLOSE_IN_PROGRESS'},
      ),
      type: DioExceptionType.badResponse,
    );

    final mapped = ApiErrorMapper.fromDio(error);

    expect(mapped.statusCode, 409);
    expect(
      mapped.message,
      'Hay otro cierre diario en curso. Reintenta cuando finalice.',
    );
  });
}
