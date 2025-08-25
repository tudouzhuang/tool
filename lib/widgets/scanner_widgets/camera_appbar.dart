// camera_app_bar.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../../../utils/app_colors.dart';

class CameraAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool isFlashOn;
  final bool isGridVisible;
  final bool showGridIcon; // Add this new parameter
  final VoidCallback onClosePressed;
  final VoidCallback onFlashPressed;
  final VoidCallback onGridPressed;

  const CameraAppBar({
    super.key,
    required this.isFlashOn,
    required this.isGridVisible,
    required this.showGridIcon, // Add to constructor
    required this.onClosePressed,
    required this.onFlashPressed,
    required this.onGridPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.close, color: AppColors.primary),
        onPressed: onClosePressed,
      ),

      actions: [
        IconButton(
          icon: SvgPicture.asset(
            isFlashOn
                ? 'assets/icons/flash_icon.svg'
                : 'assets/icons/no_flash_icon.svg',
            height: 24,
            width: 24,
          ),
          onPressed: onFlashPressed,
        ),
        if (showGridIcon) // Only show grid icon if showGridIcon is true
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: IconButton(
              icon: SvgPicture.asset(
                'assets/icons/grid_icon.svg',
                color: isGridVisible ? AppColors.primary : Colors.grey,
                width: 24,
                height: 24,
              ),
              onPressed: onGridPressed,
            ),
          ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}