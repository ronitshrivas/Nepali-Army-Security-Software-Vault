import 'package:flutter/material.dart';
import 'theme.dart';

/// Maps backend enum strings to consistent status colours across the app.
class StatusColors {
  static Color severity(String? s) {
    switch (s?.toLowerCase()) {
      case 'critical':
        return AppColors.danger;
      case 'high':
        return const Color(0xFFE0662B);
      case 'medium':
        return AppColors.warning;
      case 'low':
        return AppColors.info;
      case 'info':
        return AppColors.neutral;
      default:
        return AppColors.neutral;
    }
  }

  static Color alertStatus(String? s) {
    switch (s?.toLowerCase()) {
      case 'open':
        return AppColors.danger;
      case 'acknowledged':
        return AppColors.warning;
      case 'resolved':
        return AppColors.success;
      default:
        return AppColors.neutral;
    }
  }

  static Color deviceStatus(String? s) {
    switch (s?.toLowerCase()) {
      case 'active':
        return AppColors.success;
      case 'lost':
        return AppColors.danger;
      case 'retired':
        return AppColors.neutral;
      default:
        return AppColors.neutral;
    }
  }
}
