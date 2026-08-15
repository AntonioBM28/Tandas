import '../../../../core/network/dio_client.dart';
import '../models/pantalla_publica.dart';
import '../models/tanda_resumen.dart';

class TandasTvRepository {
  final DioClient _dioClient;

  TandasTvRepository(this._dioClient);

  Future<List<TandaResumen>> obtenerMisTandas() async {
    final response = await _dioClient.dio.get('/tandas/mis-tandas');
    final list = (response.data as List).cast<Map<String, dynamic>>();
    return list.map((j) => TandaResumen.fromJson(j)).toList();
  }

  Future<PantallaPublica> obtenerPantallaPublica(String tandaId) async {
    final response = await _dioClient.dio.get('/tandas/$tandaId/pantalla-publica');
    return PantallaPublica.fromJson(response.data as Map<String, dynamic>);
  }
}
