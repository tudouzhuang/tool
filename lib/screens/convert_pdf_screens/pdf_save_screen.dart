import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart'; // Add this for localization
import 'dart:io';
import 'dart:async';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:archive/archive.dart';
import '../../utils/app_snackbar.dart';
import '../../widgets/buttons/save_zip_png_btn.dart';
import '../../widgets/custom_appbar.dart';
import '../../widgets/tools/animated_loaded_container.dart';
import '../../widgets/tools/document_container.dart';

class PdfSaveScreen extends StatefulWidget {
  final File selectedPdf;
  final File convertedFile;
  final String selectedFormat;
  final VoidCallback? onFileDeleted;

  const PdfSaveScreen({
    super.key,
    required this.selectedPdf,
    required this.convertedFile,
    required this.selectedFormat,
    this.onFileDeleted,
  });

  @override
  State<PdfSaveScreen> createState() => _PdfSaveScreenState();
}

class _PdfSaveScreenState extends State<PdfSaveScreen>
    with SingleTickerProviderStateMixin {
  bool isConverting = true;
  bool isCompleted = false;
  String currentFileName = '';
  bool _animationCompleted = false;
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;
  final List<File> _extractedImageFiles = [];
  bool _isZipFile = false;
  bool _isSinglePageImage = false;
  int _currentImageIndex = 0;
  late String _currentFilePath;

  @override
  void initState() {
    super.initState();
    _currentFilePath = widget.convertedFile.path;
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _progressAnimation.addListener(() => setState(() {}));
    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          isConverting = false;
          _animationCompleted = true;
          isCompleted = true;
        });
        _determineFileType();
      }
    });

    final originalName =
        widget.selectedPdf.path.split('/').last.split('.').first;
    currentFileName = originalName;
    _animationController.forward();
  }

  void _determineFileType() {
    if (widget.selectedFormat == 'Image') {
      _isSinglePageImage =
      !_currentFilePath.toLowerCase().endsWith('.zip');
      _isZipFile = _currentFilePath.toLowerCase().endsWith('.zip');

      if (_isZipFile) {
        _extractZipFile();
      }
    } else {
      _isZipFile = _currentFilePath.toLowerCase().endsWith('.zip');
      if (_isZipFile) {
        _extractZipFile();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    for (var file in _extractedImageFiles) {
      if (file.existsSync()) {
        try {
          file.deleteSync();
        } catch (e) {
          debugPrint('error_deleting_temp_file'.trParams({'error': e.toString()}));
        }
      }
    }
    super.dispose();
  }

  Future<void> _extractZipFile() async {
    try {
      final file = File(_currentFilePath);
      if (!file.existsSync()) {
        return;
      }

      final bytes = await file.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);
      final tempDir = await getTemporaryDirectory();

      for (final file in archive) {
        if (file.isFile && _isImageFile(file.name)) {
          final extractedFile = File('${tempDir.path}/${file.name}');
          await extractedFile.writeAsBytes(file.content as List<int>);
          setState(() {
            _extractedImageFiles.add(extractedFile);
          });
        }
      }
    } catch (e) {
      debugPrint('error_extracting_zip'.trParams({'error': e.toString()}));
      if (mounted) {
        AppSnackBar.show(context,
            message: 'failed_to_extract_images'.trParams({'error': e.toString()}));
      }
    }
  }

  bool _isImageFile(String filename) {
    final extension = filename.toLowerCase().split('.').last;
    return ['jpg', 'jpeg', 'png'].contains(extension);
  }

  String get fileName {
    if (_isSinglePageImage && widget.selectedFormat == 'Image') {
      return '$currentFileName.png';
    }
    return '$currentFileName.${_getFormatExtension()}';
  }

  String _getFormatExtension() {
    switch (widget.selectedFormat) {
      case 'Word':
        return 'docx';
      case 'Excel':
        return 'xlsx';
      case 'PowerPoint':
        return 'pptx';
      case 'Image':
        return _isSinglePageImage ? 'png' : 'zip';
      default:
        return 'jpg';
    }
  }

  String get fileSize {
    final file = File(_currentFilePath);
    return (file.lengthSync() / (1024 * 1024)).toStringAsFixed(2);
  }

  String get formattedDate {
    final now = DateTime.now();
    return '${now.day}/${now.month}/${now.year.toString().substring(2)}';
  }

  String get formattedTime {
    final now = DateTime.now();
    return '${now.hour}:${now.minute.toString().padLeft(2, '0')}${now.hour < 12 ? 'am' : 'pm'}';
  }

  Future<void> _openFile() async {
    final file = File(_currentFilePath);
    if (file.existsSync()) {
      try {
        if (_isZipFile) {
          _showImagePreviewDialog();
        } else if (_isSinglePageImage) {
          final result = await OpenFile.open(_currentFilePath);
          if (result.type != ResultType.done && mounted) {
            AppSnackBar.show(context,
                message: 'cannot_open_image'.trParams({'message': result.message}));
          }
        } else {
          final result = await OpenFile.open(_currentFilePath);
          if (result.type != ResultType.done && mounted) {
            AppSnackBar.show(context,
                message: 'cannot_open_file'.trParams({'message': result.message}));
          }
        }
      } catch (e) {
        if (mounted) {
          AppSnackBar.show(context,
              message: 'error_opening_file'.trParams({'error': e.toString()}));
        }
      }
    } else if (mounted) {
      AppSnackBar.show(context, message: 'file_not_found_or_not_converted'.tr);
    }
  }

  void _showImagePreviewDialog() {
    if (_extractedImageFiles.isEmpty) {
      AppSnackBar.show(context, message: 'no_preview_images_available'.tr);
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'image_preview'.tr,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(),
              SizedBox(
                height: 300,
                child: StatefulBuilder(
                  builder: (context, setState) {
                    return Column(
                      children: [
                        Expanded(
                          child: _extractedImageFiles.isNotEmpty
                              ? Image.file(
                            _extractedImageFiles[_currentImageIndex],
                            fit: BoxFit.contain,
                          )
                              : Center(
                            child: Text('no_images_available'.tr),
                          ),
                        ),
                        if (_extractedImageFiles.length > 1)
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.arrow_back_ios),
                                  onPressed: () {
                                    setState(() {
                                      _currentImageIndex =
                                          (_currentImageIndex - 1) %
                                              _extractedImageFiles.length;
                                      if (_currentImageIndex < 0) {
                                        _currentImageIndex =
                                            _extractedImageFiles.length - 1;
                                      }
                                    });
                                  },
                                ),
                                Text(
                                  '${_currentImageIndex + 1}/${_extractedImageFiles.length}',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.arrow_forward_ios),
                                  onPressed: () {
                                    setState(() {
                                      _currentImageIndex =
                                          (_currentImageIndex + 1) %
                                              _extractedImageFiles.length;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
              const Divider(),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'archive_contains_images'.trParams({'count': _extractedImageFiles.length.toString()}),
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _handleFileDeleted() {
    widget.onFileDeleted?.call();
    Navigator.of(context).pop();
    Navigator.of(context).pop();
    Navigator.of(context).pop(true);
    AppSnackBar.show(context, message: 'file_deleted_successfully'.tr);
  }

  void _handleFileRenamed(String newPath) {
    setState(() {
      _currentFilePath = newPath;
    });
  }

  String get fileTypeForSaving {
    if (widget.selectedFormat == 'Image') {
      return _isSinglePageImage ? 'png' : 'zip';
    } else {
      switch (widget.selectedFormat) {
        case 'Word':
          return 'docx';
        case 'Excel':
          return 'xlsx';
        case 'PowerPoint':
          return 'pptx';
        default:
          return 'unknown';
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: 'convert_pdf'.tr,
        onBackPressed: () {
          Navigator.of(context).pop(false);
        },
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Padding(
              padding: const EdgeInsets.all(14.0),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  _buildLoadingContainer(),
                  if (_animationCompleted) ...[
                    const SizedBox(height: 36),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'converted_file'.tr,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    DocumentContainer(
                      filePath: _currentFilePath,
                      onTap: _openFile,
                      onDelete: _handleFileDeleted,
                      onFileRenamed: _handleFileRenamed,
                    ),
                  ],
                  SizedBox(height: MediaQuery.of(context).padding.bottom + 320),
                ],
              ),
            ),
          ),
          if (_animationCompleted)
            Positioned(
              left: 20,
              right: 20,
              bottom: MediaQuery.of(context).padding.bottom+10,
              child: SaveFileButton(
                filePath: _currentFilePath,
                fileType: fileTypeForSaving,
                buttonText: 'save'.tr,
                onSaveCompleted: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
              ),
            ),

        ],

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