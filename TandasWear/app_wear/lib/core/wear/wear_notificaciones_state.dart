import 'package:flutter/foundation.dart';

import 'wear_bridge.dart';
import 'wear_protocol.dart';

/// Estado en memoria de las notificaciones de pago que llegan del celular.
/// Reemplaza a los mocks: se llena con lo que manda AppMovil vía
/// [rutaTandaSync] y permite reportar un pago de vuelta.
class WearNotificacionesState extends ChangeNotifier {
  List<TandaWearItem> _items = [];
  DateTime? _ultimaSync;
  final Set<String> _reportando = {};

  List<TandaWearItem> get items => _items;
  DateTime? get ultimaSync => _ultimaSync;

  bool estaReportando(String pagoId) => _reportando.contains(pagoId);

  /// Empieza a escuchar al celular y le pide los datos más recientes.
  /// Se llama una sola vez, al arrancar la app.
  void iniciar() {
    debugPrint('[WearNotificacionesState] iniciar(): escuchando y pidiendo sync');
    WearBridge.mensajes.listen((mensaje) {
      debugPrint('[WearNotificacionesState] mensaje recibido: ${mensaje.ruta}');
      if (mensaje.ruta != rutaTandaSync) return;
      final payload = TandaSyncPayload.fromJson(mensaje.datos);
      debugPrint('[WearNotificacionesState] sync con ${payload.items.length} item(s)');
      _items = _ordenarPorUrgencia(payload.items);
      _ultimaSync = payload.generadoEn;
      _reportando.clear();
      notifyListeners();
    });

    WearBridge.enviar(rutaSyncSolicitar, const {});
  }

  /// Le avisa al celular que ya se pagó [pagoId]. El item se actualiza solo
  /// cuando llegue el siguiente 'tanda/sync' con el estado confirmado.
  Future<void> reportarPago(String pagoId) async {
    if (_reportando.contains(pagoId)) return;
    _reportando.add(pagoId);
    notifyListeners();
    await WearBridge.enviar(
      rutaPagoReportar,
      PagoReportarPayload(pagoId: pagoId).toJson(),
    );
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
}
