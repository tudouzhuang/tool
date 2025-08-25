import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'dart:io';
import 'dart:async';
import 'package:open_file/open_file.dart';
import '../../services/word_to_img_service.dart';
import '../../services/word_to_pdf_service.dart';
import '../../utils/app_snackbar.dart';
import '../../widgets/buttons/save_zip_png_btn.dart';
import '../../widgets/custom_appbar.dart';
import '../../widgets/tools/animated_loaded_container.dart';
import '../../widgets/tools/document_container.dart';

class WordSaveScreen extends StatefulWidget {
  final File selectedWordFile;
  final File convertedFile;
  final String selectedFormat;
  final VoidCallback? onFileDeleted;

  const WordSaveScreen({
    super.key,
    required this.selectedWordFile,
    required this.convertedFile,
    required this.selectedFormat,
    this.onFileDeleted,
  });

  @override
  State<WordSaveScreen> createState() => _WordSaveScreenState();
}

class _WordSaveScreenState extends State<WordSaveScreen>
    with SingleTickerProviderStateMixin {
  bool isConverting = true;
  bool isCompleted = false;
  String currentFileName = '';
  bool _animationCompleted = false;
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;
  File? _convertedFile;
  String? _errorMessage;
  late String _currentFilePath;

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
    _progressAnimation.addListener(() => setState(() {}));
    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          isConverting = false;
          _animationCompleted = true;
          isCompleted = true;
        });
      }
    });

    final originalName =
        widget.selectedWordFile.path.split('/').last.split('.').first;
    currentFileName = originalName;
    _convertedFile = widget.convertedFile;
    _currentFilePath = widget.convertedFile.path;

    // Start the animation (conversion is already done)
    _startAnimation();
  }

  Future<void> _startAnimation() async {
    try {
      // Start the animation
      _animationController.forward();

      // Wait for animation to complete
      await _animationController.forward();

    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        isConverting = false;
        _animationCompleted = true;
        isCompleted = false;
      });

      if (mounted) {
        AppSnackBar.show(
          context,
          message: 'conversion_failed'.trParams({'error': e.toString()}),
        );
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String get fileName {
    String extension = widget.selectedFormat.toLowerCase() == 'pdf' ? 'pdf' : 'png';
    return '$currentFileName.$extension';
  }

  String get fileSize {
    if (_convertedFile == null) return '0.00';
    return (_convertedFile!.lengthSync() / (1024 * 1024)).toStringAsFixed(2);
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
    if (_convertedFile == null) {
      AppSnackBar.show(context, message: 'file_not_found_or_not_converted'.tr);
      return;
    }

    if (_convertedFile!.existsSync()) {
      try {
        final result = await OpenFile.open(_currentFilePath);
        if (result.type != ResultType.done && mounted) {
          AppSnackBar.show(context,
              message: 'cannot_open_file'.trParams({'message': result.message}));
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

  Future<void> _shareFile() async {
    if (_convertedFile == null) {
      AppSnackBar.show(context, message: 'file_not_found_or_not_converted'.tr);
      return;
    }

    try {
      if (widget.selectedFormat.toLowerCase() == 'pdf') {
        final wordToPdfService = WordToPdfService();
        await wordToPdfService.shareDocument(_convertedFile!);
      } else {
        final wordToImageService = WordToImageService();
        await wordToImageService.shareDocument(_convertedFile!);
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.show(context,
            message: 'error_sharing_file'.trParams({'error': e.toString()}));
      }
    }
  }

  void _handleFileDeleted() {
    widget.onFileDeleted?.call();
    Navigator.of(context).pop();
    Navigator.of(context).pop(true);
    AppSnackBar.show(context, message: 'file_deleted_successfully'.tr);
  }

  void _handleFileRenamed(String newPath) {
    setState(() {
      _currentFilePath = newPath;
    });
  }

  String get _screenTitle {
    return widget.selectedFormat.toLowerCase() == 'pdf'
        ? 'convert_word_to_pdf'.tr
        : 'convert_word_to_image'.tr;
  }

  String get _convertedFileLabel {
    return widget.selectedFormat.toLowerCase() == 'pdf'
        ? 'converted_pdf_file'.tr
        : 'converted_image_file'.tr;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: _screenTitle,
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
                  if (_animationCompleted && _convertedFile != null) ...[
                    const SizedBox(height: 36),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _convertedFileLabel,
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
                    const SizedBox(height: 20),
                  ],
                  if (_animationCompleted && _errorMessage != null) ...[
                    const SizedBox(height: 36),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red[200]!),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Colors.red[700],
                            size: 48,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'conversion_failed'.tr,
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.red[700],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _errorMessage!,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Colors.red[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pop(false);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red[600],
                              foregroundColor: Colors.white,
                            ),
                            child: Text('go_back'.tr),
                          ),
                        ],
                      ),
                    ),
                  ],
                  SizedBox(height: MediaQuery.of(context).padding.bottom + 320),
                ],
              ),
            ),
          ),
          if (_animationCompleted && _convertedFile != null)
            Positioned(
              left: 20,
              right: 20,
              bottom: MediaQuery.of(context).padding.bottom,
              child: SaveFileButton(
                filePath: _currentFilePath,
                fileType: widget.selectedFormat.toLowerCase(),
                buttonText: widget.selectedFormat.toLowerCase() == 'pdf'
                    ? 'save_pdf'.tr
                    : 'save_image'.tr,
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