import 'dart:async';
import 'package:flutter/foundation.dart';

import '../../../../core/wear/wear_protocol.dart';
import '../../domain/repositories/pagos_wear_repository.dart';

/// Reemplaza al viejo estado basado en Bluetooth: el reloj carga y refresca
/// sus propios pagos pendientes directo del backend.
class PagosWearState extends ChangeNotifier {
  final PagosWearRepository _repository;
  PagosWearState(this._repository);

  List<TandaWearItem> _items = [];
  bool _cargando = false;
  String? _error;
  final Set<String> _reportando = {};
  Timer? _autoRefresh;

  List<TandaWearItem> get items => _items;
  bool get cargando => _cargando;
  String? get error => _error;

  bool estaReportando(String pagoId) => _reportando.contains(pagoId);

  void iniciar() {
    cargar();
    _autoRefresh?.cancel();
    _autoRefresh = Timer.periodic(const Duration(seconds: 45), (_) => cargar());
  }

  /// Al cerrar sesión: para el auto-refresco y limpia lo que se estaba
  /// mostrando (era de otro usuario).
  void detener() {
    _autoRefresh?.cancel();
    _items = [];
    _reportando.clear();
    _error = null;
    notifyListeners();
  }

  Future<void> cargar() async {
    _cargando = true;
    notifyListeners();
    try {
      final nuevos = await _repository.obtenerPagosPendientes();
      _items = _ordenarPorUrgencia(nuevos);
      _error = null;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  Future<void> reportarPago(String pagoId) async {
    if (_reportando.contains(pagoId)) return;
    _reportando.add(pagoId);
    notifyListeners();
    try {
      await _repository.reportarPago(pagoId);
    } catch (_) {
      // Si falla, el siguiente refresco simplemente lo sigue mostrando
      // como pendiente; no hay más que hacer desde aquí.
    }
    await cargar();
    _reportando.remove(pagoId);
    notifyListeners();
  }

  List<TandaWearItem> _ordenarPorUrgencia(List<TandaWearItem> items) {
    const orden = {
      TandaWearTipo.pagoAtrasado: 0,
      TandaWearTipo.pagoProximo: 1,
      TandaWearTipo.pagoPendiente: 2,
      TandaWearTipo.pagoReportado: 3,
    };
    final copia = List<TandaWearItem>.from(items);
    copia.sort((a, b) => (orden[a.tipo] ?? 99).compareTo(orden[b.tipo] ?? 99));
    return copia;
  }

  @override
  void dispose() {
    _autoRefresh?.cancel();
    super.dispose();
  }
}
