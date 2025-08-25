import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:toolkit/screens/convert_word_screen/word_format_selection_screen.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_snackbar.dart';
import '../../widgets/buttons/gradient_btn.dart';
import '../../widgets/tools/custom_svg_image.dart';
import '../../widgets/tools/info_card.dart';
import '../../widgets/tools/tools_app_bar.dart';

class ConvertWordToPdfMainScreen extends StatefulWidget {
  const ConvertWordToPdfMainScreen({super.key});

  @override
  State<ConvertWordToPdfMainScreen> createState() => _ConvertWordToPdfMainScreenState();
}

class _ConvertWordToPdfMainScreenState extends State<ConvertWordToPdfMainScreen> {
  File? _selectedWordFile;
  String? _errorMessage;

  void _clearSelectedFile() {
    setState(() {
      _selectedWordFile = null;
    });
  }

  Future<void> _pickWordFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['docx', 'doc'],
      );

      if (result != null) {
        final file = File(result.files.single.path!);
        final extension = result.files.single.extension?.toLowerCase();

        // Check if it's a supported Word document format
        if (extension != 'docx' && extension != 'doc') {
          setState(() {
            _errorMessage = 'please_select_word_only'.tr;
            _selectedWordFile = null;
          });
          return;
        }

        if (extension == 'doc') {
          setState(() {
            _errorMessage = 'docx_format_preferred'.tr;
            _selectedWordFile = file; // Still allow it but show warning
          });
        } else {
          setState(() {
            _selectedWordFile = file;
            _errorMessage = null;
          });
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = '${'error_selecting_word'.tr}: $e';
        _selectedWordFile = null;
      });
    }
  }

  void _removeWordFile() {
    setState(() {
      _selectedWordFile = null;
      _errorMessage = null;
    });
  }

  Future<void> _convertWordFile() async {
    if (_selectedWordFile == null) {
      AppSnackBar.show(context, message: 'please_select_word_first'.tr);
      return;
    }

    // Navigate to format selection screen instead of directly to save screen
    final shouldClearFile = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WordFormatSelectionScreen(
          selectedWordFile: _selectedWordFile!,
          onFileDeleted: _clearSelectedFile,
        ),
      ),
    );

    // Clear the file if needed
    if (shouldClearFile == true) {
      _clearSelectedFile();
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: ToolsAppBar(
        title: 'convert_word_to_pdf'.tr,
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
                      title: 'convert_word_to_pdf_format'.tr,
                      description: 'convert_word_to_pdf_description'.tr),
                  const SizedBox(height: 24),
                  // Custom Word file selection container
                  _buildWordFileSelectionContainer(),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _errorMessage!,
                      style: TextStyle(
                          color: _errorMessage!.contains('preferred') ? Colors.orange : Colors.red,
                          fontSize: 10
                      ),
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
              text: 'convert_to_pdf'.tr,
              onPressed: _convertWordFile,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWordFileSelectionContainer() {
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
                'select_word_file'.tr,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          // Word file selection area
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: InkWell(
              onTap: _selectedWordFile == null ? _pickWordFile : null,
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
                  child: _selectedWordFile != null
                      ? Stack(
                    children: [
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: Icon(
                                  Icons.description,
                                  size: 30,
                                  color: Colors.blue[700],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _selectedWordFile!.path.split('/').last,
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
                          onTap: _removeWordFile,
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
                        'click_to_choose_word'.tr,
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