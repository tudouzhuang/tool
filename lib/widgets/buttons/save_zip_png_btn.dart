import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/save_zip_png_service.dart';
import '../../utils/app_colors.dart';

class SaveFileButton extends StatelessWidget {
  final String filePath;  // Changed from File to String path
  final String fileType;
  final String buttonText;
  final double? width;
  final VoidCallback? onSaveCompleted;

  const SaveFileButton({
    super.key,
    required this.filePath,  // Updated parameter
    required this.fileType,
    this.buttonText = 'save',
    this.width,
    this.onSaveCompleted,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? double.infinity,
      height: 48,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              AppColors.gradientStart,
              AppColors.gradientEnd,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: ElevatedButton(
          onPressed: () async {
            await SaveFileService.saveFile(context, File(filePath), fileType);
            if (onSaveCompleted != null) {
              onSaveCompleted!();
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
          ),
          child: Text(
            buttonText.tr,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}