import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:toolkit/screens/convert_word_screen/word_save_screen.dart';
import 'dart:io';
import '../../services/word_to_img_service.dart';
import '../../services/word_to_pdf_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_snackbar.dart';
import '../../widgets/buttons/gradient_btn.dart';
import '../../widgets/custom_appbar.dart';

class WordFormatSelectionScreen extends StatefulWidget {
  final File selectedWordFile;
  final VoidCallback? onFileDeleted;

  const WordFormatSelectionScreen({
    super.key,
    required this.selectedWordFile,
    this.onFileDeleted
  });

  @override
  State<WordFormatSelectionScreen> createState() => _WordFormatSelectionScreenState();
}

class _WordFormatSelectionScreenState extends State<WordFormatSelectionScreen> {
  String? selectedFormat;
  bool _isConverting = false;
  File? _convertedFile;
  List<File>? _convertedFiles; // For multiple images

  // Initialize services
  final WordToImageService _imageService = WordToImageService();
  final WordToPdfService _pdfService = WordToPdfService();

  String get fileName => widget.selectedWordFile.path.split('/').last;

  String get fileSize {
    final sizeInBytes = widget.selectedWordFile.lengthSync();
    if (sizeInBytes < 1024) return '$sizeInBytes B';
    if (sizeInBytes < 1024 * 1024) return '${(sizeInBytes / 1024).toStringAsFixed(1)} KB';
    return '${(sizeInBytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  String get formattedDate {
    final modifiedDate = widget.selectedWordFile.lastModifiedSync();
    return '${modifiedDate.day.toString().padLeft(2, '0')}/${modifiedDate.month.toString().padLeft(2, '0')}/${modifiedDate.year.toString().substring(2)}';
  }

  String get formattedTime {
    final modifiedDate = widget.selectedWordFile.lastModifiedSync();
    final hour = modifiedDate.hour == 0 ? 12 : (modifiedDate.hour > 12 ? modifiedDate.hour - 12 : modifiedDate.hour);
    final period = modifiedDate.hour < 12 ? 'AM' : 'PM';
    return '$hour:${modifiedDate.minute.toString().padLeft(2, '0')} $period';
  }

  Future<void> _convertFile() async {
    // Check if no format is selected
    if (selectedFormat == null) {
      AppSnackBar.show(context, message: 'Please select a format first'.tr);
      return;
    }

    // Validate file exists and is readable
    if (!await widget.selectedWordFile.exists()) {
      AppSnackBar.show(context, message: 'Selected file does not exist'.tr);
      return;
    }

    setState(() {
      _isConverting = true;
      _convertedFile = null;
      _convertedFiles = null;
    });

    try {
      switch (selectedFormat) {
        case 'PDF':
          _convertedFile = await _pdfService.convertWordToPdf(widget.selectedWordFile);
          break;

        case 'Image':
        // Check if file is too large and might need multiple pages
          final fileSizeInMB = widget.selectedWordFile.lengthSync() / (1024 * 1024);

          if (fileSizeInMB > 5.0) {
            // For larger files, create multiple images
            _convertedFiles = await _imageService.convertWordToMultipleImages(
              widget.selectedWordFile,
              width: 800,
              height: 1200,
              fontSize: 14,
              linesPerPage: 45,
            );
            // Set the first image as the main converted file for compatibility
            _convertedFile = _convertedFiles!.isNotEmpty ? _convertedFiles!.first : null;
          } else {
            // For smaller files, create single image
            _convertedFile = await _imageService.convertWordToImage(
              widget.selectedWordFile,
              width: 800,
              height: 1200,
              fontSize: 14,
              outputFormat: 'png',
            );
          }
          break;

        default:
          throw Exception('Unsupported format: $selectedFormat'.tr);
      }

      if (_convertedFile == null) {
        throw Exception('Conversion failed - no output generated'.tr);
      }

      if (!mounted) return;

      // Navigate to WordSaveScreen with converted file(s)
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => WordSaveScreen(
            selectedWordFile: widget.selectedWordFile,
            convertedFile: _convertedFile!,
            selectedFormat: selectedFormat!,
            onFileDeleted: widget.onFileDeleted,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      // More detailed error handling
      String errorMessage;
      if (e.toString().contains('Permission denied')) {
        errorMessage = 'Permission denied. Please check file permissions.'.tr;
      } else if (e.toString().contains('No space left')) {
        errorMessage = 'Insufficient storage space.'.tr;
      } else if (e.toString().contains('Invalid file format')) {
        errorMessage = 'Invalid Word document format.'.tr;
      } else {
        errorMessage = 'Conversion failed: ${e.toString().replaceAll('Exception: ', '')}';
      }

      _showErrorDialog(errorMessage);
    } finally {
      if (mounted) {
        setState(() {
          _isConverting = false;
        });
      }
    }
  }

  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red[600],
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              'conversion_failed'.tr,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              error,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Please try again or select a different file.'.tr,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: Text(
              'ok'.tr,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(title: 'convert_word'.tr),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Text(
              'selected_file'.tr,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 10),
            _buildFileInfoCard(),
            const SizedBox(height: 30),
            Text(
              'select_format'.tr,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                _buildFormatOption('PDF', 'assets/icons/convert_pdf.svg'),
                const SizedBox(
                  width: 16,
                ),
                _buildFormatOption('Image', 'assets/icons/convert_img_icon.svg'),
              ],
            ),
            const Spacer(),
            _buildConvertButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildFileInfoCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                width: 50,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: Colors.transparent,
                ),
                child: Center(
                  child: SvgPicture.asset(
                    'assets/icons/word_icon.svg',
                    width: 30,
                    height: 30,
                  ),
                ),
              ),
            ),
            Container(width: 1, color: Colors.grey.shade300),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      fileName,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$formattedDate | $formattedTime | $fileSize MB',
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.w400,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormatOption(String label, String iconPath) {
    final isSelected = selectedFormat == label;
    return GestureDetector(
      onTap: _isConverting ? null : () => setState(() {
        selectedFormat = label;
        _convertedFile = null;
        _convertedFiles = null;
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        child: Column(
          children: [
            Container(
              width: 85,
              height: 85,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: isSelected
                    ? Border.all(color: AppColors.primary, width: 3)
                    : Border.all(color: Colors.grey.shade300, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: isSelected
                        ? AppColors.primary.withOpacity(0.3)
                        : Colors.black.withOpacity(0.1),
                    blurRadius: isSelected ? 8 : 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: SvgPicture.asset(
                  iconPath,
                  width: 32,
                  height: 36,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? AppColors.primary : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConvertButton() {
    return CustomGradientButton(
      text: _isConverting ? 'converting'.tr : 'convert'.tr,
      onPressed: _isConverting ? null : _convertFile,
    );
  }
}