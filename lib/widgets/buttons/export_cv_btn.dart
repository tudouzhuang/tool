import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/app_colors.dart';

class ExportButton extends StatelessWidget {
  final VoidCallback onExport; // Rename to be more specific

  const ExportButton({super.key, required this.onExport});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      width: 88,
      decoration: BoxDecoration(
        color: AppColors.bgBoxColor,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.30),
            blurRadius: 2,
            offset: const Offset(0, 0),
          )
        ],
      ),
      child: TextButton(
        onPressed: onExport, // Use the renamed callback
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
          foregroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text(
          'export'.tr,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
