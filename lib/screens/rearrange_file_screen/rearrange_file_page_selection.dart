import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as path;
import 'package:pdfx/pdfx.dart';
import 'package:toolkit/screens/rearrange_file_screen/pdf_rearrange_service.dart';
import 'package:toolkit/utils/app_snackbar.dart';
import '../../utils/app_colors.dart';
import '../../widgets/buttons/gradient_btn.dart';
import '../../widgets/custom_appbar.dart';
import '../split_screen/docxService.dart';
import 'rearrange_file_result_screen.dart';
import 'package:pdf/widgets.dart' as pw;

class RearrangeFilePageSelection extends StatefulWidget {
  final File selectedFile;

  const RearrangeFilePageSelection({
    super.key,
    required this.selectedFile,
  });

  @override
  State<RearrangeFilePageSelection> createState() => _RearrangeFilePageSelectionState();
}

class _RearrangeFilePageSelectionState extends State<RearrangeFilePageSelection> {
  File? _docxFile;
  List<bool> _selectedPages = [];
  List<int> _pageSelectionOrder = [];
  String _fileName = '';
  bool _isPdfFile = false;
  List<pw.Document> _pdfPages = [];
  List<Uint8List?> _pageImages = [];
  bool _isLoadingPreviews = false;
  PdfDocument? _pdfDocument;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _processSelectedFile();
  }

  @override
  void dispose() {
    _pdfDocument?.close();
    super.dispose();
  }

  Future<void> _processSelectedFile() async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      _docxFile = widget.selectedFile;
      _fileName = path.basename(_docxFile!.path);

      final fileExtension = path.extension(_docxFile!.path).toLowerCase();
      _isPdfFile = fileExtension == '.pdf';

      if (_isPdfFile) {
        await _processPdfFile();
      } else {
        await _processDocxFile();
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.show(context, message: '${'error_processing_file'.tr}: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _processPdfFile() async {
    final pdfService = PdfRearrangeService();
    final pageCount = await pdfService.getPageCount(_docxFile!);
    _pdfPages = await pdfService.extractPages(_docxFile!);

    setState(() {
      _selectedPages = List<bool>.filled(pageCount, false); // Changed to false
      _pageSelectionOrder = []; // Start with empty list
      _pageImages = List<Uint8List?>.filled(pageCount, null);
      _isLoadingPreviews = true;
    });

    await _generatePdfPreviews();
  }

  Future<void> _processDocxFile() async {
    final docxService = DocxSplitterService();
    final pages = await docxService.extractPages(_docxFile!);

    setState(() {
      _selectedPages = List<bool>.filled(pages.length, false); // Changed to false
      _pageSelectionOrder = []; // Start with empty list
      _isLoadingPreviews = false;
    });
  }

  Future<void> _generatePdfPreviews() async {
    try {
      _pdfDocument = await PdfDocument.openFile(_docxFile!.path);

      // Generate previews for visible pages first
      for (int i = 0; i < _pdfDocument!.pagesCount; i++) {
        if (!mounted) break;

        try {
          final page = await _pdfDocument!.getPage(i + 1);
          final pageImage = await page.render(
            width: 200,
            height: 300,
            format: PdfPageImageFormat.png,
            backgroundColor: '#FFFFFF',
          );

          if (mounted) {
            setState(() {
              _pageImages[i] = pageImage?.bytes;
            });
          }
        } catch (pageError) {
          debugPrint('Error rendering page ${i + 1}: $pageError');
          _pageImages[i] = await _generatePlaceholderImage(i + 1, 'PDF');
        }
      }
    } catch (e) {
      debugPrint('Error generating PDF previews: $e');

      for (int i = 0; i < _pdfPages.length; i++) {
        _pageImages[i] = await _generatePlaceholderImage(i + 1, 'PDF');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingPreviews = false);
      }
    }
  }

  Future<Uint8List> _generatePlaceholderImage(int pageNumber, String fileType) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint();

    paint.color = Colors.white;
    canvas.drawRect(const Rect.fromLTWH(0, 0, 200, 300), paint);

    paint.color = Colors.grey.shade300;
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 2;
    canvas.drawRect(const Rect.fromLTWH(0, 0, 200, 300), paint);

    paint.color = Colors.grey.shade400;
    paint.strokeWidth = 1;
    for (int i = 0; i < 8; i++) {
      canvas.drawLine(
        Offset(20, 40 + (i * 25)),
        Offset(180, 40 + (i * 25)),
        paint,
      );
    }

    paint.color = Colors.grey.shade200;
    paint.style = PaintingStyle.fill;
    canvas.drawRect(const Rect.fromLTWH(70, 220, 60, 40), paint);

    final picture = recorder.endRecording();
    final image = await picture.toImage(200, 300);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    return byteData!.buffer.asUint8List();
  }

  void _togglePage(int index) {
    setState(() {
      if (_selectedPages[index]) {
        _selectedPages[index] = false;
        _pageSelectionOrder.remove(index);
      } else {
        _selectedPages[index] = true;
        _pageSelectionOrder.add(index);
      }
    });
  }

  int _getPageDisplayNumber(int pageIndex) {
    if (!_selectedPages[pageIndex]) return 0;
    return _pageSelectionOrder.indexOf(pageIndex) + 1;
  }

  void _navigateToResults() {
    if (_docxFile == null || _isProcessing) return;

    final newOrder = List<int>.from(_pageSelectionOrder);

    if (newOrder.isEmpty) {
      AppSnackBar.show(context, message: 'please_select_at_least_one_page'.tr);
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RearrangeFileResultScreen(
          originalFile: _docxFile!,
          newPageOrder: newOrder,
          isPdfFile: _isPdfFile,
          pdfPages: _isPdfFile ? _pdfPages : null,
        ),
      ),
    );
  }

  Widget _buildPagePreview(int index) {
    if (_isPdfFile) {
      if (_isLoadingPreviews) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Center(
            child: CircularProgressIndicator(color: AppColors.primary,),
          ),
        );
      }

      if (_pageImages[index] != null) {
        return Padding(
          padding: const EdgeInsets.all(3.5),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              image: DecorationImage(
                image: MemoryImage(_pageImages[index]!),
                fit: BoxFit.cover,
              ),
            ),
          ),
        );
      }

      return Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.picture_as_pdf,
              size: 40,
              color: Colors.grey.shade600,
            ),
            const SizedBox(height: 8),
            Text(
              '${'page_number'.tr} ${index + 1}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    } else {
      return Column(
        children: [
          Expanded(
            child: Center(
              child: Image.asset(
                'assets/images/doc.png',
                fit: BoxFit.cover,
                height: 150,
                width: 150,
                errorBuilder: (context, error, stackTrace) {
                  return Image.asset(
                    'assets/images/doc.png',
                    color: Colors.grey.shade400,
                  );
                },
              ),
            ),
          ),
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalPages = _selectedPages.length;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(title: 'rearrange_pages'.tr),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_isPdfFile && _isLoadingPreviews)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    'loading_pdf_previews'.tr,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              Expanded(
                child: _isProcessing
                    ? const Center(child: CircularProgressIndicator(color: AppColors.primary,))
                    : GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 0.7,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: totalPages,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () => _togglePage(index),
                      child: Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: _selectedPages[index]
                                    ? const Color(0xFF009688)
                                    : Colors.grey.shade300,
                                width: _selectedPages[index] ? 2 : 1,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: _buildPagePreview(index),
                            ),
                          ),
                          Positioned(
                            bottom: 8,
                            right: 8,
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: _selectedPages[index]
                                    ? const Color(0xFF009688)
                                    : Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: _selectedPages[index]
                                      ? Colors.transparent
                                      : Colors.grey.shade400,
                                  width: 2,
                                ),
                              ),
                              child: _selectedPages[index]
                                  ? const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 16,
                              )
                                  : null,
                            ),
                          ),
                          if (_selectedPages[index])
                            Positioned(
                              top: 8,
                              left: 8,
                              child: Container(
                                width: 24,
                                height: 24,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF009688),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    '${_getPageDisplayNumber(index)}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
                child: CustomGradientButton(
                  text: 'rearrange'.tr,
                  onPressed: _navigateToResults,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}