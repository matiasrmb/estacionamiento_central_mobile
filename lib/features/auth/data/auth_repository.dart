import '../../../core/storage.dart';
import '../../../core/http_client.dart';
import 'auth_api.dart';

class AuthRepository {
  final AuthApi api;
  final SecureStore store;

  AuthRepository({required this.api, required this.store});

  Future<void> login(String usuario, String clave) async {
    final data = await api.login(usuario: usuario, clave: clave);
    final token = data['access_token'] as String;
    final rol = data['rol'] as String;

    await store.saveSession(token: token, user: usuario, role: rol);
  }

  Future<void> logout() => store.clear();
}