import 'package:dio/dio.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class ApiErrorMapper {
  static ApiException fromDio(DioException e) {
    final status = e.response?.statusCode;
    final data = e.response?.data;

    // Timeout / conexión
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return ApiException(
          'Tiempo de conexión agotado. Verifica que el servidor esté encendido y conectado a la red local.',
        );

      case DioExceptionType.sendTimeout:
        return ApiException('Tiempo de envío agotado. Reintenta la operación.');

      case DioExceptionType.receiveTimeout:
        return ApiException(
          'El servidor tardó demasiado en responder. Reintenta.',
        );

      case DioExceptionType.connectionError:
        return ApiException(
          'No se pudo conectar al servidor. Verifica la IP configurada, el Wi-Fi y que la API esté ejecutándose.',
        );

      case DioExceptionType.badCertificate:
        return ApiException('Certificado inválido del servidor.');

      case DioExceptionType.cancel:
        return ApiException('La solicitud fue cancelada.');

      case DioExceptionType.unknown:
        return ApiException(
          'Error inesperado de red. Revisa conexión LAN y configuración del servidor.',
        );

      case DioExceptionType.badResponse:
        return _fromHttpStatus(status, data);
    }
  }

  static ApiException _fromHttpStatus(int? status, dynamic data) {
    final body = data?.toString() ?? '';

    switch (status) {
      case 400:
        return ApiException('Solicitud inválida.', statusCode: status);

      case 401:
        return ApiException(
          'Credenciales inválidas o sesión expirada.',
          statusCode: status,
        );

      case 403:
        return ApiException(
          'No tienes permisos para realizar esta acción.',
          statusCode: status,
        );

      case 404:
        return ApiException(
          'Recurso no encontrado. Verifica la ruta del servidor.',
          statusCode: status,
        );

      case 405:
        return ApiException(
          'Método no permitido por la API.',
          statusCode: status,
        );

      case 406:
        return ApiException(
          'La API rechazó el formato de la solicitud.',
          statusCode: status,
        );

      case 409:
        // Aquí intentamos rescatar mensajes útiles del backend
        if (body.contains('Solo lavado no tiene precios configurados') ||
            body.contains(
              'Solo lavado no tiene precios activos configurados',
            )) {
          return ApiException(
            'Solo lavado no tiene precios activos configurados. Configurá o activá un precio/tipo de lavado en Configuración para Solo lavado.',
            statusCode: status,
          );
        }
        if (body.contains('INGRESO_YA_SALIO')) {
          return ApiException(
            'Ese ingreso ya fue cerrado.',
            statusCode: status,
          );
        }
        if (body.contains('PLATE_ALREADY_ACTIVE')) {
          return ApiException(
            'La patente ya tiene un ingreso activo.',
            statusCode: status,
          );
        }
        return ApiException(
          'Conflicto de datos. Revisa el estado actual del registro.',
          statusCode: status,
        );

      case 422:
        if (body.contains('NOCHES_NOT_AVAILABLE')) {
          return ApiException(
            'No se puede registrar en modo Noche porque no está disponible. Verifica que esté habilitado y tenga un valor mayor que cero.',
            statusCode: status,
          );
        }
        return ApiException(
          'Datos inválidos o incompletos.',
          statusCode: status,
        );

      case 500:
        return ApiException('Error interno del servidor.', statusCode: status);

      case 503:
        if (body.contains('Solo lavado')) {
          return ApiException(
            'Solo lavado no está disponible: no se pudo actualizar la base de datos. Lavados vinculados y baño siguen disponibles.',
            statusCode: status,
          );
        }
        return ApiException(
          'Servicio no disponible. Reintenta en unos minutos.',
          statusCode: status,
        );

      default:
        return ApiException(
          'Error del servidor${status != null ? ' ($status)' : ''}. ${body.isNotEmpty ? body : ''}'
              .trim(),
          statusCode: status,
        );
    }
  }
}
