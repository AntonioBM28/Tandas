import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/storage/secure_storage_service.dart';

class AuthRepository {
  final DioClient _dioClient;
  final SecureStorageService _storageService;

  AuthRepository(this._dioClient, this._storageService);

  Future<String> generarCodigo() async {
    try {
      final response = await _dioClient.dio.post('/auth/dispositivo/generar-codigo');
      return response.data['codigo'] as String;
    } catch (e) {
      throw Exception('No se pudo generar el código. Revisa tu conexión.');
    }
  }

  /// true si ya se confirmó (y ya se guardó la sesión), false si sigue
  /// pendiente. Lanza una excepción si el código ya no es válido.
  Future<bool> consultarEstado(String codigo) async {
    try {
      final response = await _dioClient.dio.get('/auth/dispositivo/estado/$codigo');
      final data = response.data as Map<String, dynamic>;
      if (data['estado'] == 'CONFIRMADO') {
        final usuario = data['usuario'] as Map<String, dynamic>;
        await _storageService.saveTokens(
          token: data['accessToken'] as String,
          refreshToken: data['refreshToken'] as String,
          userId: usuario['id'] as String,
        );
        return true;
      }
      return false;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception('El código expiró, se generará uno nuevo');
      }
      throw Exception('Error al consultar el código');
    }
  }
}
