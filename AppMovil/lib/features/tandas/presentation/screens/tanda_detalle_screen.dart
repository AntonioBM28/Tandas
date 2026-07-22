import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../domain/models/tanda.dart';
import '../../domain/models/tanda_detalle.dart';
import '../providers/tanda_detalle_provider.dart';

extension StringExtension on String {
  String capitalize() => "${this[0].toUpperCase()}${substring(1)}";
}

class TandaDetalleScreen extends StatefulWidget {
  final String id;
  const TandaDetalleScreen({super.key, required this.id});

  @override
  State<TandaDetalleScreen> createState() => _TandaDetalleScreenState();
}

class _TandaDetalleScreenState extends State<TandaDetalleScreen> {
  final _storage = SecureStorageService();

  @override
  void initState() {
    super.initState();
    _cargarDetalle();
  }

  void _cargarDetalle() async {
    final userId = await _storage.getUserId();
    if (userId != null && mounted) {
      context.read<TandaDetalleProvider>().fetchDetalle(widget.id, userId);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Color _getEstadoColor(TandaEstado estado) {
    switch (estado) {
      case TandaEstado.armando: return Colors.amber.shade700;
      case TandaEstado.activa: return Colors.green.shade600;
      case TandaEstado.finalizada: return Colors.grey.shade600;
      case TandaEstado.cancelada: return Colors.red.shade600;
    }
  }

  Color _getPagoColor(PagoEstado estado) {
    switch (estado) {
      case PagoEstado.pendiente: return Colors.amber.shade700;
      case PagoEstado.pagado: return Colors.green.shade600;
      case PagoEstado.atrasado: return Colors.red.shade600;
    }
  }

  String _formatDate(DateTime d) {
    return "${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}";
  }

  Widget _buildInfoCol(String label, String value, ThemeData theme) {
    return Column(
      children: [
        Text(label, style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        const SizedBox(height: 4),
        Text(value, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildPagoRow(Pago pago, bool isAdmin, ThemeData theme) {
    final color = _getPagoColor(pago.estado);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            pago.estado == PagoEstado.pagado ? Icons.check_circle : (pago.estado == PagoEstado.pendiente ? Icons.schedule : Icons.error),
            size: 20,
            color: color,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(pago.nombreMiembro, style: theme.textTheme.bodyLarge)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Text(pago.estado.name.toUpperCase(), style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold)),
          ),
          if (isAdmin && pago.estado != PagoEstado.pagado) ...[
            const SizedBox(width: 8),
            InkWell(
              onTap: () => _showSnackBar('Marcar como pagado - Próximamente'),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: theme.colorScheme.primaryContainer, shape: BoxShape.circle),
                child: Icon(Icons.done_all, size: 16, color: theme.colorScheme.onPrimaryContainer),
              ),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildCicloActualSection(Ciclo ciclo, bool isAdmin, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Ciclo Actual #${ciclo.numeroCiclo}', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Card(
          elevation: 2,
          shadowColor: Colors.black12,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Beneficiario', style: theme.textTheme.labelMedium),
                        Text(ciclo.nombreBeneficiario, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Bote Total', style: theme.textTheme.labelMedium),
                        Text('\$${ciclo.montoTotalCiclo.toStringAsFixed(2)}', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.green.shade700)),
                      ],
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(),
                ),
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 16, color: theme.colorScheme.error),
                    const SizedBox(width: 8),
                    Text('Límite de pago: ${_formatDate(ciclo.fechaLimite)}', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 16),
                if (ciclo.pagos.isNotEmpty) ...[
                  Text('Estado de pagos', style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 8),
                  ...ciclo.pagos.map((p) => _buildPagoRow(p, isAdmin, theme)),
                ]
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMiembroTile(Miembro m, bool isAdmin, ThemeData theme) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.secondaryContainer,
        child: Text(m.nombre.substring(0, 1).toUpperCase(), style: TextStyle(color: theme.colorScheme.onSecondaryContainer)),
      ),
      title: Text(m.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: m.turnoOrden != null ? Text('Turno #${m.turnoOrden}') : const Text('Sin turno asignado'),
      trailing: m.rol == TandaRol.admin 
        ? Chip(
            label: const Text('Admin', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
            backgroundColor: theme.colorScheme.primaryContainer,
            side: BorderSide.none,
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
          ) 
        : (isAdmin ? IconButton(icon: const Icon(Icons.more_vert), onPressed: () => _showSnackBar('Gestionar miembro - Próximamente')) : null),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TandaDetalleProvider>();
    final theme = Theme.of(context);

    if (provider.isLoading || provider.detalle == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final detalle = provider.detalle!;
    final tanda = detalle.tandaBase;
    final isAdmin = tanda.rolDelUsuario == TandaRol.admin;
    final isActiva = tanda.estado == TandaEstado.activa;
    final isArmando = tanda.estado == TandaEstado.armando;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tanda.nombre, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Container(
              margin: const EdgeInsets.only(top: 2),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _getEstadoColor(tanda.estado).withOpacity(0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                tanda.estado.name.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  color: _getEstadoColor(tanda.estado),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        actions: [
          if (isAdmin)
            PopupMenuButton<String>(
              onSelected: (val) => _showSnackBar('$val tanda - Próximamente'),
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'Editar', child: Text('Editar tanda')),
                const PopupMenuItem(value: 'Cancelar', child: Text('Cancelar tanda')),
              ],
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _cargarDetalle(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                elevation: 0,
                color: theme.colorScheme.surfaceVariant.withOpacity(0.4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildInfoCol('Aportación', '\$${tanda.montoAportacion.toStringAsFixed(0)}', theme),
                      _buildInfoCol('Frecuencia', tanda.frecuencia.displayName.capitalize(), theme),
                      _buildInfoCol('Miembros', '${tanda.numMiembrosActuales}/${tanda.numParticipantes}', theme),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              if (isArmando && isAdmin) ...[
                Text('Gestión de Tanda', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => context.push('/tandas/${widget.id}/miembros/agregar').then((_) => _cargarDetalle()),
                        icon: const Icon(Icons.person_add),
                        label: const Text('Invitar'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => _showSnackBar('Iniciar tanda - Próximamente'),
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Iniciar'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
              
              if (isActiva && detalle.cicloActual != null) ...[
                _buildCicloActualSection(detalle.cicloActual!, isAdmin, theme),
                const SizedBox(height: 24),
              ],

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Miembros y Turnos', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  if (isAdmin)
                    TextButton(
                      onPressed: () => context.push('/tandas/${widget.id}/miembros').then((_) => _cargarDetalle()),
                      child: const Text('Gestionar'),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              if (detalle.miembros.isEmpty) 
                const Text('No hay miembros en esta tanda aún.'),
              ...detalle.miembros.map((m) => _buildMiembroTile(m, isAdmin, theme)),
            ],
          ),
        ),
      ),
    );
  }
}
