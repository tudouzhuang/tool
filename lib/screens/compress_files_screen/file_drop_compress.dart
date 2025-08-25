import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';
import 'package:path/path.dart' as path;

import '../../utils/app_colors.dart';

class DottedFileDropZoneCompress extends StatelessWidget {
  final List<File> selectedFiles;
  final VoidCallback onTap;
  final Function(int) onRemoveFile;

  const DottedFileDropZoneCompress({
    super.key,
    required this.selectedFiles,
    required this.onTap,
    required this.onRemoveFile,
  });

  IconData _getFileIcon(String extension) {
    switch (extension.toLowerCase()) {
      case '.pdf':
        return Icons.picture_as_pdf;
      case '.doc':
      case '.docx':
        return Icons.description;
      case '.pptx':
      case '.ppt':
        return Icons.file_present;
      case '.jpeg':
      case '.jpg':
      case '.png':
        return Icons.image;
      default:
        return Icons.insert_drive_file;
    }
  }

  String _getFileName(String filePath) {
    return path.basename(filePath);
  }

  @override
  Widget build(BuildContext context) {
    return DottedBorder(
      color: AppColors.primary,
      strokeWidth: 1.5,
      dashPattern: const [5, 4],
      borderType: BorderType.RRect,
      radius: const Radius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: double.infinity,
          constraints: BoxConstraints(
            minHeight: 128,
            maxHeight: (selectedFiles.isNotEmpty) ? 300 : 128,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: const Color(0xFF00BCD4).withOpacity(0.05),
          ),
          child: (selectedFiles.isNotEmpty)
              ? SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: selectedFiles.asMap().entries.map((entry) {
                      final index = entry.key;
                      final file = entry.value;
                      final extension = path.extension(file.path);

                      return Stack(
                        children: [
                          SizedBox(
                            width: 100,
                            height: 100,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _getFileIcon(extension),
                                  size: 40,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(height: 6),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  child: Text(
                                    _getFileName(file.path),
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w400,
                                    ),
                                    maxLines: 2,
                                    textAlign: TextAlign.center,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Positioned(
                            top: 5,
                            right: 5,
                            child: GestureDetector(
                              onTap: () => onRemoveFile(index),
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  size: 16,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          )
              : Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 8),
              SvgPicture.asset(
                'assets/icons/upload_file_icon.svg',
                height: 28,
                width: 36,
              ),
              const SizedBox(height: 8),
              Text(
                'drag_drop'.tr,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: Colors.grey,
                  fontSize: 10,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }}