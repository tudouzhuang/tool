import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';
import '../../widgets/tools/dotted_file_drop.dart';

class FileSelectionContainer extends StatelessWidget {
  final String title;
  final String emptyStateText;
  final List<File> selectedFiles;
  final VoidCallback onTap;
  final Function(int) onRemoveFile;
  final bool isMultipleSelection;

  const FileSelectionContainer({
    super.key,
    required this.title,
    required this.emptyStateText,
    required this.selectedFiles,
    required this.onTap,
    required this.onRemoveFile,
    this.isMultipleSelection = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 10,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          // File selection section
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 14, top: 14),
              child: Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          // Dotted file drop zone
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: DottedFileDropZone(
              selectedImages: selectedFiles,
              onTap: onTap,
              onRemoveImage: onRemoveFile,
              emptyStateText: emptyStateText,
              isMultipleSelection: isMultipleSelection,
            ),
          ),
        ],
      ),
    );
  }
}