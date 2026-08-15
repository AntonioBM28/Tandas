import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/models/pantalla_publica.dart';
import '../providers/pantalla_publica_state.dart';

const _meses = [
  'ene', 'feb', 'mar', 'abr', 'may', 'jun',
  'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
];

String _formatFecha(DateTime fecha) => '${fecha.day} de ${_meses[fecha.month - 1]} de ${fecha.year}';

/// La pantalla que se queda proyectada durante la reunión: ciclo vigente,
/// quién ya pagó y a quién le toca cobrar. Se refresca sola.
class PantallaPublicaScreen extends StatefulWidget {
  final String tandaId;
  final String nombreTanda;

  const PantallaPublicaScreen({super.key, required this.tandaId, required this.nombreTanda});

  @override
  State<PantallaPublicaScreen> createState() => _PantallaPublicaScreenState();
}

class _PantallaPublicaScreenState extends State<PantallaPublicaScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PantallaPublicaState>().iniciar(widget.tandaId);
    });
  }

  @override
  void dispose() {
    context.read<PantallaPublicaState>().detener();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<PantallaPublicaState>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    autofocus: true,
                    icon: const Icon(Icons.arrow_back, color: AppColors.primaryText, size: 28),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.nombreTanda,
                      style: const TextStyle(
                        color: AppColors.primaryText,
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (state.cargando)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.secondaryText),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(child: _buildBody(state)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(PantallaPublicaState state) {
    if (state.cargando && state.data == null) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (state.error != null && state.data == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(state.error!, style: const TextStyle(color: AppColors.statusLate, fontSize: 20)),
            const SizedBox(height: 16),
            TextButton(
              autofocus: true,
              onPressed: () => context.read<PantallaPublicaState>().refrescar(),
              child: const Text('Reintentar', style: TextStyle(fontSize: 20)),
            ),
          ],
        ),
      );
    }

    final data = state.data;
    if (data == null) return const SizedBox.shrink();

    final ciclo = data.cicloActual;
    if (ciclo == null) {
      return Center(
        child: Text(
          data.tanda.estado == 'ARMANDO'
              ? 'Esta tanda todavía se está armando: no hay ningún ciclo activo.'
              : 'Esta tanda no tiene un ciclo activo en este momento.',
          style: const TextStyle(color: AppColors.secondaryText, fontSize: 22),
          textAlign: TextAlign.center,
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CicloHeader(ciclo: ciclo),
          const SizedBox(height: 32),
          _ResumenRow(resumen: ciclo.resumen),
          const SizedBox(height: 32),
          Text(
            'Pagos de este ciclo',
            style: const TextStyle(color: AppColors.primaryText, fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _PagosGrid(pagos: ciclo.pagos),
        ],
      ),
    );
  }
}

class _CicloHeader extends StatelessWidget {
  final CicloPublico ciclo;
  const _CicloHeader({required this.ciclo});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ciclo ${ciclo.numeroCiclo}',
                  style: const TextStyle(color: AppColors.secondaryText, fontSize: 18),
                ),
                const SizedBox(height: 4),
                Text(
                  'Le toca a ${ciclo.beneficiario.nombre}',
                  style: const TextStyle(
                    color: AppColors.primaryText,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Fecha límite: ${_formatFecha(ciclo.fechaLimite)}',
                  style: const TextStyle(color: AppColors.secondaryText, fontSize: 18),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text('Bote total', style: TextStyle(color: AppColors.secondaryText, fontSize: 16)),
              const SizedBox(height: 4),
              Text(
                '\$${ciclo.montoTotalCiclo.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ResumenRow extends StatelessWidget {
  final ResumenPagos resumen;
  const _ResumenRow({required this.resumen});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _ResumenChip(label: 'Pagados', valor: resumen.pagados, color: AppColors.statusOk),
        const SizedBox(width: 16),
        _ResumenChip(label: 'Reportados', valor: resumen.reportados, color: AppColors.statusReported),
        const SizedBox(width: 16),
        _ResumenChip(label: 'Pendientes', valor: resumen.pendientes, color: AppColors.statusPending),
        const SizedBox(width: 16),
        _ResumenChip(label: 'Atrasados', valor: resumen.atrasados, color: AppColors.statusLate),
      ],
    );
  }
}

class _ResumenChip extends StatelessWidget {
  final String label;
  final int valor;
  final Color color;
  const _ResumenChip({required this.label, required this.valor, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border(left: BorderSide(color: color, width: 5)),
        ),
        child: Column(
          children: [
            Text('$valor', style: TextStyle(color: color, fontSize: 26, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(color: AppColors.secondaryText, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}

class _PagosGrid extends StatelessWidget {
  final List<PagoPublico> pagos;
  const _PagosGrid({required this.pagos});

  @override
  Widget build(BuildContext context) {
    if (pagos.isEmpty) {
      return const Text(
        'Nadie tiene un pago pendiente en este ciclo (el beneficiario no aporta su propia parte).',
        style: TextStyle(color: AppColors.secondaryText, fontSize: 16),
      );
    }
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 360,
        mainAxisExtent: 72,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: pagos.length,
      itemBuilder: (context, index) => _PagoTile(pago: pagos[index]),
    );
  }
}

class _PagoTile extends StatelessWidget {
  final PagoPublico pago;
  const _PagoTile({required this.pago});

  Color get _color {
    switch (pago.estado) {
      case 'PAGADO':
        return AppColors.statusOk;
      case 'REPORTADO':
        return AppColors.statusReported;
      case 'ATRASADO':
        return AppColors.statusLate;
      default:
        return AppColors.statusPending;
    }
  }

  String get _label {
    switch (pago.estado) {
      case 'PAGADO':
        return 'Pagado';
      case 'REPORTADO':
        return 'Reportado';
      case 'ATRASADO':
        return 'Atrasado';
      default:
        return 'Pendiente';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(width: 12, height: 12, decoration: BoxDecoration(color: _color, shape: BoxShape.circle)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              pago.nombre,
              style: const TextStyle(color: AppColors.primaryText, fontSize: 16, fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(_label, style: TextStyle(color: _color, fontSize: 13)),
        ],
      ),
    );
  }
}
