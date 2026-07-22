import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/circular_safe_area.dart';
import '../../data/mock_notificaciones.dart';

class NotificacionCard extends StatefulWidget {
  final NotificacionMock notificacion;

  const NotificacionCard({super.key, required this.notificacion});

  @override
  State<NotificacionCard> createState() => _NotificacionCardState();
}

class _NotificacionCardState extends State<NotificacionCard> with SingleTickerProviderStateMixin {
  bool _isPressed = false;

  void _showToast(BuildContext context, String message) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: 24,
        left: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.statusOk, width: 1),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle, color: AppColors.statusOk, size: 16),
                const SizedBox(width: 8),
                Text(
                  message,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);
    Future.delayed(const Duration(seconds: 2), () {
      overlayEntry.remove();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Configuración según el tipo
    Color accentColor;
    IconData iconData;
    String titulo;
    bool showCheckBtn = false;

    switch (widget.notificacion.tipo) {
      case TipoNotificacion.teTocaCobrar:
        accentColor = AppColors.statusCollect;
        iconData = Icons.emoji_events; // Trofeo o regalo
        titulo = '¡Te toca cobrar!';
        break;
      case TipoNotificacion.pagoAtrasado:
        accentColor = AppColors.statusLate;
        iconData = Icons.warning_amber_rounded;
        titulo = 'Pago atrasado';
        showCheckBtn = true;
        break;
      case TipoNotificacion.pagoProximo:
        accentColor = AppColors.statusPending;
        iconData = Icons.access_time;
        titulo = 'Pago próximo';
        break;
      case TipoNotificacion.pagoPendiente:
        accentColor = Colors.blueGrey;
        iconData = Icons.calendar_today;
        titulo = 'Pago pendiente';
        showCheckBtn = true;
        break;
    }

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.scale(
            scaleX: 0.8 + (0.2 * value),
            scaleY: 0.8 + (0.2 * value),
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: () {
          // Feedback de tap (solo UI)
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          transform: Matrix4.identity()..scale(_isPressed ? 0.95 : 1.0),
          transformAlignment: Alignment.center,
          child: Scaffold(
            backgroundColor: AppColors.background,
            body: CircularSafeArea(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(iconData, color: accentColor, size: 28),
                      const SizedBox(height: 6),
                      Text(
                        titulo,
                        style: widget.notificacion.tipo == TipoNotificacion.teTocaCobrar
                            ? AppTextStyles.title.copyWith(color: accentColor, fontSize: 18)
                            : AppTextStyles.body.copyWith(color: accentColor, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '\$${widget.notificacion.monto.toStringAsFixed(0)}',
                        style: widget.notificacion.tipo == TipoNotificacion.teTocaCobrar
                            ? AppTextStyles.title.copyWith(fontSize: 24)
                            : AppTextStyles.title,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.notificacion.nombreTanda,
                        style: AppTextStyles.body.copyWith(fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        widget.notificacion.tiempoInfo,
                        style: AppTextStyles.body.copyWith(fontSize: 12, color: Colors.white70),
                      ),
                      // Espacio al fondo para no tapar los dots
                      const SizedBox(height: 16),
                    ],
                  ),
                  if (showCheckBtn)
                    Positioned(
                      right: 0,
                      bottom: 16,
                      child: GestureDetector(
                        onTap: () => _showToast(context, 'Marcado como pagado'),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.statusOk.withAlpha(51), // approx 0.2 opacity
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.statusOk, width: 2),
                          ),
                          child: const Icon(Icons.check, color: AppColors.statusOk, size: 20),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
