import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/circular_safe_area.dart';

// Mock variables to simulate the 3 states
enum PaymentStatus { pending, late, collect }

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  // Change this variable to test different states:
  // PaymentStatus.pending, PaymentStatus.late, PaymentStatus.collect
  final PaymentStatus currentStatus = PaymentStatus.pending;

  @override
  Widget build(BuildContext context) {
    String mainText;
    Color statusColor;
    String subText;

    switch (currentStatus) {
      case PaymentStatus.late:
        mainText = 'Pago atrasado';
        statusColor = AppColors.statusLate;
        subText = '\$500';
        break;
      case PaymentStatus.collect:
        mainText = '¡Te toca cobrar!';
        statusColor = AppColors.statusCollect;
        subText = '\$5,000 en 3 días';
        break;
      case PaymentStatus.pending:
        mainText = 'Pago en 2 días';
        statusColor = AppColors.statusPending;
        subText = '\$500';
        break;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CircularSafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Icon/Avatar
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: Colors.blueGrey,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Text(
                'A',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(height: 8),
            
            // Context text
            const Text(
              'Tanda Familiar',
              style: AppTextStyles.body,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            
            // Urgent Status
            Text(
              mainText,
              style: AppTextStyles.urgentStatus.copyWith(color: statusColor),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            
            // Amount or details
            Text(
              subText,
              style: AppTextStyles.title,
              textAlign: TextAlign.center,
            ),
            
            const Spacer(),
            
            // Swipe hint
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Desliza',
                  style: AppTextStyles.body.copyWith(
                    fontSize: 10,
                    color: AppColors.secondaryText,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: AppColors.secondaryText,
                  size: 10,
                ),
              ],
            ),
            const SizedBox(height: 16), // Espacio para los dots globales
          ],
        ),
      ),
    );
  }
}
