enum TipoNotificacion {
  teTocaCobrar,
  pagoAtrasado,
  pagoProximo,
  pagoPendiente,
}

class NotificacionMock {
  final String id;
  final TipoNotificacion tipo;
  final String nombreTanda;
  final double monto;
  final String tiempoInfo; // Ej: "hace 3 días", "en 2 días"
  final bool leido;

  const NotificacionMock({
    required this.id,
    required this.tipo,
    required this.nombreTanda,
    required this.monto,
    required this.tiempoInfo,
    this.leido = false,
  });
}

// Lista mock de notificaciones con diferentes estados
final List<NotificacionMock> mockNotificaciones = [
  const NotificacionMock(
    id: '1',
    tipo: TipoNotificacion.pagoAtrasado,
    nombreTanda: 'Tanda Oficina',
    monto: 500.0,
    tiempoInfo: 'hace 3 días',
  ),
  const NotificacionMock(
    id: '2',
    tipo: TipoNotificacion.pagoProximo,
    nombreTanda: 'Tanda Familiar',
    monto: 1000.0,
    tiempoInfo: 'en 2 días',
  ),
  const NotificacionMock(
    id: '3',
    tipo: TipoNotificacion.teTocaCobrar,
    nombreTanda: 'Tanda Amigos',
    monto: 10000.0,
    tiempoInfo: 'en 5 días',
  ),
  const NotificacionMock(
    id: '4',
    tipo: TipoNotificacion.pagoPendiente,
    nombreTanda: 'Tanda Vecinos',
    monto: 250.0,
    tiempoInfo: 'en 10 días',
  ),
  const NotificacionMock(
    id: '5',
    tipo: TipoNotificacion.pagoPendiente,
    nombreTanda: 'Tanda Gimnasio',
    monto: 300.0,
    tiempoInfo: 'en 15 días',
  ),
];
