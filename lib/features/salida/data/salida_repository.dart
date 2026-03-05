import '../../../core/storage.dart';
import '../../../core/http_client.dart';
import 'activos_api.dart';
import 'salida_api.dart';

class SalidaRepository {
  final ActivosApi activosApi;
  final SalidaApi salidaApi;

  SalidaRepository({required this.activosApi, required this.salidaApi});

  Future<List<dynamic>> listarActivos() => activosApi.listarActivos();

  Future<Map<String, dynamic>> preview(int idIngreso) =>
      salidaApi.previewSalida(idIngreso: idIngreso);

  Future<Map<String, dynamic>> confirmar(int idIngreso, {bool imprimirSunmi = false}) =>
      salidaApi.confirmarSalida(idIngreso: idIngreso, imprimirSunmi: imprimirSunmi);
}