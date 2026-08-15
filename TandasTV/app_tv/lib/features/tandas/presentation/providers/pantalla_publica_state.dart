import 'dart:async';
import 'package:flutter/foundation.dart';

import '../../domain/models/pantalla_publica.dart';
import '../../domain/repositories/tandas_tv_repository.dart';

/// Pensado para quedarse abierto en la sala durante una reunión: se
/// refresca solo cada rato para reflejar pagos que se van reportando desde
/// otros dispositivos.
class PantallaPublicaState extends ChangeNotifier {
  final TandasTvRepository _repository;
  PantallaPublicaState(this._repository);

  PantallaPublica? _data;
  bool _cargando = false;
  String? _error;
  Timer? _autoRefresh;
  String? _tandaId;

  PantallaPublica? get data => _data;
  bool get cargando => _cargando;
  String? get error => _error;

  void iniciar(String tandaId) {
    _tandaId = tandaId;
    _cargar();
    _autoRefresh?.cancel();
    _autoRefresh = Timer.periodic(const Duration(seconds: 20), (_) => _cargar());
  }

  Future<void> _cargar() async {
    final tandaId = _tandaId;
    if (tandaId == null) return;
    _cargando = _data == null; // solo mostramos el loader grande la primera vez
    notifyListeners();
    try {
      _data = await _repository.obtenerPantallaPublica(tandaId);
      _error = null;
    } catch (e) {
      _error = 'No se pudo actualizar la información.';
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  Future<void> refrescar() => _cargar();

  void detener() {
    _autoRefresh?.cancel();
    _data = null;
    _tandaId = null;
  }

  @override
  void dispose() {
    _autoRefresh?.cancel();
    super.dispose();
  }
}
