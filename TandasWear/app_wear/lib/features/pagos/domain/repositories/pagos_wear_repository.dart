import '../../../../core/network/dio_client.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../core/wear/wear_protocol.dart';

/// El reloj ahora habla directo con el backend (ya no depende de que el
/// celular esté cerca ni prendido). Misma lógica que WearSyncService del
/// celular: tandas activas -> ciclo actual -> pagos propios pendientes.
class PagosWearRepository {
  final DioClient _dioClient;
  final SecureStorageService _storageService;

  PagosWearRepository(this._dioClient, this._storageService);

  Future<List<TandaWearItem>> obtenerPagosPendientes() async {
    final userId = await _storageService.getUserId();
    if (userId == null) return [];

    final tandasResponse = await _dioClient.dio.get('/tandas/mis-tandas');
    final tandas = (tandasResponse.data as List).cast<Map<String, dynamic>>();
    final activas = tandas.where((t) => t['estado'] == 'ACTIVA');

    final items = <TandaWearItem>[];
    for (final tanda in activas) {
      try {
        final detalleResponse = await _dioClient.dio.get('/tandas/${tanda['id']}');
        final detalle = detalleResponse.data as Map<String, dynamic>;
        final ciclos = (detalle['ciclos'] as List?) ?? [];
        if (ciclos.isEmpty) continue;

        final ciclo = ciclos.last as Map<String, dynamic>;
        final fechaLimite = ciclo['fechaLimite'] != null
            ? DateTime.tryParse(ciclo['fechaLimite'] as String)
            : null;
        final pagos = (ciclo['pagos'] as List?) ?? [];

        for (final p in pagos) {
          final pago = p as Map<String, dynamic>;
          final miembroTanda = pago['miembroTanda'] as Map<String, dynamic>?;
          final usuario = miembroTanda?['usuario'] as Map<String, dynamic>?;
          if (usuario == null || usuario['id'] != userId) continue;

          final estado = pago['estado'] as String? ?? 'PENDIENTE';
          if (estado == 'PAGADO') continue;

          items.add(TandaWearItem(
            id: pago['id'] as String,
            tipo: _tipoParaPago(estado, fechaLimite),
            tandaId: tanda['id'] as String,
            nombreTanda: tanda['nombre'] as String? ?? '',
            monto: double.tryParse(pago['monto']?.toString() ?? '0') ?? 0.0,
            fechaLimite: fechaLimite,
            pagoId: pago['id'] as String,
          ));
        }
      } catch (_) {
        // Si una tanda falla al cargar su detalle, seguimos con las demás.
        continue;
      }
    }
    return items;
  }

  Future<void> reportarPago(String pagoId) async {
    await _dioClient.dio.patch('/pagos/$pagoId', data: {'estado': 'REPORTADO'});
  }

  TandaWearTipo _tipoParaPago(String estado, DateTime? fechaLimite) {
    if (estado == 'ATRASADO') return TandaWearTipo.pagoAtrasado;
    if (estado == 'REPORTADO') return TandaWearTipo.pagoReportado;
    if (fechaLimite == null) return TandaWearTipo.pagoPendiente;
    final dias = fechaLimite.difference(DateTime.now()).inDays;
    return dias <= 2 ? TandaWearTipo.pagoProximo : TandaWearTipo.pagoPendiente;
  }
}
