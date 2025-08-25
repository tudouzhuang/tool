import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:toolkit/utils/app_colors.dart';

class ToolItem extends StatelessWidget {
  final String icon;
  final String name;
  final VoidCallback onTap;

  const ToolItem({
    super.key,
    required this.icon,
    required this.name,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: SizedBox(
          width: 80, // Slightly increased width
          child: Column(
            mainAxisSize: MainAxisSize.min, // Use minimum space needed
            children: [
              Container(
                width: 78,
                height: 78,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.16),
                      blurRadius: 2,
                    ),
                  ],
                ),
                child: Center(
                  child: SvgPicture.asset(
                    icon,
                    width: 30,
                    height: 34,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 32, // Fixed height for text area
                child: Text(
                  name,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}