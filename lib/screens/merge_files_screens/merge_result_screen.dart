import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../../utils/app_snackbar.dart';
import '../../widgets/buttons/save_zip_png_btn.dart';
import '../../widgets/custom_appbar.dart';
import '../../widgets/tools/animated_loaded_container.dart';
import '../../widgets/tools/document_container.dart';

class MergeResultScreen extends StatefulWidget {
  final String mergedFilePath;
  final VoidCallback? onSaveAndReturn;

  const MergeResultScreen({
    super.key,
    required this.mergedFilePath,
    this.onSaveAndReturn,
  });

  @override
  State<MergeResultScreen> createState() => _MergeResultScreenState();
}

class _MergeResultScreenState extends State<MergeResultScreen>
    with SingleTickerProviderStateMixin {
  bool isConverting = true;
  bool isCompleted = false;
  String currentFileName = '';
  bool _animationCompleted = false;
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;
  late String _currentFilePath; // Track current file path
  late String _permanentFilePath; // Add permanent file path

  @override
  void initState() {
    super.initState();
    _currentFilePath = widget.mergedFilePath; // Initialize with original path
    _initializePermanentFile(); // Create permanent copy
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

    final originalName = widget.mergedFilePath.split('/').last.split('.').first;
    currentFileName = originalName;
    _animationController.forward();
  }

  // Create a permanent copy of the merged file
  Future<void> _initializePermanentFile() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final originalName = path.basenameWithoutExtension(widget.mergedFilePath);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _permanentFilePath = '${appDir.path}/${originalName}_$timestamp.pdf';

      // Copy the temporary file to permanent location
      final tempFile = File(widget.mergedFilePath);
      if (await tempFile.exists()) {
        await tempFile.copy(_permanentFilePath);
        setState(() {
          _currentFilePath = _permanentFilePath;
        });
      }
    } catch (e) {
      debugPrint('Error creating permanent file: $e');
      // If permanent copy fails, keep using the original path
      _permanentFilePath = widget.mergedFilePath;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    // Clean up temporary files but keep the permanent one
    _cleanupTempFile();
    super.dispose();
  }

  void _cleanupTempFile() {
    try {
      // Only delete the original temp file, not the permanent one
      if (widget.mergedFilePath != _permanentFilePath) {
        final tempFile = File(widget.mergedFilePath);
        if (tempFile.existsSync()) {
          tempFile.deleteSync();
        }
      }
    } catch (e) {
      debugPrint('Error cleaning up temp file: $e');
    }
  }

  String get fileName {
    return _currentFilePath.split('/').last;
  }

  String get fileSize {
    final file = File(_currentFilePath);
    if (file.existsSync()) {
      return (file.lengthSync() / (1024 * 1024)).toStringAsFixed(2);
    }
    return "0.00";
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
        final result = await OpenFile.open(_currentFilePath);
        if (result.type != ResultType.done && mounted) {
          AppSnackBar.show(context,
              message: '${'cannot_open_file'.tr}: ${result.message}');
        }
      } catch (e) {
        if (mounted) {
          AppSnackBar.show(context,
              message: '${'error_opening_file'.tr}: ${e.toString()}');
        }
      }
    } else if (mounted) {
      AppSnackBar.show(context, message: 'file_not_found_or_not_processed'.tr);
    }
  }

  void _handleFileDeleted() {
    // Clean up the current file
    try {
      final file = File(_currentFilePath);
      if (file.existsSync()) {
        file.deleteSync();
      }
    } catch (e) {
      debugPrint('Error deleting file: $e');
    }

    if (widget.onSaveAndReturn != null) {
      widget.onSaveAndReturn!();
    }
    Navigator.of(context).pop();
    Navigator.of(context).pop();
    AppSnackBar.show(context, message: 'file_deleted_successfully'.tr);
  }

  void _handleSaveCompleted() {
    if (widget.onSaveAndReturn != null) {
      widget.onSaveAndReturn!();
    }
    Navigator.of(context).pop();
    Navigator.of(context).pop();
    AppSnackBar.show(context, message: 'file_saved_successfully'.tr);
  }

  void _handleFileRenamed(String newPath) {
    setState(() {
      _currentFilePath = newPath;
    });
    if (mounted) {
      AppSnackBar.show(context, message: 'file_renamed_successfully'.tr);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: 'merge_results'.tr,
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
                        'merged_pdf_file'.tr,
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
              left: 0,
              right: 0,
              bottom: MediaQuery.of(context).padding.bottom,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20),
                child: SaveFileButton(
                  filePath: _currentFilePath,
                  fileType: 'pdf',
                  buttonText: 'save'.tr,
                  onSaveCompleted: _handleSaveCompleted,
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
