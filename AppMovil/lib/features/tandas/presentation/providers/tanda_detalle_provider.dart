import 'package:flutter/foundation.dart';
import '../../domain/repositories/tanda_detalle_repository.dart';
import '../../domain/models/tanda_detalle.dart';

class TandaDetalleProvider with ChangeNotifier {
  final TandaDetalleRepository _repository;
  
  TandaDetalle? _detalle;
  bool _isLoading = false;
  String? _errorMessage;

  TandaDetalleProvider(this._repository);

  TandaDetalle? get detalle => _detalle;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  // Necesitamos el currentUserId para saber si somos admin o miembro y mapearlo
  Future<void> fetchDetalle(String id, String currentUserId) async {
    _setLoading(true);
    _setError(null);
    try {
      _detalle = await _repository.getTandaDetalle(id, currentUserId);
    } catch (e) {
      _setError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> invitarMiembro(String tandaId, String email) async {
    _setLoading(true);
    _setError(null);
    try {
      final success = await _repository.invitarMiembro(tandaId, email);
      _setLoading(false);
      return success;
    } catch (e) {
      _setError(e.toString().replaceAll('Exception: ', ''));
      _setLoading(false);
      return false;
    }
  }

  Future<bool> quitarMiembro(String tandaId, String miembroTandaId) async {
    _setLoading(true);
    _setError(null);
    try {
      final success = await _repository.quitarMiembro(tandaId, miembroTandaId);
      if (success && _detalle != null) {
        _detalle!.miembros.removeWhere((m) => m.id == miembroTandaId);
        notifyListeners();
      }
      _setLoading(false);
      return success;
    } catch (e) {
      _setError(e.toString().replaceAll('Exception: ', ''));
      _setLoading(false);
      return false;
    }
  }
}
