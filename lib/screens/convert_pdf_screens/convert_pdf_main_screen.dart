import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart'; // GetX import for localization
import '../../utils/app_colors.dart';
import '../../utils/app_snackbar.dart';
import '../../widgets/buttons/gradient_btn.dart';
import '../../widgets/tools/custom_svg_image.dart';
import '../../widgets/tools/info_card.dart';
import '../../widgets/tools/tools_app_bar.dart';
import 'pdf_format_selection_screen.dart';

class ConvertPdfMainScreen extends StatefulWidget {
  const ConvertPdfMainScreen({super.key});

  @override
  State<ConvertPdfMainScreen> createState() => _ConvertPdfMainScreenState();
}

class _ConvertPdfMainScreenState extends State<ConvertPdfMainScreen> {
  File? _selectedPdf;
  String? _errorMessage;

  void _clearSelectedFile() {
    setState(() {
      _selectedPdf = null;
    });
  }

  Future<void> _pickPdf() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null) {
        final file = File(result.files.single.path!);
        if (result.files.single.extension?.toLowerCase() != 'pdf') {
          setState(() {
            _errorMessage = 'please_select_pdf_only'.tr;
            _selectedPdf = null;
          });
          return;
        }

        setState(() {
          _selectedPdf = file;
          _errorMessage = null;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = '${'error_selecting_pdf'.tr}: $e';
        _selectedPdf = null;
      });
    }
  }

  void _removePdf() {
    setState(() {
      _selectedPdf = null;
    });
  }

  Future<void> _convertPdf() async {
    if (_selectedPdf == null) {
      AppSnackBar.show(context, message: 'please_select_pdf_first'.tr);
      return;
    }

    final shouldClearFile = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PdfFormatSelectionScreen(
          selectedPdf: _selectedPdf!,
          onFileDeleted: _clearSelectedFile, // Pass the callback
        ),
      ),
    );

    if (shouldClearFile == true) {
      _clearSelectedFile();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: ToolsAppBar(
        title: 'convert_pdf'.tr,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(30.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const CustomSvgImage(
                      imagePath: 'assets/images/convert_pdf_img.svg'),
                  const SizedBox(height: 30),
                  InfoCard(
                      title: 'convert_pdf_format'.tr,
                      description: 'convert_pdf_description'.tr),
                  const SizedBox(height: 24),
                  // Custom PDF selection container
                  _buildPdfSelectionContainer(),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red, fontSize: 10),
                    ),
                  ],
                ],
              ),
            ),
          ),
          Padding(
            padding:
            const EdgeInsets.symmetric(horizontal: 30.0, vertical: 26.0),
            child: CustomGradientButton(
              text: 'next'.tr,
              onPressed: _convertPdf,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPdfSelectionContainer() {
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
          // Title
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 14, top: 14),
              child: Text(
                'select_file'.tr,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          // PDF selection area
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: InkWell(
              onTap: _selectedPdf == null ? _pickPdf : null,
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
                    color: AppColors.bgBoxColor,
                  ),
                  child: _selectedPdf != null
                      ? Stack(
                    children: [
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(top: 10),
                                child: Icon(
                                  Icons.picture_as_pdf,
                                  size: 30,
                                  color: Colors.red,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _selectedPdf!.path.split('/').last,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.grey.shade600,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: _removePdf,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                )
                              ],
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                      : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SvgPicture.asset(
                        'assets/icons/upload_file_icon.svg',
                        height: 28,
                        width: 36,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'click_to_choose_pdf'.tr,
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
            ),
          ),
        ],
      ),
    );
  }
}