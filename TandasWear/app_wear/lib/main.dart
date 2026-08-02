import 'package:flutter/material.dart';
import 'core/theme/app_colors.dart';
import 'core/wear/wear_notificaciones_state.dart';
import 'features/dashboard/presentation/screens/main_wear_screen.dart';

void main() {
  final wearState = WearNotificacionesState();
  wearState.iniciar();
  runApp(AppWear(wearState: wearState));
}

class AppWear extends StatelessWidget {
  final WearNotificacionesState wearState;

  const AppWear({super.key, required this.wearState});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AppWear Tandas',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.statusOk,
          secondary: AppColors.statusPending,
          surface: AppColors.background,
        ),
        useMaterial3: true,
      ),
      home: MainWearScreen(state: wearState),
    );
  }
}
