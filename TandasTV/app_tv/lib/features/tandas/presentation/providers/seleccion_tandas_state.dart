import 'package:flutter/foundation.dart';

import '../../domain/models/tanda_resumen.dart';
import '../../domain/repositories/tandas_tv_repository.dart';

class SeleccionTandasState extends ChangeNotifier {
  final TandasTvRepository _repository;
  SeleccionTandasState(this._repository);

  List<TandaResumen> _tandas = [];
  bool _cargando = false;
  String? _error;

  List<TandaResumen> get tandas => _tandas;
  bool get cargando => _cargando;
  String? get error => _error;

  Future<void> cargar() async {
    _cargando = true;
    _error = null;
    notifyListeners();
    try {
      _tandas = await _repository.obtenerMisTandas();
    } catch (e) {
      _error = 'No se pudieron cargar tus tandas. Revisa tu conexión.';
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }
}
