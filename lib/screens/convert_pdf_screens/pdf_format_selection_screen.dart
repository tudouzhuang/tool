import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart'; // Add this import for localization
import 'dart:io';
import '../../services/pdf_to_img_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_snackbar.dart';
import '../../widgets/buttons/gradient_btn.dart';
import '../../widgets/custom_appbar.dart';
import '../../services/pdf_to_word_service.dart';
import './pdf_save_screen.dart';

class PdfFormatSelectionScreen extends StatefulWidget {
  final File selectedPdf;
  final VoidCallback? onFileDeleted;

  const PdfFormatSelectionScreen(
      {super.key, required this.selectedPdf, this.onFileDeleted});

  @override
  State<PdfFormatSelectionScreen> createState() =>
      _PdfFormatSelectionScreenState();
}

class _PdfFormatSelectionScreenState extends State<PdfFormatSelectionScreen> {
  String? selectedFormat;
  bool _isConverting = false;
  File? _convertedFile;

  String get fileName => widget.selectedPdf.path.split('/').last;

  String get fileSize =>
      (widget.selectedPdf.lengthSync() / (1024 * 1024)).toStringAsFixed(2);

  String get formattedDate {
    final modifiedDate = widget.selectedPdf.lastModifiedSync();
    return '${modifiedDate.day}/${modifiedDate.month}/${modifiedDate.year.toString().substring(2)}';
  }

  String get formattedTime {
    final modifiedDate = widget.selectedPdf.lastModifiedSync();
    return '${modifiedDate.hour}:${modifiedDate.minute.toString().padLeft(2, '0')}${modifiedDate.hour < 12 ? 'AM'.tr : 'PM'.tr}';
  }

  Future<void> _convertFile() async {
    // Check if no format is selected
    if (selectedFormat == null) {
      AppSnackBar.show(context, message: 'Please select a format first'.tr);
      return;
    }

    setState(() {
      _isConverting = true;
      _convertedFile = null;
    });

    try {
      switch (selectedFormat) {
        case 'Word':
          final service = PdfToWordService();
          _convertedFile = await service.convertPdfToWord(widget.selectedPdf);
          break;
        case 'Image':
          final service = PdfToImageService();
          _convertedFile = await service.convertPdfToImage(widget.selectedPdf);
          break;
        default:
          throw Exception('Unsupported format'.tr);
      }

      if (!mounted) return;

      // Navigate to PdfSaveScreen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PdfSaveScreen(
            selectedPdf: widget.selectedPdf,
            convertedFile: _convertedFile!,
            selectedFormat: selectedFormat!,
            onFileDeleted: widget.onFileDeleted,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _showErrorDialog(e.toString());
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
      builder: (context) => AlertDialog(
        title: Text(
          'conversion_failed'.tr,
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        content: Text(
          error,
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'ok'.tr,
              style: GoogleFonts.inter(color: AppColors.primary),
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
      appBar: CustomAppBar(title: 'convert_pdf'.tr),
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
              ),
            ),
            const SizedBox(height: 10),
            Container(
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
                            'assets/icons/convert_pdf.svg',
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
            ),
            const SizedBox(height: 30),
            Text(
              'select_format'.tr,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                _buildFormatOption('word'.tr, 'assets/icons/word_icon.svg'),
                const SizedBox(
                  width: 16,
                ),
                _buildFormatOption(
                    'image'.tr, 'assets/icons/convert_img_icon.svg'),
              ],
            ),
            const Spacer(),
            CustomGradientButton(
              text: _isConverting ? 'converting'.tr : 'convert'.tr,
              onPressed: _isConverting ? null : _convertFile,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormatOption(String label, String iconPath) {
    final isSelected = selectedFormat == label;
    return GestureDetector(
      onTap: () => setState(() {
        selectedFormat = label;
        _convertedFile = null;
      }),
      child: Column(
        children: [
          Container(
            width: 78,
            height: 78,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: isSelected
                  ? Border.all(color: AppColors.primary, width: 2)
                  : null,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.16),
                  blurRadius: 2,
                ),
              ],
            ),
            child: Center(
              child: SvgPicture.asset(
                iconPath,
                width: 30,
                height: 34,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: isSelected ? AppColors.primary : Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
