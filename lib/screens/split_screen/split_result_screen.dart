import 'dart:io';
import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as syncfusion;
import 'package:toolkit/widgets/tools/document_container.dart';
import 'package:path/path.dart' as path;
import '../../services/save_zip_png_service.dart';
import '../../utils/app_snackbar.dart';
import '../../widgets/buttons/gradient_btn.dart';
import '../../widgets/custom_appbar.dart';
import '../../widgets/tools/animated_loaded_container.dart';
import 'document_item.dart';
import 'docxService.dart';

class SplitProgressScreen extends StatefulWidget {
  final DocumentItem document;
  final List<bool> selectedPages;
  final bool isMultipleFiles;
  final List<DocumentItem> documents;

  const SplitProgressScreen({
    super.key,
    required this.document,
    required this.selectedPages,
    this.isMultipleFiles = false,
    this.documents = const [],
  });

  @override
  State<SplitProgressScreen> createState() => _SplitProgressScreenState();
}

class _SplitProgressScreenState extends State<SplitProgressScreen> with SingleTickerProviderStateMixin {

  final TextEditingController _textController = TextEditingController();
  bool _animationCompleted = false;
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;
  double _progress = 0.0;
  File? _outputFile;
  final String _resultText = '';
  bool _fileRenamed = false;
  String _saveButtonKey = 'initial';
  final bool _isSaving = false;

  File? convertedFile;
  String _currentFilePath = '';

  // DocxSplitterService to handle DOCX processing
  final DocxSplitterService _docxService = DocxSplitterService();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _progressAnimation.addListener(() {
      setState(() {});
    });

    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _animationCompleted = true;
          _textController.text = _resultText;
        });
      }
    });

    _animationController.forward();
    _startSplitting();
  }

  Future<void> _handleSaveFile() async {
    if (convertedFile != null) {
      try {
        await SaveFileService.saveFile(
          context,
          File(_currentFilePath),
          _getFormatExtension(),
        );
        Navigator.of(context).popUntil((route) => route.isFirst);
      } catch (e) {
        AppSnackBar.show(context,
            message: '${'failed_to_save_file'.tr}: ${e.toString()}');
      }
    }
  }

  String _getFormatExtension() {
    if (_currentFilePath.isNotEmpty) {
      return _currentFilePath.split('.').last;
    }
    return 'pdf';
  }

  Future<void> _handleFileRenamed(String newPath) async {
    try {
      final oldFile = _outputFile;
      final newFile = File(newPath);

      if (oldFile != null && oldFile.path != newPath) {
        if (await oldFile.exists()) {
          await oldFile.rename(newPath);
        }
      }

      setState(() {
        _outputFile = newFile;
        convertedFile = newFile;
        _currentFilePath = newPath;
        _fileRenamed = true;
        _saveButtonKey = 'renamed_${DateTime.now().millisecondsSinceEpoch}';
      });

      if (mounted) {
        AppSnackBar.show(context, message: 'file_renamed_successfully'.tr);
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.show(context, message: '${'error_renaming_file'.tr}: ${e.toString()}');
      }
    }
  }

  Future<void> _startSplitting() async {
    for (int i = 0; i <= 10; i += 5) {
      if (mounted) {
        setState(() {
          _progress = i / 100;
        });
      }
      await Future.delayed(const Duration(milliseconds: 100));
    }

    try {
      final tempDir = await getTemporaryDirectory();
      final fileName = widget.document.name;
      final outputPath = '${tempDir.path}/split_$fileName';

      if (fileName.toLowerCase().endsWith('.pdf')) {
        await _processPdfFile(outputPath);
      }
      else if (fileName.toLowerCase().endsWith('.docx')) {
        await _processDocxFile(outputPath);
      } else {
        _updateStatus('processing_generic_document'.tr);
        _outputFile = File(outputPath);
        await widget.document.file.copy(_outputFile!.path);

        for (int i = 30; i <= 100; i += 10) {
          if (mounted) {
            setState(() {
              _progress = i / 100;
            });
          }
          await Future.delayed(const Duration(milliseconds: 100));
        }
      }

      if (_outputFile != null) {
        convertedFile = _outputFile;
        _currentFilePath = _outputFile!.path;
      }

    } catch (e) {
      print('Error processing file: $e');
      _updateStatus('error_encountered_fallback'.tr);

      final tempDir = await getTemporaryDirectory();
      _outputFile = File('${tempDir.path}/split_${widget.document.name}');
      await widget.document.file.copy(_outputFile!.path);

      if (_outputFile != null) {
        convertedFile = _outputFile;
        _currentFilePath = _outputFile!.path;
      }

      for (int i = _progress.toInt() * 100; i <= 100; i += 10) {
        if (mounted) {
          setState(() {
            _progress = i / 100;
          });
        }
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }

    if (mounted) {
      setState(() {
      });
    }
  }

  void _updateStatus(String message) {
    if (mounted) {
      setState(() {
      });
    }
  }

  Future<void> _processPdfFile(String outputPath) async {
    _updateStatus('creating_pdf_selected_pages'.tr);

    final pdfData = await widget.document.file.readAsBytes();
    final originalDoc = syncfusion.PdfDocument(inputBytes: pdfData);

    final selectedIndices = <int>[];
    for (int i = 0; i < widget.selectedPages.length; i++) {
      if (widget.selectedPages[i]) {
        selectedIndices.add(i);
      }
    }

    if (selectedIndices.isEmpty) {
      originalDoc.dispose();
      throw Exception('no_pages_selected'.tr);
    }

    final mergedDoc = syncfusion.PdfDocument();

    for (int i = 0; i < selectedIndices.length; i++) {
      final pageIndex = selectedIndices[i];
      if (pageIndex >= originalDoc.pages.count) continue;

      final page = originalDoc.pages[pageIndex];
      final pageTemplate = page.createTemplate();

      final newPage = mergedDoc.pages.add();
      newPage.graphics.drawPdfTemplate(pageTemplate, const Offset(0, 0));

      if (mounted) {
        setState(() => _progress = (i + 1) / selectedIndices.length * 0.9);
      }
    }

    originalDoc.dispose();

    _outputFile = File(outputPath);
    final bytes = mergedDoc.saveSync();
    await _outputFile!.writeAsBytes(bytes);
    mergedDoc.dispose();

    if (mounted) {
      setState(() => _progress = 1.0);
    }
    _updateStatus('pdf_created_successfully'.tr);
  }

  Future<void> _openFile() async {
    try {
      if (_outputFile == null) {
        AppSnackBar.show(context, message: 'no_document_available_to_open'.tr);
        return;
      }

      if (!await _outputFile!.exists()) {
        AppSnackBar.show(context, message: 'file_not_found'.tr);
        return;
      }

      final result = await OpenFile.open(_outputFile!.path);

      if (result.type != ResultType.done) {
        AppSnackBar.show(context, message: '${'cannot_open_file'.tr}: ${result.message}');

        if (_outputFile!.path.toLowerCase().endsWith('.zip')) {
          AppSnackBar.show(context, message: 'zip_file_message'.tr);
        }
      }
    } catch (e) {
      print('Error opening file: $e');
      AppSnackBar.show(context, message: 'error_opening_document'.tr);
    }
  }

  void _handleFileDeleted() async {
    if (!mounted) return;

    try {
      if (_outputFile != null && await _outputFile!.exists()) {
        await _outputFile!.delete();
        print('File deleted: ${_outputFile!.path}');
      }

      setState(() {
        _outputFile = null;
        convertedFile = null;
        _currentFilePath = '';
        _saveButtonKey = 'deleted_${DateTime.now().millisecondsSinceEpoch}';
      });

      if (_outputFile == null && mounted) {
        Navigator.of(context).pop();
        Navigator.of(context).pop();
        Navigator.of(context).pop();
        AppSnackBar.show(context, message: 'file_deleted_successfully'.tr);
        return;
      }

    } catch (e) {
      print('Error deleting file: $e');
      if (mounted) {
        AppSnackBar.show(context, message: '${'error_during_deletion'.tr}: ${e.toString()}');
      }
    }
  }

  Future<void> _processDocxFile(String outputPath) async {
    try {
      _updateStatus('splitting_docx_files'.tr);

      final pages = await _docxService.extractPages(widget.document.file);
      final archive = Archive();
      final baseName = path.basenameWithoutExtension(widget.document.name);

      for (int i = 0; i < widget.selectedPages.length; i++) {
        if (!widget.selectedPages[i] || i >= pages.length) continue;

        final singlePageRange = [[i]];
        final results = await _docxService.splitDocxByRanges(widget.document.file, singlePageRange);
        if (results.isNotEmpty) {
          final filePath = results[0].filePath;
          final file = File(filePath);
          if (await file.exists()) {
            final bytes = await file.readAsBytes();
            final fileName = '${baseName}_page_${i + 1}.docx';
            archive.addFile(ArchiveFile(fileName, bytes.length, bytes));
          }
        }

        setState(() => _progress = (i + 1) / widget.selectedPages.length * 0.9);
      }

      _updateStatus('creating_zip_archive'.tr);
      final zipBytes = ZipEncoder().encode(archive);
      _outputFile = File(outputPath.replaceAll('.docx', '.zip'));
      await _outputFile!.writeAsBytes(zipBytes!);

      setState(() => _progress = 1.0);
      _updateStatus('zip_created_successfully'.tr);
    } catch (e) {
      print("DOCX splitting error: $e");
      _updateStatus('error_saving_original'.tr);
      _outputFile = File(outputPath);
      await widget.document.file.copy(outputPath);
    }
  }

  bool get hasValidFile {
    return _outputFile != null && _outputFile!.existsSync();
  }

  @override
  void dispose() {
    _textController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(title: ('split_document'.tr)),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(14.0, 14.0, 14.0, 100.0),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    _buildLoadingContainer(),
                    if (_animationCompleted) ...[
                      const SizedBox(height: 36),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          ('split_file_progress_screen'.tr),
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (_outputFile != null)
                        DocumentContainer(
                          filePath: _outputFile!.path,
                          onTap: _openFile,
                          onDelete: _handleFileDeleted,
                          onFileRenamed: _handleFileRenamed,
                        ),
                    ],
                  ],
                ),
              ),
            ),

            if (_animationCompleted && hasValidFile)
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  child: CustomGradientButton(
                    key: ValueKey(_saveButtonKey),
                    text: _isSaving ? 'saving'.tr : 'save'.tr,
                    onPressed: _isSaving ? null : _handleSaveFile,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingContainer() {
    return AnimatedLoadingContainer(
      animationController: _animationController,
      animationCompleted: _animationCompleted,
    );
  }
}