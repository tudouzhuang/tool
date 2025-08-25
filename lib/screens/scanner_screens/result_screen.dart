import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:open_file/open_file.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../../provider/file_provider.dart';
import '../../utils/app_snackbar.dart';
import '../../widgets/buttons/save_document_btn.dart';
import '../../widgets/custom_appbar.dart';
import '../../widgets/tools/animated_loaded_container.dart';
import '../../widgets/tools/document_container.dart';

class ResultScreen extends StatefulWidget {
  final File wordDocument;

  const ResultScreen({super.key, required this.wordDocument});

  @override
  _ResultScreenState createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen>
    with SingleTickerProviderStateMixin {
  bool _animationCompleted = false;
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;

  // Add this to track the current file path
  late String _currentFilePath;

  @override
  void initState() {
    super.initState();
    // Initialize with the original file path
    _currentFilePath = widget.wordDocument.path;

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

  Future<void> _handleLoadingComplete() async {
    setState(() {
      _animationCompleted = true;
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _openDocument() async {
    try {
      // Use the current file path instead of the original path
      await OpenFile.open(_currentFilePath);
    } catch (e) {
      AppSnackBar.show(context, message: '${'failed_to_open_document'.tr}: $e');
    }
  }

  // Updated permission check that handles Android 10+ changes
  Future<bool> _checkAndRequestStoragePermission() async {
    if (Platform.isAndroid) {
      // For Android 10 (API 29) and above, we can use the media store without storage permission
      if (await _isAndroidVersionAbove29()) {
        return true; // No need for storage permission on Android 10+
      }

      // For older Android versions, request storage permission
      final status = await Permission.storage.status;
      if (!status.isGranted) {
        final result = await Permission.storage.request();
        return result.isGranted;
      }
      return status.isGranted;
    } else if (Platform.isIOS) {
      // iOS doesn't need explicit permission for this operation
      return true;
    }

    return false;
  }

  // Helper method to check Android version
  Future<bool> _isAndroidVersionAbove29() async {
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      return androidInfo.version.sdkInt >= 29; // Android 10 is API 29
    }
    return false;
  }

  void _handleFileDeleted() {
    // Clear all files from the provider when a file is deleted
    final fileProvider = Provider.of<FileProvider>(context, listen: false);
    fileProvider.clearAllFiles();

    Navigator.of(context).pop();
    Navigator.of(context).pop();
    Navigator.of(context).pop();
    AppSnackBar.show(context, message: 'file_deleted_successfully'.tr);
  }

  // Add this method to handle file rename
  void _handleFileRenamed(String newFilePath) {
    setState(() {
      _currentFilePath = newFilePath;
    });
  }

  // Method to handle save completion and clear files
  void _handleSaveCompleted() {
    // Clear all files from provider after successful save
    final fileProvider = Provider.of<FileProvider>(context, listen: false);
    fileProvider.clearAllFiles();

    // Navigate back to previous screens
    Navigator.of(context).pop(true);
    // Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(title: 'edit'.tr),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Padding(
              padding: const EdgeInsets.all(14.0),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  // Always show the loading container (it will show completed state)
                  _buildLoadingContainer(),
                  // Show document content only after animation completes
                  if (_animationCompleted) ...[
                    const SizedBox(height: 36),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '${'generated_document'.tr}:',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    DocumentContainer(
                      filePath: _currentFilePath, // Use current file path
                      onTap: _openDocument,
                      onDelete: _handleFileDeleted,
                      onFileRenamed: _handleFileRenamed, // Add this callback
                    ),
                  ],
                  SizedBox(height: MediaQuery
                      .of(context)
                      .padding
                      .bottom + 320),
                ],
              ),
            ),
          ),
          if (_animationCompleted)
            Positioned(
              left: 20,
              right: 20,
              bottom: MediaQuery
                  .of(context)
                  .padding
                  .bottom,
              child: SaveDocumentButton(
                documentFile: File(_currentFilePath),
                padding: const EdgeInsets.symmetric(
                    horizontal: 20.0, vertical: 20),
                onSaveCompleted: _handleSaveCompleted,
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