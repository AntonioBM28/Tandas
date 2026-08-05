import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../pagos/presentation/providers/pagos_wear_state.dart';
import '../../../notificaciones/presentation/widgets/notificacion_card.dart';
import 'dashboard_screen.dart';

class MainWearScreen extends StatefulWidget {
  final VoidCallback? onCerrarSesion;

  const MainWearScreen({super.key, this.onCerrarSesion});

  @override
  State<MainWearScreen> createState() => _MainWearScreenState();
}

class _MainWearScreenState extends State<MainWearScreen> {
  // viewportFraction < 1.0 da la pista visual de la siguiente página
  final PageController _pageController = PageController(viewportFraction: 0.92);
  int _currentIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<PagosWearState>();
    final items = state.items;
    // Total de páginas: 1 (Dashboard) + n (Notificaciones de pago)
    final totalPages = 1 + items.length;
    final currentIndex = _currentIndex >= totalPages ? totalPages - 1 : _currentIndex;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        alignment: Alignment.center,
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() => _currentIndex = index);
            },
            itemCount: totalPages,
            itemBuilder: (context, index) {
              if (index == 0) {
                return DashboardScreen(onCerrarSesion: widget.onCerrarSesion);
              }
              final item = items[index - 1];
              return NotificacionCard(
                item: item,
                reportando: state.estaReportando(item.pagoId),
                onReportar: () => state.reportarPago(item.pagoId),
              );
            },
          ),

          // Indicador de página (dots)
          Positioned(
            bottom: 12, // Respetando zona segura circular
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(totalPages, (index) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 2.0),
                  height: 6,
                  width: currentIndex == index ? 6 : 4,
                  decoration: BoxDecoration(
                    color: currentIndex == index
                        ? AppColors.primaryText
                        : AppColors.secondaryText.withAlpha(127),
                    shape: BoxShape.circle,
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
