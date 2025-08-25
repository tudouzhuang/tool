import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../../screens/scanner_screens/scanner_screen.dart';
import '../../utils/app_colors.dart';

class ScannerButton extends StatelessWidget {
  final VoidCallback onTap;

  const ScannerButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const ScannerScreen()),
        );
      },
      child: Container(
        height: 90,
        width: 90,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Center(
          child: Container(
            height: 70,
            width: 70,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.topRight,
                colors: [
                  AppColors.gradientStart,
                  AppColors.gradientEnd,
                ],
              ),
            ),
            child: Center(
              child: SvgPicture.asset(
                'assets/icons/scan_icon.svg',
                width: 30,
                height: 30,
                colorFilter: const ColorFilter.mode(
                  Colors.white,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}