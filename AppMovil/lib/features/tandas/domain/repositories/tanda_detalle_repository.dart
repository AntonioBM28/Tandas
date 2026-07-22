import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../models/tanda_detalle.dart';

class TandaDetalleRepository {
  final DioClient _dioClient;

  TandaDetalleRepository(this._dioClient);

  Future<TandaDetalle> getTandaDetalle(String tandaId, String currentUserId) async {
    try {
      final response = await _dioClient.dio.get('/tandas/$tandaId');
      if (response.statusCode == 200) {
        return TandaDetalle.fromJson(response.data, currentUserId);
      }
      throw Exception('Tanda no encontrada');
    } catch (e) {
      throw Exception('Error al obtener detalle de la tanda: ${e.toString()}');
    }
  }

  Future<bool> invitarMiembro(String tandaId, String email) async {
    try {
      final response = await _dioClient.dio.post('/tandas/$tandaId/miembros', data: {
        'email': email,
      });
      return response.statusCode == 201 || response.statusCode == 200;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception('Este correo no está registrado en Tandas. La persona debe crear una cuenta primero.');
      }
      throw Exception(e.response?.data['message'] ?? 'Error al invitar miembro');
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<bool> quitarMiembro(String tandaId, String miembroTandaId) async {
    try {
      final response = await _dioClient.dio.delete('/tandas/$tandaId/miembros/$miembroTandaId');
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      throw Exception('Error al quitar miembro: ${e.toString()}');
    }
  }
}
