import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppSnackBar {
  static void show(
    BuildContext context, {
    required String message,
  }) {
    final snackBar = SnackBar(
      content: Text(
        message,
        style: const TextStyle(
          color: AppColors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: AppColors.primary.withOpacity(0.7),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.only(bottom: 70, right: 20, left: 20),
      elevation: 6,
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}
// AppSnackBar.show(context, message: 'Error saving file: $e');
