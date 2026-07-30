import 'ingreso_api.dart';

class IngresoRepository {
  final IngresoApi api;

  IngresoRepository({required this.api});

  Future<Map<String, dynamic>> registrar(
    String patente, {
    bool nochesPrepagadas = false,
  }) {
    return api.registrarIngreso(
      patente: patente,
      nochesPrepagadas: nochesPrepagadas,
    );
  }
}
