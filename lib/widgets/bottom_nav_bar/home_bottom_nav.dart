import 'package:flutter/material.dart';
import 'package:toolkit/utils/app_colors.dart';
import '../buttons/scanner_button.dart';
import 'nav_items.dart';

class HomeBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const HomeBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topCenter,
      clipBehavior: Clip.none,
      children: [
        // Bottom Navigation Container
        Container(
          height: 74,
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(36),
              topRight: Radius.circular(36),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: NavBarItem(
                  index: 0,
                  iconPath: 'assets/icons/home_icon.svg',
                  isActive: currentIndex == 0,
                  onTap: onTap,
                ),
              ),
              const Spacer(),
              Expanded(
                child: NavBarItem(
                  index: 2,
                  iconPath: 'assets/icons/folder_icon.svg',
                  isActive: currentIndex == 2,
                  onTap: onTap,
                ),
              ),
            ],
          ),
        ),
        // Center Scanner Button
        Positioned(
          top: -30,
          child: ScannerButton(onTap: () => onTap(1)),
        ),
      ],
    );
  }
}
