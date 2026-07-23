import 'package:estacionamiento_central_mobile/features/bootstrap/presentation/bootstrap_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('resolveBootstrapRoute', () {
    test(
      'routes to settings when baseUrl is null or empty even with a session',
      () {
        expect(
          resolveBootstrapRoute(baseUrl: null, token: 'token', role: 'admin'),
          '/settings',
        );
        expect(
          resolveBootstrapRoute(baseUrl: '   ', token: 'token', role: 'admin'),
          '/settings',
        );
      },
    );

    test('routes to home when baseUrl and session are present', () {
      expect(
        resolveBootstrapRoute(
          baseUrl: 'http://10.10.0.25:8000/api/v1',
          token: 'token',
          role: 'admin',
        ),
        '/home',
      );
    });

    test('routes to login when baseUrl is present but session is missing', () {
      expect(
        resolveBootstrapRoute(
          baseUrl: 'http://10.10.0.25:8000/api/v1',
          token: null,
          role: 'admin',
        ),
        '/login',
      );
      expect(
        resolveBootstrapRoute(
          baseUrl: 'http://10.10.0.25:8000/api/v1',
          token: 'token',
          role: null,
        ),
        '/login',
      );
    });
  });
}
