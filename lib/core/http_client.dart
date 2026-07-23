import 'package:dio/dio.dart';
import 'storage.dart';
import 'config.dart';

class ApiClient {
  final Dio dio;
  final SecureStore store;
  Future<void> Function()? onUnauthorized;

  ApiClient({required this.store, this.onUnauthorized})
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

          return handler.next(options);
        },
        onError: (e, handler) async {
          if (e.response?.statusCode == 401) {
            await store.clear();
            await onUnauthorized?.call();
          }

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
  }
}
