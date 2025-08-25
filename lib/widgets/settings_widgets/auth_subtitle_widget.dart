import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/app_colors.dart';

class AuthSubtitleWidget extends StatelessWidget {
  final String normalText;
  final String highlightedText;

  const AuthSubtitleWidget({
    super.key,
    required this.normalText,
    required this.highlightedText,
  });

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: AppColors.black,
          height: 1.4,
        ),
        children: [
          TextSpan(text: normalText),
          TextSpan(
            text: highlightedText,
            style: GoogleFonts.inter(
              color: AppColors.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}