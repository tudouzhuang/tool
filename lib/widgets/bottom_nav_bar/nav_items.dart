import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class NavBarItem extends StatelessWidget {
  final int index;
  final String iconPath;
  final bool isActive;
  final Function(int) onTap;

  const NavBarItem({
    super.key,
    required this.index,
    required this.iconPath,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkResponse(
        onTap: () => onTap(index),
        radius: 20,        // Very small ripple radius
        containedInkWell: true,
        // Constrains ripple to container bounds
        highlightShape: BoxShape.circle,
        // Circular highlight effect
        splashColor: const Color(0xFF00B4BE).withOpacity(0.1),
        highlightColor: const Color(0xFF00B4BE).withOpacity(0.05),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: SvgPicture.asset(
            iconPath,
            width: 26,
            height: 26,
            colorFilter: ColorFilter.mode(
              isActive ? const Color(0xFF00B4BE) : Colors.black,
              BlendMode.srcIn,
            ),
          ),
        ),
      ),
    );
  }
}
