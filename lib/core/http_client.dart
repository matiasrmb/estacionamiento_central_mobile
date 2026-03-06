import 'package:dio/dio.dart';
import 'storage.dart';
import 'config.dart';

class ApiClient {
  final Dio dio;
  final SecureStore store;

  ApiClient({required this.store})
      : dio = Dio(
          BaseOptions(
            baseUrl: '', // se setea en init()
            connectTimeout: AppConfig.connectTimeout,
            receiveTimeout: AppConfig.receiveTimeout,
          ),
        ) {
    dio.interceptors.add(
      InterceptorsWrapper(
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
      ),
    );
  }

  /// Debes llamar esto una vez antes de usar APIs.
  Future<void> init() async {
    final cfg = AppConfig(store: store);
    final baseUrl = await cfg.getApiBaseUrl();

    dio.options.baseUrl = baseUrl;

    // DEBUG
    // ignore: avoid_print
    print('API baseUrl = ${dio.options.baseUrl}');
  }
}