import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  static const TextStyle title = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: AppColors.primaryText,
  );
  
  static const TextStyle body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.secondaryText,
  );
  
  static const TextStyle urgentStatus = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: AppColors.statusPending,
  );
}
