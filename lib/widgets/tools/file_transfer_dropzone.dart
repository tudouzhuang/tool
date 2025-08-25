import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path/path.dart' as path;
import '../../models/file_model.dart';
import '../../utils/app_colors.dart';

class FileTransferDropZone extends StatelessWidget {
  final FileModel? selectedFile;
  final VoidCallback onTap;
  final VoidCallback onRemoveFile;
  final String emptyStateText;
  final bool isEmpty;

  const FileTransferDropZone({
    super.key,
    required this.selectedFile,
    required this.onTap,
    required this.onRemoveFile,
    this.emptyStateText = 'Generate QR Code',
    this.isEmpty = false,
  });

  @override
  Widget build(BuildContext context) {
    final showEmptyState = isEmpty || selectedFile == null;

    return InkWell(
      onTap: onTap,
      child: DottedBorder(
        color: AppColors.primary,
        strokeWidth: 1.5,
        dashPattern: const [5, 4],
        borderType: BorderType.RRect,
        radius: const Radius.circular(8),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(
            minHeight: 100,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: const Color(0xFF00BCD4).withOpacity(0.05),
          ),
          child: showEmptyState
              ? Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(
                'assets/images/red_qr_code.svg',
                height: 30,
                width: 30,
              ),
              const SizedBox(height: 8),
              Text(
                emptyStateText,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: Colors.grey,
                  fontSize: 10,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          )
              : Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildFileItem(selectedFile!),
          ),
        ),
      ),
    );
  }

  Widget _buildFileItem(FileModel file) {
    final fileExtension = path.extension(file.name).toLowerCase();

    return Stack(
      clipBehavior: Clip.none, // This allows children to overflow
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: _getFileTypeColor(fileExtension),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Icon(
                    _getFileTypeIcon(fileExtension),
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      file.name,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      file.size,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              // Add invisible spacer to balance layout
              const SizedBox(width: 20),
            ],
          ),
        ),
        Positioned(
          top: -6,
          right: -8,
          child: GestureDetector(
            onTap: onRemoveFile,
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: Colors.grey[350],
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 1.5,
                ),
              ),
              child: const Icon(
                Icons.close,
                size: 12,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Color _getFileTypeColor(String extension) {
    switch (extension) {
      case '.pdf':
        return Colors.red;
      case '.doc':
      case '.docx':
        return Colors.blue;
      case '.txt':
        return Colors.grey;
      case '.jpg':
      case '.jpeg':
      case '.png':
        return Colors.purple;
      default:
        return AppColors.primary;
    }
  }

  IconData _getFileTypeIcon(String extension) {
    switch (extension) {
      case '.pdf':
        return Icons.picture_as_pdf;
      case '.doc':
      case '.docx':
        return Icons.description;

      case '.jpg':
      case '.jpeg':
      case '.png':
        return Icons.image;
      default:
        return Icons.insert_drive_file;
    }
  }
}
