import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:open_file/open_file.dart';
import 'package:toolkit/widgets/custom_appbar.dart';
import '../../services/word_document_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_snackbar.dart';
import '../../widgets/buttons/save_document_btn.dart';
import '../../widgets/tools/animated_loaded_container.dart';
import '../../widgets/tools/document_container.dart';

class ExtractedTextScreen extends StatefulWidget {
  final String extractedText;
  final String? detectedLanguage;

  const ExtractedTextScreen({
    super.key,
    required this.extractedText,
    this.detectedLanguage,
  });

  @override
  State<ExtractedTextScreen> createState() => _ExtractedTextScreenState();
}

class _ExtractedTextScreenState extends State<ExtractedTextScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  bool _isLoading = true;
  bool _animationCompleted = false;
  bool _isSaving = false;
  String? _savedFilePath;
  bool _fileRenamed = false;
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;
  final WordDocumentService _wordDocumentService = WordDocumentService();
  static const int maxFileSizeBytes = 100 * 1024 * 1024;
  static const int maxTextSizeBytes = 500 * 1024 * 1024;

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
        _handleLoadingComplete();
      }
    });

    _animationController.forward();
  }

  int _getTextSizeInBytes(String Text) {
    return utf8.encode(Text).length;
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  Future<int> _getFileSizeInBytes(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        return await file.length();
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  Future<void> _handleLoadingComplete() async {
    setState(() {
      _isLoading = false;
      _animationCompleted = true;
      _textController.text = widget.extractedText;
    });

    await _saveAsWord();
  }

  @override
  void dispose() {
    _textController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _saveAsWord() async {
    try {
      setState(() {
        _isSaving = true;
      });

      // Check text size before creating document
      final textSizeBytes = _getTextSizeInBytes(_textController.text);

      if (textSizeBytes > maxTextSizeBytes) {
        setState(() {
          _isSaving = false;
        });
        AppSnackBar.show(context,
            message:
                '${'text_too_large'.tr}: ${_formatFileSize(textSizeBytes)}. ${'max_allowed'.tr}: ${_formatFileSize(maxTextSizeBytes)}');
        return;
      }

      final filePath =
          await _wordDocumentService.createWordDocument(_textController.text);

      // Check created file size
      final fileSizeBytes = await _getFileSizeInBytes(filePath);

      if (fileSizeBytes > maxFileSizeBytes) {
        // Delete the oversized file
        final file = File(filePath);
        if (await file.exists()) {
          await file.delete();
        }

        setState(() {
          _isSaving = false;
        });

        AppSnackBar.show(context,
            message:
                '${'file_too_large'.tr}: ${_formatFileSize(fileSizeBytes)}. ${'max_allowed'.tr}: ${_formatFileSize(maxFileSizeBytes)}');
        return;
      }

      setState(() {
        _isSaving = false;
        _savedFilePath = filePath;
      });

      // Show success message with file size
    } catch (e) {
      setState(() {
        _isSaving = false;
      });
      AppSnackBar.show(context, message: '${'error_saving_file'.tr}: $e');
    }
  }

  Future<void> _handleFileDeleted() async {
    try {
      if (_savedFilePath != null) {
        final file = File(_savedFilePath!);
        if (await file.exists()) {
          await file.delete();
        }
      }
      if (mounted) {
        Navigator.of(context).pop(true);
        Navigator.of(context).pop(true);
        AppSnackBar.show(context, message: 'file_deleted_successfully'.tr);
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.show(context, message: '${'error_deleting_file'.tr}: $e');
      }
    }
  }

  Future<void> _openDocument() async {
    if (_savedFilePath == null) return;

    try {
      final result = await OpenFile.open(_savedFilePath!);
      if (result.type != ResultType.done) {
        AppSnackBar.show(context,
            message: '${'could_not_open_file'.tr}: ${result.message}');
      }
    } catch (e) {
      AppSnackBar.show(context, message: '${'error_opening_file'.tr}: $e');
    }
  }

  void _handleFileRenamed(String newPath) {
    setState(() {
      _savedFilePath = newPath;
      _fileRenamed = true;
    });
  }

  Future<void> _copyToClipboard() async {
    try {
      await Clipboard.setData(ClipboardData(text: _textController.text));
      if (mounted) {
        AppSnackBar.show(context, message: 'text_copied_to_clipboard'.tr);
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.show(context, message: '${'error_copying_text'.tr}: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: 'ocr'.tr,
        onBackPressed: () {
          Navigator.of(context).pop(false);
        },
      ),
      body: WillPopScope(
        onWillPop: () async {
          Navigator.of(context).pop(false);
          return false;
        },
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Padding(
                padding: const EdgeInsets.all(14.0),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    if (_isLoading || _animationCompleted)
                      _buildLoadingContainer(),
                    const SizedBox(height: 36),
                    if (!_isLoading) ...[
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'extracted_text_file'.tr,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (_savedFilePath != null)
                        DocumentContainer(
                          filePath: _savedFilePath!,
                          onTap: _openDocument,
                          onDelete: _handleFileDeleted,
                          onFileRenamed: _handleFileRenamed,
                        ),
                      if (_savedFilePath == null)
                        Container(
                          width: double.infinity,
                          height: 70,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              'no_file_available'.tr,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'extracted_text'.tr,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: MediaQuery.of(context).size.height * 0.4,
                        ),
                        child: Column(
                          children: [
                            _buildTextContainer(),
                            const SizedBox(height: 60),
                          ],
                        ),
                      ),
                    ],
                    SizedBox(
                        height: MediaQuery.of(context).padding.bottom + 20),
                  ],
                ),
              ),
            ),
            if (!_isLoading && _savedFilePath != null)
              Positioned(
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).padding.bottom + 20,
                child: SaveDocumentButton(
                  documentFile: File(_savedFilePath!),
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  skipTimestamp: _fileRenamed,
                  onSaveCompleted: () {
                    Navigator.of(context).pop(true);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextContainer() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      // Remove the maxHeight constraint that was causing issues
      constraints: BoxConstraints(
        minHeight: 200, // Set minimum height instead
        maxHeight: MediaQuery.of(context).size.height *
            0.4, // Keep reasonable max height
      ),
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
          // Add size info at the top
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                onPressed: _copyToClipboard,
                icon: const Icon(
                  Icons.content_copy,
                  size: 20,
                ),
                style: IconButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  animationDuration: const Duration(milliseconds: 300),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Scrollbar(
              // Add scrollbar for better UX
              child: SingleChildScrollView(
                // Wrap TextField in SingleChildScrollView
                child: TextField(
                  controller: _textController,
                  maxLines: null,
                  // Allow unlimited lines
                  minLines: 8,
                  // Set minimum lines to ensure good height
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: (value) {
                    setState(() {}); // Refresh size info when text changes
                  },
                ),
              ),
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
