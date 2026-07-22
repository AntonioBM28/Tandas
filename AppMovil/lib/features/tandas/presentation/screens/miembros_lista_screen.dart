import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../domain/models/tanda.dart';
import '../providers/tanda_detalle_provider.dart';

class MiembrosListaScreen extends StatelessWidget {
  final String id;
  const MiembrosListaScreen({super.key, required this.id});

  void _removerMiembro(BuildContext context, String miembroId, String nombreMiembro) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Quitar miembro'),
        content: Text('¿Seguro que deseas quitar a $nombreMiembro de la tanda?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final provider = context.read<TandaDetalleProvider>();
              final success = await provider.quitarMiembro(id, miembroId);
              
              if (context.mounted) {
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Miembro removido exitosamente'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(provider.errorMessage ?? 'Error al quitar miembro'),
                      backgroundColor: Theme.of(context).colorScheme.error,
                    ),
                  );
                }
              }
            },
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TandaDetalleProvider>();
    final detalle = provider.detalle;
    final theme = Theme.of(context);

    if (provider.isLoading && detalle == null) {
      return Scaffold(appBar: AppBar(), body: const Center(child: CircularProgressIndicator()));
    }

    if (detalle == null) {
      return Scaffold(appBar: AppBar(), body: const Center(child: Text('Tanda no encontrada')));
    }

    final tanda = detalle.tandaBase;
    final isAdmin = tanda.rolDelUsuario == TandaRol.admin;
    final miembros = detalle.miembros;

    return Scaffold(
      appBar: AppBar(
        title: Text('Miembros (${miembros.length}/${tanda.numParticipantes})'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Stack(
        children: [
          ListView.builder(
            padding: const EdgeInsets.only(bottom: 80), 
            itemCount: miembros.length,
            itemBuilder: (context, index) {
              final miembro = miembros[index];
              final isCurrentUserAdmin = miembro.rol == TandaRol.admin;
              
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                elevation: 0,
                color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isCurrentUserAdmin ? theme.colorScheme.primaryContainer : theme.colorScheme.secondaryContainer,
                    child: Text(
                      miembro.nombre.isNotEmpty ? miembro.nombre.substring(0, 1).toUpperCase() : '?',
                      style: TextStyle(
                        color: isCurrentUserAdmin ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          miembro.nombre,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isCurrentUserAdmin) ...[
                        const SizedBox(width: 4),
                        Icon(Icons.star, size: 16, color: theme.colorScheme.primary),
                      ]
                    ],
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: miembro.turnoOrden != null ? theme.colorScheme.primary.withOpacity(0.1) : Colors.amber.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          miembro.turnoOrden != null ? 'Turno #${miembro.turnoOrden}' : 'Sin turno asignado',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: miembro.turnoOrden != null ? theme.colorScheme.primary : Colors.amber.shade800,
                          ),
                        ),
                      ),
                    ),
                  ),
                  trailing: (isAdmin && !isCurrentUserAdmin)
                      ? IconButton(
                          icon: const Icon(Icons.person_remove),
                          color: theme.colorScheme.error,
                          onPressed: () => _removerMiembro(context, miembro.id, miembro.nombre),
                        )
                      : null,
                ),
              );
            },
          ),
          if (provider.isLoading)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/tandas/$id/miembros/agregar'),
              icon: const Icon(Icons.person_add),
              label: const Text('Agregar miembro'),
            )
          : null,
    );
  }
}
