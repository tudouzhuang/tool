import 'package:flutter/material.dart';
import 'package:toolkit/utils/app_colors.dart';

class GradientBackgroundWidget extends StatelessWidget {
  final Widget child;

  const GradientBackgroundWidget({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.topRight,
          colors: [
            AppColors.gradientStart,
            AppColors.gradientEnd,
          ],
        ),
      ),
      child: child,
    );
  }
}
