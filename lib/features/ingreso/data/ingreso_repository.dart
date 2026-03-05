import '../../../core/storage.dart';
import '../../../core/http_client.dart';
import 'ingreso_api.dart';

class IngresoRepository {
  final IngresoApi api;

  IngresoRepository({required this.api});

  Future<Map<String, dynamic>> registrar(String patente) {
    return api.registrarIngreso(patente: patente);
  }
}