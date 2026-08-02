import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';

/// Un mensaje recibido del otro lado del puente (celular <-> reloj).
class WearMessage {
  final String ruta;
  final Map<String, dynamic> datos;

  WearMessage({required this.ruta, required this.datos});
}

/// Puente nativo con la app complementaria (celular o reloj, según en qué
/// proyecto se use) vía la Wear OS Data Layer API. El lado nativo
/// (MainActivity.kt) es simétrico en ambos proyectos: mismo nombre de canal,
/// mismo formato { ruta, datos }.
///
/// No requiere que haya conexión: si Play Services o el dispositivo
/// emparejado no están disponibles, enviar() simplemente no entrega el
/// mensaje en vez de fallar la app.
class WearBridge {
  static const _channel = MethodChannel('com.tandas.wear/mensajes');
  static final _incomingController = StreamController<WearMessage>.broadcast();
  static bool _initialized = false;

  static void _ensureInitialized() {
    if (_initialized) return;
    _initialized = true;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'mensajeRecibido') {
        final args = Map<String, dynamic>.from(call.arguments as Map);
        final ruta = args['ruta'] as String? ?? '';
        final datosRaw = args['datos'] as String? ?? '{}';
        Map<String, dynamic> datos;
        try {
          datos = Map<String, dynamic>.from(jsonDecode(datosRaw) as Map);
        } catch (_) {
          datos = {};
        }
        _incomingController.add(WearMessage(ruta: ruta, datos: datos));
      }
    });
  }

  /// Mensajes que llegan del otro lado. Cada mensaje trae una 'ruta' (para
  /// saber qué tipo de mensaje es) y sus 'datos'.
  static Stream<WearMessage> get mensajes {
    _ensureInitialized();
    return _incomingController.stream;
  }

  /// Envía un mensaje al otro lado, identificado por [ruta] (p.ej.
  /// 'tanda/sync' o 'pago/reportar'), con [datos] como payload.
  static Future<void> enviar(String ruta, Map<String, dynamic> datos) async {
    _ensureInitialized();
    try {
      await _channel.invokeMethod('enviarMensaje', {
        'ruta': ruta,
        'datos': jsonEncode(datos),
      });
    } on PlatformException {
      // Sin Play Services o sin dispositivo conectado: no es un error fatal.
    }
  }
}
