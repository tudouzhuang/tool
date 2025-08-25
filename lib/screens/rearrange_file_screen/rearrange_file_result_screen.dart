import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:open_file/open_file.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:toolkit/screens/rearrange_file_screen/pdf_rearrange_service.dart';
import '../../utils/app_snackbar.dart';
import '../../widgets/buttons/gradient_btn.dart';
import '../../widgets/custom_appbar.dart';
import '../../widgets/tools/animated_loaded_container.dart';
import '../../widgets/tools/document_container.dart';
import '../../services/save_zip_png_service.dart';
import '../split_screen/docxService.dart';
import 'package:pdf/widgets.dart' as pw;

class RearrangeFileResultScreen extends StatefulWidget {
  final File originalFile;
  final List<int> newPageOrder;
  final bool isPdfFile;
  final List<pw.Document>? pdfPages;

  const RearrangeFileResultScreen({
    super.key,
    required this.originalFile,
    required this.newPageOrder,
    this.isPdfFile = false,
    this.pdfPages,
  });

  @override
  State<RearrangeFileResultScreen> createState() => _RearrangeFileResultScreenState();
}

class _RearrangeFileResultScreenState extends State<RearrangeFileResultScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;
  bool _animationCompleted = false;

  double _progress = 0.0;
  File? _outputFile;
  bool _processingComplete = false;
  bool _errorOccurred = false;
  String _statusMessage = '';
  final List<File?> _rearrangedFiles = [];
  bool _fileRenamed = false;
  String _saveButtonKey = 'initial';
  final bool _isSaving = false;
  File? convertedFile;
  String _currentFilePath = '';

  @override
  void initState() {
    super.initState();
    _statusMessage = 'processing_document'.tr;

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    )..addListener(() {
      setState(() {});
    });

    _animationController.forward().then((_) {
      setState(() {
        _animationCompleted = true;
      });
    });

    _rearrangeDocument();
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
    return widget.isPdfFile ? 'pdf' : 'docx';
  }

  Future<void> _rearrangeDocument() async {
    try {
      if (!await widget.originalFile.exists()) {
        throw Exception('original_file_not_exist'.tr);
      }

      final fileSize = await widget.originalFile.length();
      if (fileSize == 0) {
        throw Exception('original_file_empty'.tr);
      }

      if (widget.newPageOrder.isEmpty) {
        throw Exception('no_page_order_specified'.tr);
      }

      setState(() => _statusMessage = 'reading_document_pages'.tr);
      _updateProgress(0.2);

      if (widget.isPdfFile) {
        final pdfService = PdfRearrangeService();

        List<pw.Document> allPages;
        if (widget.pdfPages != null) {
          allPages = widget.pdfPages!;
        } else {
          allPages = await pdfService.extractPages(widget.originalFile);
        }

        if (allPages.isEmpty) {
          throw Exception('no_pages_found_pdf'.tr);
        }

        for (int index in widget.newPageOrder) {
          if (index < 0 || index >= allPages.length) {
            throw Exception('${'invalid_page_index'.tr}: $index. ${'document_has'.tr} ${allPages.length} ${'pages'.tr}.');
          }
        }

        _updateProgress(0.4);

        setState(() => _statusMessage = 'rearranging_pdf_pages'.tr);

        final reorderedPages = widget.newPageOrder.map((index) => allPages[index]).toList();

        if (reorderedPages.isEmpty) {
          throw Exception('no_pages_selected_rearrangement'.tr);
        }

        _updateProgress(0.6);

        setState(() => _statusMessage = 'creating_new_pdf_document'.tr);

        final fileNameWithoutExt = path.basenameWithoutExtension(widget.originalFile.path);
        final timestamp = DateTime.now().millisecondsSinceEpoch;

        final Directory appDocDir = await getApplicationDocumentsDirectory();
        final String outputPath = path.join(
            appDocDir.path,
            '${fileNameWithoutExt}_rearranged_$timestamp.pdf'
        );

        await Directory(path.dirname(outputPath)).create(recursive: true);

        _outputFile = await pdfService.createPdfFromPages(reorderedPages, outputPath);

        _updateProgress(0.8);

      } else {
        final docxService = DocxSplitterService();

        final allPages = await docxService.extractPages(widget.originalFile);

        if (allPages.isEmpty) {
          throw Exception('no_pages_found_document'.tr);
        }

        for (int index in widget.newPageOrder) {
          if (index < 0 || index >= allPages.length) {
            throw Exception('${'invalid_page_index'.tr}: $index. ${'document_has'.tr} ${allPages.length} ${'pages'.tr}.');
          }
        }

        _updateProgress(0.4);

        setState(() => _statusMessage = 'rearranging_pages'.tr);
        final reorderedPages = widget.newPageOrder.map((index) => allPages[index]).toList();

        if (reorderedPages.isEmpty) {
          throw Exception('no_pages_selected_rearrangement'.tr);
        }

        _updateProgress(0.6);

        setState(() => _statusMessage = 'creating_new_document'.tr);

        final fileNameWithoutExt = path.basenameWithoutExtension(widget.originalFile.path);
        final fileExt = path.extension(widget.originalFile.path);
        final timestamp = DateTime.now().millisecondsSinceEpoch;

        final Directory appDocDir = await getApplicationDocumentsDirectory();
        final String outputPath = path.join(
            appDocDir.path,
            '${fileNameWithoutExt}_rearranged_$timestamp$fileExt'
        );

        await Directory(path.dirname(outputPath)).create(recursive: true);

        _outputFile = await docxService.createDocumentFromPages(
            reorderedPages,
            outputPath
        );

        _updateProgress(0.8);
      }

      if (_outputFile == null) {
        throw Exception('failed_create_output_file'.tr);
      }

      if (!await _outputFile!.exists()) {
        throw Exception('output_file_not_created'.tr);
      }

      final outputSize = await _outputFile!.length();
      if (outputSize == 0) {
        throw Exception('created_file_empty'.tr);
      }

      print('Created ${widget.isPdfFile ? "PDF" : "DOCX"} file: ${_outputFile!.path}, size: $outputSize bytes');

      _rearrangedFiles.add(_outputFile);

      convertedFile = _outputFile;
      _currentFilePath = _outputFile!.path;

      _updateProgress(0.9);

      setState(() {
        _statusMessage = '${'document_rearranged_successfully'.tr} (${_formatFileSize(outputSize)})';
        _processingComplete = true;
        _progress = 1.0;
      });

    } catch (e) {
      print('Error in _rearrangeDocument: $e');
      setState(() {
        _statusMessage = '${'error'.tr}: ${e.toString()}';
        _errorOccurred = true;
        _processingComplete = false;
      });
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes ${'bytes'.tr}';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  void _updateProgress(double value) {
    setState(() {
      _progress = value;
    });
  }

  Widget _buildLoadingContainer() {
    return AnimatedLoadingContainer(
      animationController: _animationController,
      animationCompleted: _animationCompleted,
    );
  }

  void _openFile(File file) async {
    try {
      if (!await file.exists()) {
        throw Exception('file_not_exist'.tr);
      }

      final fileSize = await file.length();
      if (fileSize == 0) {
        throw Exception('file_empty'.tr);
      }

      // Show loading message
      if (mounted) {
        AppSnackBar.show(context, message: 'opening_file'.tr);
      }

      // Actually open the file
      final result = await OpenFile.open(file.path);

      if (result.type == ResultType.done) {
        // File opened successfully
        print('File opened successfully: ${file.path}');
      } else if (result.type == ResultType.noAppToOpen) {
        if (mounted) {
          AppSnackBar.show(context,
              message: 'no_app_to_open_file'.tr);
        }
      } else if (result.type == ResultType.permissionDenied) {
        if (mounted) {
          AppSnackBar.show(context,
              message: 'permission_denied_open_file'.tr);
        }
      } else {
        if (mounted) {
          AppSnackBar.show(context,
              message: '${'failed_to_open_file'.tr}: ${result.message}');
        }
      }

    } catch (e) {
      print('Error opening file: $e');
      if (mounted) {
        AppSnackBar.show(context, message: '${'cannot_open_file'.tr}: ${e.toString()}');
      }
    }
  }

  void _handleFileDeleted() async {
    try {
      if (_outputFile != null && await _outputFile!.exists()) {
        await _outputFile!.delete();
        print('File deleted: ${_outputFile!.path}');
      }

      _rearrangedFiles.clear();

      setState(() {
        _outputFile = null;
        convertedFile = null;
        _currentFilePath = '';
        _processingComplete = false;
        _saveButtonKey = 'deleted_${DateTime.now().millisecondsSinceEpoch}';
      });

      if (mounted) {
        AppSnackBar.show(context, message: 'file_deleted_successfully'.tr);
      }

      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          Navigator.of(context).pop();
          Navigator.of(context).pop();
          Navigator.of(context).pop();
          AppSnackBar.show(context, message: 'file_deleted_successfully'.tr);
        }
      });

    } catch (e) {
      print('Error deleting file: $e');
      if (mounted) {
        AppSnackBar.show(context, message: '${'error_deleting_file'.tr}: $e');
      }
    }
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

        final index = _rearrangedFiles.indexWhere((file) => file?.path == oldFile?.path);
        if (index != -1) {
          _rearrangedFiles[index] = newFile;
        }
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

  bool get hasValidFiles {
    return _outputFile != null && _outputFile!.existsSync();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(title: 'rearrange_results'.tr),
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
                      if (_errorOccurred) ...[
                        const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 64,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'error_occurred'.tr,
                          style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w600),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _statusMessage,
                          style: GoogleFonts.inter(fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _errorOccurred = false;
                              _processingComplete = false;
                              _progress = 0.0;
                              _statusMessage = 'processing_document'.tr;
                              _rearrangedFiles.clear();
                              _outputFile = null;
                              convertedFile = null;
                              _currentFilePath = '';
                              _fileRenamed = false;
                              _saveButtonKey = 'retry_${DateTime.now().millisecondsSinceEpoch}';
                            });
                            _rearrangeDocument();
                          },
                          child: Text('try_again'.tr),
                        ),
                      ] else ...[
                        const SizedBox(height: 24),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'rearranged_files'.tr,
                            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w500),
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (_rearrangedFiles.isNotEmpty)
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _rearrangedFiles.length,
                            itemBuilder: (context, index) {
                              final file = _rearrangedFiles[index];
                              if (file == null) return const SizedBox.shrink();
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: DocumentContainer(
                                  filePath: file.path,
                                  onTap: () => _openFile(file),
                                  onDelete: _handleFileDeleted,
                                  onFileRenamed: _handleFileRenamed,
                                ),
                              );
                            },
                          )
                        else if (!_processingComplete)
                          Center(
                            child: Text(
                              'processing_document'.tr,
                              style: GoogleFonts.inter(fontSize: 16),
                            ),
                          ),
                      ],
                    ],
                  ],
                ),
              ),
            ),

            if (_animationCompleted && hasValidFiles && !_errorOccurred && _processingComplete)
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: CustomGradientButton(
                    key: Key(_saveButtonKey),
                    text: _isSaving
                        ? 'saving'.tr
                        : 'save'.tr,
                    onPressed: _isSaving ? null : _handleSaveFile,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}