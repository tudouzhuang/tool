import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../utils/app_colors.dart';

class FileSelectionSection extends StatefulWidget {
  final String sectionTitle;
  final VoidCallback onSelectFiles;
  final VoidCallback? onScanNew;
  final String? selectedFileName;

  const FileSelectionSection({
    super.key,
    required this.sectionTitle,
    required this.onSelectFiles,
    this.onScanNew,
    this.selectedFileName,
  });

  @override
  State<FileSelectionSection> createState() => _FileSelectionSectionState();
}

class _FileSelectionSectionState extends State<FileSelectionSection> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.sectionTitle,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 6),
          // Container with rounded corners for both buttons
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.primary),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  // Select File button
                  Expanded(
                    child: InkWell(
                      onTap: widget.onSelectFiles,
                      child: Padding(
                        padding:
                            const EdgeInsets.only(top: 4, left: 4, bottom: 4),
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF00A3A3),
                            // Teal color from Figma
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: Center(
                            child: Text(
                              'select_file'.tr,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Scan New button
                  if (widget.onScanNew != null)
                    Expanded(
                      child: InkWell(
                        onTap: widget.onScanNew,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.only(
                              topRight: Radius.circular(7),
                              bottomRight: Radius.circular(7),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              'scan_new'.tr,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: const Color(
                                    0xFF00A3A3), // Teal color to match the theme
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Selected file display
          if (widget.selectedFileName != null) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                widget.selectedFileName!,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
