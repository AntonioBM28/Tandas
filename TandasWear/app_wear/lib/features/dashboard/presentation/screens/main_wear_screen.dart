import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../notificaciones/data/mock_notificaciones.dart';
import '../../../notificaciones/presentation/widgets/notificacion_card.dart';
import 'dashboard_screen.dart';

class MainWearScreen extends StatefulWidget {
  const MainWearScreen({super.key});

  @override
  State<MainWearScreen> createState() => _MainWearScreenState();
}

class _MainWearScreenState extends State<MainWearScreen> {
  // viewportFraction < 1.0 da la pista visual de la siguiente página
  final PageController _pageController = PageController(viewportFraction: 0.92);
  int _currentIndex = 0;
  List<NotificacionMock> _sortedNotificaciones = [];

  @override
  void initState() {
    super.initState();
    _sortNotificaciones();
  }

  void _sortNotificaciones() {
    _sortedNotificaciones = List.from(mockNotificaciones);
    _sortedNotificaciones.sort((a, b) {
      final order = {
        TipoNotificacion.teTocaCobrar: 0,
        TipoNotificacion.pagoAtrasado: 1,
        TipoNotificacion.pagoProximo: 2,
        TipoNotificacion.pagoPendiente: 3,
      };
      return order[a.tipo]!.compareTo(order[b.tipo]!);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Total de páginas: 1 (Dashboard) + n (Notificaciones)
    final totalPages = 1 + _sortedNotificaciones.length;

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
                return const DashboardScreen();
              }
              final notificacion = _sortedNotificaciones[index - 1];
              return NotificacionCard(notificacion: notificacion);
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
                  width: _currentIndex == index ? 6 : 4,
                  decoration: BoxDecoration(
                    color: _currentIndex == index
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
