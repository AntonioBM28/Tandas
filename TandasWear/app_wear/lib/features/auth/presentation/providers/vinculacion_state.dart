import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../domain/repositories/auth_repository.dart';

/// Maneja el flujo de "pide un código, muéstralo, pregunta cada rato si ya
/// lo confirmaron desde el celular".
class VinculacionState extends ChangeNotifier {
  final AuthRepository _repository;
  VinculacionState(this._repository);

  String? _codigo;
  bool _cargando = false;
  bool _vinculado = false;
  String? _error;
  Timer? _pollTimer;

  String? get codigo => _codigo;
  bool get cargando => _cargando;
  bool get vinculado => _vinculado;
  String? get error => _error;

  Future<void> iniciar() async {
    _pollTimer?.cancel();
    _cargando = true;
    _error = null;
    _codigo = null;
    notifyListeners();

    try {
      _codigo = await _repository.generarCodigo();
      _cargando = false;
      notifyListeners();
      _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) => _consultar());
    } catch (e) {
      _cargando = false;
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }

  Future<void> _consultar() async {
    if (_codigo == null) return;
    try {
      final listo = await _repository.consultarEstado(_codigo!);
      if (listo) {
        _pollTimer?.cancel();
        _vinculado = true;
        notifyListeners();
      }
    } catch (e) {
      _pollTimer?.cancel();
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }
}
