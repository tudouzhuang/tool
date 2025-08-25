import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as path;
import 'package:pdfx/pdfx.dart';
import 'package:toolkit/screens/split_screen/split_result_screen.dart';
import 'package:toolkit/utils/app_snackbar.dart';
import 'package:toolkit/widgets/buttons/gradient_btn.dart';
import 'package:toolkit/widgets/custom_appbar.dart';

import '../../utils/app_colors.dart';
import 'document_item.dart';

class PageSelectionScreen extends StatefulWidget {
  final DocumentItem selectedDocument;
  final int initialPageCount;
  final bool isWordDocument;

  const PageSelectionScreen({
    super.key,
    required this.selectedDocument,
    this.initialPageCount = 1,
    this.isWordDocument = false,
  });

  @override
  State<PageSelectionScreen> createState() => _PageSelectionScreenState();
}

class _PageSelectionScreenState extends State<PageSelectionScreen> {
  late int totalPages;
  late List<bool> selectedPages;
  final TextEditingController _pageCountController = TextEditingController(text: '6');

  bool _isLoadingPreviews = false;
  List<Uint8List?> _pageImages = [];
  PdfDocument? _pdfDocument;
  bool _isPdfFile = false;
  String? _filePath;

  @override
  void initState() {
    super.initState();
    totalPages = widget.initialPageCount;
    selectedPages = List.generate(totalPages, (index) => false);

    _filePath = widget.selectedDocument.file.path;

    if (_filePath != null) {
      final fileExtension = path.extension(_filePath!).toLowerCase();
      _isPdfFile = fileExtension == '.pdf';

      if (_isPdfFile) {
        _loadPdfPreviews();
      }
    }
  }

  @override
  void dispose() {
    _pageCountController.dispose();
    _pdfDocument?.close();
    super.dispose();
  }

  Future<void> _loadPdfPreviews() async {
    if (_filePath == null) return;

    try {
      setState(() {
        _isLoadingPreviews = true;
        _pageImages = List<Uint8List?>.filled(totalPages, null);
      });

      _pdfDocument = await PdfDocument.openFile(_filePath!);

      for (int i = 0; i < totalPages; i++) {
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
          print('Error rendering page ${i + 1}: $pageError');
          _pageImages[i] = await _generatePlaceholderImage(i + 1, 'PDF');
        }
      }
    } catch (e) {
      print('Error generating PDF previews: $e');
      for (int i = 0; i < totalPages; i++) {
        _pageImages[i] = await _generatePlaceholderImage(i + 1, 'PDF');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingPreviews = false;
        });
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

  void _togglePage(int pageIndex) {
    setState(() {
      selectedPages[pageIndex] = !selectedPages[pageIndex];
    });
  }

  void _onSplitPressed() {
    final anySelected = selectedPages.any((s) => s);
    if (!anySelected) {
      AppSnackBar.show(context, message: 'Please select at least one page');
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SplitProgressScreen(
          document: widget.selectedDocument,
          selectedPages: selectedPages,
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
            child: CircularProgressIndicator(
                color: AppColors.primary),
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
              'Page ${index + 1}',
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
                height: 110,
                width: 110,
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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(title: ('split'.tr)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 15,),
              Expanded(
                child: GridView.builder(
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
                                color: selectedPages[index]
                                    ? const Color(0xFF009688)
                                    : Colors.grey.shade300,
                                width: selectedPages[index] ? 2 : 1,
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
                                color: selectedPages[index]
                                    ? const Color(0xFF009688)
                                    : Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: selectedPages[index]
                                      ? Colors.transparent
                                      : Colors.grey.shade400,
                                  width: 2,
                                ),
                              ),
                              child: selectedPages[index]
                                  ? const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 16,
                              )
                                  : null,
                            ),
                          ),
                          if (selectedPages[index])
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
                                    '${selectedPages.take(index).where((selected) => selected).length + 1}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
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
                padding: const EdgeInsets.symmetric(horizontal:6.0, vertical: 10.0),
                child: CustomGradientButton(
                  text: ('split'.tr),
                  onPressed: _onSplitPressed,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}