import 'package:flutter/material.dart';
import 'core/theme/app_colors.dart';
import 'features/dashboard/presentation/screens/main_wear_screen.dart';

void main() {
  runApp(const AppWear());
}

class AppWear extends StatelessWidget {
  const AppWear({super.key});

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
      home: const MainWearScreen(),
    );
  }
}
