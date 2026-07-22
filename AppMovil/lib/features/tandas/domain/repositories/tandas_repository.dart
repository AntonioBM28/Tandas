import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../models/tanda.dart';

class TandasRepository {
  final DioClient _dioClient;

  TandasRepository(this._dioClient);

  Future<List<Tanda>> getMisTandas() async {
    try {
      final response = await _dioClient.dio.get('/tandas/mis-tandas');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => Tanda.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Error al obtener tandas: ${e.toString()}');
    }
  }

  Future<Tanda> crearTanda({
    required String nombre,
    String? descripcion,
    required double montoAportacion,
    required String frecuencia, // SEMANAL, QUINCENAL, MENSUAL
    required int numParticipantes,
  }) async {
    try {
      final response = await _dioClient.dio.post('/tandas', data: {
        'nombre': nombre,
        'descripcion': descripcion,
        'montoAportacion': montoAportacion,
        'frecuencia': frecuencia,
        'numParticipantes': numParticipantes,
      });

      if (response.statusCode == 201 || response.statusCode == 200) {
        // La API retorna la tanda. Agregamos miRol y numMiembrosActuales manualmente
        // ya que la respuesta del POST puede que no tenga el mismo formato que mis-tandas
        final data = response.data;
        data['miRol'] = 'ADMIN';
        data['numMiembrosActuales'] = 1; 
        return Tanda.fromJson(data);
      }
      throw Exception('Error al crear tanda');
    } catch (e) {
      throw Exception('Error al crear tanda: ${e.toString()}');
    }
  }
}
