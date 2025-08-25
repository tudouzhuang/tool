import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/app_colors.dart';

class AddAnotherButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final double height;
  final double width;
  final IconData? icon;

  const AddAnotherButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.height = 48,
    this.width = 278,
    this.icon = Icons.add_circle_outline,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(

        height: height,
        width: width,
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.30),
              blurRadius: 2,
              offset: const Offset(0, 0),
            ),
          ],
          color: AppColors.bgBoxColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: TextButton.icon(
          onPressed: onPressed,
          icon: Icon(
            icon,
            color: Colors.black,
            size: 18,
          ),
          label: Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
        ),
      ),
    );
  }
}