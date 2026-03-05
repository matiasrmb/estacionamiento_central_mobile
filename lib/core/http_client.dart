// lib/core/http_client.dart
import 'package:dio/dio.dart';
import 'storage.dart';

class ApiClient {
  final Dio dio;
  final SecureStore store;

  ApiClient({required this.store})
      : dio = Dio(BaseOptions(
          // IMPORTANTE: incluir /api/v1
          baseUrl: 'http://192.168.1.13:8000/api/v1',
          connectTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 10),
        )) {
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await store.readToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        options.headers['Accept'] = 'application/json';

        // DEBUG
        // ignore: avoid_print
        print('HTTP -> ${options.method} ${options.uri}');
        // ignore: avoid_print
        print('Headers: ${options.headers}');
        // ignore: avoid_print
        print('Body: ${options.data}');

        return handler.next(options);
      },
      onResponse: (response, handler) {
        // ignore: avoid_print
        print('HTTP <- ${response.statusCode} ${response.requestOptions.uri}');
        // ignore: avoid_print
        print('Resp: ${response.data}');
        return handler.next(response);
      },
      onError: (e, handler) {
        // ignore: avoid_print
        print('HTTP !! ${e.response?.statusCode} ${e.requestOptions.uri}');
        // ignore: avoid_print
        print('Err: ${e.response?.data}');
        return handler.next(e);
      },
    ));
  }
}