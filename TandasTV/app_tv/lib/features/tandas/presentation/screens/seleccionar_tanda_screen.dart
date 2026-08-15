import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/models/tanda_resumen.dart';
import '../providers/seleccion_tandas_state.dart';
import 'pantalla_publica_screen.dart';

/// Pantalla "home" de la TV una vez vinculada: elegir con el control remoto
/// cuál tanda mostrar en grande.
class SeleccionarTandaScreen extends StatefulWidget {
  final VoidCallback onCerrarSesion;

  const SeleccionarTandaScreen({super.key, required this.onCerrarSesion});

  @override
  State<SeleccionarTandaScreen> createState() => _SeleccionarTandaScreenState();
}

class _SeleccionarTandaScreenState extends State<SeleccionarTandaScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SeleccionTandasState>().cargar();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<SeleccionTandasState>();

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
                  const Expanded(
                    child: Text(
                      'Elige una tanda',
                      style: TextStyle(
                        color: AppColors.primaryText,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: widget.onCerrarSesion,
                    icon: const Icon(Icons.logout, color: AppColors.secondaryText),
                    label: const Text(
                      'Cambiar cuenta',
                      style: TextStyle(color: AppColors.secondaryText, fontSize: 18),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(child: _buildBody(context, state)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, SeleccionTandasState state) {
    if (state.cargando && state.tandas.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (state.error != null && state.tandas.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(state.error!, style: const TextStyle(color: AppColors.statusLate, fontSize: 20)),
            const SizedBox(height: 16),
            TextButton(
              autofocus: true,
              onPressed: () => context.read<SeleccionTandasState>().cargar(),
              child: const Text('Reintentar', style: TextStyle(fontSize: 20)),
            ),
          ],
        ),
      );
    }
    if (state.tandas.isEmpty) {
      return const Center(
        child: Text(
          'Todavía no perteneces a ninguna tanda.',
          style: TextStyle(color: AppColors.secondaryText, fontSize: 20),
        ),
      );
    }

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 420,
        mainAxisExtent: 140,
        crossAxisSpacing: 24,
        mainAxisSpacing: 24,
      ),
      itemCount: state.tandas.length,
      itemBuilder: (context, index) {
        final tanda = state.tandas[index];
        return _TandaCard(
          tanda: tanda,
          autofocus: index == 0,
          onSelect: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => PantallaPublicaScreen(tandaId: tanda.id, nombreTanda: tanda.nombre)),
          ),
        );
      },
    );
  }
}

class _TandaCard extends StatefulWidget {
  final TandaResumen tanda;
  final bool autofocus;
  final VoidCallback onSelect;

  const _TandaCard({required this.tanda, required this.autofocus, required this.onSelect});

  @override
  State<_TandaCard> createState() => _TandaCardState();
}

class _TandaCardState extends State<_TandaCard> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final tanda = widget.tanda;
    return Material(
      color: _focused ? AppColors.primary : AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        autofocus: widget.autofocus,
        borderRadius: BorderRadius.circular(16),
        onFocusChange: (focused) => setState(() => _focused = focused),
        onTap: widget.onSelect,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                tanda.nombre,
                style: TextStyle(
                  color: _focused ? Colors.black : AppColors.primaryText,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              Row(
                children: [
                  Icon(Icons.group_outlined, size: 18, color: _focused ? Colors.black87 : AppColors.secondaryText),
                  const SizedBox(width: 6),
                  Text(
                    '${tanda.numMiembrosActuales}/${tanda.numParticipantes} miembros',
                    style: TextStyle(color: _focused ? Colors.black87 : AppColors.secondaryText, fontSize: 15),
                  ),
                ],
              ),
              Text(
                tanda.estado,
                style: TextStyle(
                  color: _focused ? Colors.black87 : AppColors.secondaryText,
                  fontSize: 13,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
