import 'dart:io';
import 'package:dotted_border/dotted_border.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_snackbar.dart';
import '../../widgets/buttons/gradient_btn.dart';
import '../../widgets/tools/custom_svg_image.dart';
import '../../widgets/tools/info_card.dart';
import '../../widgets/tools/tools_app_bar.dart';
import 'merge_result_screen.dart';

class MergeFileMainScreen extends StatefulWidget {
  const MergeFileMainScreen({super.key});

  @override
  State<MergeFileMainScreen> createState() => _MergeFileMainScreenState();
}

class _MergeFileMainScreenState extends State<MergeFileMainScreen> {
  final List<File> _selectedPdfs = [];
  String? _errorMessage;
  bool _isProcessing = false;

  Future<void> _pickPdfs() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: true,
      );

      if (result != null) {
        List<File> newFiles = [];
        for (var file in result.files) {
          if (file.extension?.toLowerCase() != 'pdf') {
            setState(() {
              _errorMessage = 'please_select_pdf_only'.tr;
            });
            continue;
          }

          if (file.path != null) {
            bool isDuplicate = _selectedPdfs
                .any((existingFile) => existingFile.path == file.path);
            if (!isDuplicate) {
              newFiles.add(File(file.path!));
            }
          }
        }

        setState(() {
          _selectedPdfs.addAll(newFiles);
          if (newFiles.isNotEmpty) {
            _errorMessage = null;
          }
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = '${'error_selecting_pdfs'.tr}: $e';
      });
    }
  }

  void _removePdf(int index) {
    setState(() {
      _selectedPdfs.removeAt(index);
      if (_selectedPdfs.isEmpty) {
        _errorMessage = null;
      }
    });
  }

  void _reorderPdfs(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final File item = _selectedPdfs.removeAt(oldIndex);
      _selectedPdfs.insert(newIndex, item);
    });
  }

  Future<void> _mergePdfs() async {
    if (_selectedPdfs.length < 2) {
      AppSnackBar.show(context, message: 'please_two_select'.tr);
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final PdfDocument outputDocument = PdfDocument();

      for (File file in _selectedPdfs) {
        final List<int> bytes = await file.readAsBytes();
        final PdfDocument inputDocument = PdfDocument(inputBytes: bytes);

        for (int i = 0; i < inputDocument.pages.count; i++) {
          outputDocument.pages.add().graphics.drawPdfTemplate(
            inputDocument.pages[i].createTemplate(),
            const Offset(0, 0),
          );
        }

        inputDocument.dispose();
      }

      final List<int> mergedBytes = outputDocument.saveSync();
      outputDocument.dispose();

      final dir = await getTemporaryDirectory();
      final mergedFile = File('${dir.path}/merged_output.pdf');
      await mergedFile.writeAsBytes(mergedBytes);

      setState(() {
        _isProcessing = false;
      });

      // Show success message
      AppSnackBar.show(context, message: 'merge_successful'.tr);

      // Navigate to MergeResultScreen with callback
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MergeResultScreen(
            mergedFilePath: mergedFile.path,
            onSaveAndReturn: () {
              // Clear the selected PDFs when returning
              setState(() {
                _selectedPdfs.clear();
                _errorMessage = null;
              });
            },
          ),
        ),
      );
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      AppSnackBar.show(context, message: '${'failed_to_merge'.tr}: $e');
    }
  }

  String _getFileSizeString(File file) {
    int bytes = file.lengthSync();
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB"];
    int i = (bytes.bitLength - 1) ~/ 10;
    return "${(bytes / (1 << (i * 10))).toStringAsFixed(1)} ${suffixes[i]}";
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: ToolsAppBar(title: 'merge_pdfs'.tr),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(30.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const CustomSvgImage(imagePath: 'assets/images/merge_file_img.svg'),
                  const SizedBox(height: 30),
                  InfoCard(
                    title: 'merge_pdf_files'.tr,
                    description:
                    'merge_file_desc'.tr,
                  ),
                  const SizedBox(height: 24),
                  _buildPdfSelectionContainer(),
                  if (_selectedPdfs.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _buildSelectedPdfsList(),
                  ],
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
            const EdgeInsets.symmetric(horizontal: 20.0, vertical: 30.0),
            child: CustomGradientButton(
              text: 'merge_files'.tr,
              onPressed: _mergePdfs,
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
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 14, top: 14),
              child: Text(
                'select_files'.tr,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: InkWell(
              onTap: _isProcessing ? null : _pickPdfs,
              child: DottedBorder(
                color: _isProcessing ? Colors.grey : AppColors.primary,
                strokeWidth: 1.5,
                dashPattern: const [5, 4],
                borderType: BorderType.RRect,
                radius: const Radius.circular(8),
                child: Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(minHeight: 100),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: _isProcessing ? Colors.grey.shade100 : AppColors.bgBoxColor,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SvgPicture.asset(
                        'assets/icons/upload_file_icon.svg',
                        height: 28,
                        width: 36,
                        color: _isProcessing ? Colors.grey : null,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'click_files'.tr,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          color: _isProcessing ? Colors.grey : Colors.grey.shade600,
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

  Widget _buildSelectedPdfsList() {
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
          Padding(
            padding: const EdgeInsets.only(left: 14, top: 14, bottom: 8, right: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${'selected_files'.tr} (${_selectedPdfs.length})',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (_selectedPdfs.length > 1)
                  Text(
                    'drag_to_reorder'.tr,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
          ),
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _selectedPdfs.length,
            onReorder: _isProcessing ? (_, __) {} : _reorderPdfs,
            itemBuilder: (context, index) {
              final pdfFile = _selectedPdfs[index];
              final fileName = pdfFile.path.split('/').last;
              final fileSize = _getFileSizeString(pdfFile);

              return Container(
                key: Key('pdf_$index'),
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.bgBoxColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.withOpacity(0.3)),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  leading: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: SvgPicture.asset(
                      'assets/icons/convert_pdf.svg',
                      width: 24,
                      height: 24,
                    ),
                  ),
                  title: Text(
                    fileName,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${'page_order'.tr}: ${index + 1}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Text(
                        '${'file_size'.tr}: $fileSize',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                  trailing: _isProcessing
                      ? const SizedBox(
                    width: 24,
                    height: 24,
                  )
                      : GestureDetector(
                    onTap: () => _removePdf(index),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.white,
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
              );
            },
          ),
          if (_selectedPdfs.isNotEmpty)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${'total_files'.tr}: ${_selectedPdfs.length}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}