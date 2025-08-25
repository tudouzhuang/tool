import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../provider/file_provider.dart';
import '../../utils/app_snackbar.dart';
import '../../widgets/buttons/gradient_btn.dart';
import '../../widgets/tools/custom_svg_image.dart';
import '../../widgets/tools/info_card.dart';
import '../../widgets/tools/tools_app_bar.dart';
import '../../widgets/tools/dotted_file_drop.dart';
import '../../widgets/tools/ocr_file_selection.dart';
import '../scanner_screens/batch_result_screen.dart';
import '../ocr_screens/ocr_camera_screen.dart';

class EditFileScreen extends StatefulWidget {
  const EditFileScreen({super.key});

  @override
  State<EditFileScreen> createState() => _EditFileScreenState();
}

class _EditFileScreenState extends State<EditFileScreen> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final fileProvider = Provider.of<FileProvider>(context, listen: false);
        final newFile = File(pickedFile.path);
        // Clear existing files and add the new single file
        fileProvider.clearAllFiles();
        fileProvider.addFiles([newFile]);
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.show(context, message: '${'error_selecting_image'.tr}: $e');
      }
    }
  }

  Future<void> _scanNewDocument() async {
    try {
      // Navigate to the camera screen for scanning new documents
      final List<File>? capturedImages = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const OcrCameraScreen(),
        ),
      );

      if (capturedImages != null && capturedImages.isNotEmpty) {
        final fileProvider = Provider.of<FileProvider>(context, listen: false);
        // Take only the first captured image
        fileProvider.clearAllFiles();
        fileProvider.addFiles([capturedImages.first]);
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.show(context,
            message: '${'error_capturing_document'.tr}: $e');
      }
    }
  }

  void _removeFile(int index) {
    final fileProvider = Provider.of<FileProvider>(context, listen: false);
    fileProvider.removeFile(index);

    if (mounted) {
      AppSnackBar.show(context, message: 'image_removed_successfully'.tr);
    }
  }

  Future<void> _editFile() async {
    final fileProvider = Provider.of<FileProvider>(context, listen: false);

    if (!fileProvider.hasFiles) {
      AppSnackBar.show(context, message: 'please_select_an_image'.tr);
      return;
    }

    try {
      // Navigate to BatchResultScreen with the selected file
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BatchResultScreen(
            batchImages: fileProvider.selectedFiles,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        AppSnackBar.show(context, message: '${'error_processing_file'.tr}: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: ToolsAppBar(
        title: 'edit_file'.tr, // Changed from 'edit_files' to 'edit_file'
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(30.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const CustomSvgImage(
                    imagePath: 'assets/images/edit_file_img.svg',
                  ),
                  const SizedBox(height: 30),
                  InfoCard(
                    title: 'edit_file'.tr,
                    // Changed from 'edit_files' to 'edit_file'
                    description:
                        'edit_file_description'.tr, // Changed description key
                  ),
                  const SizedBox(height: 24),
                  // Combined container with shadow
                  Container(
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
                        // File selection section
                        FileSelectionSection(
                          sectionTitle: 'choose_image'.tr,
                          // Changed from 'choose_images' to 'choose_image'
                          onSelectFiles: _pickImage,
                          // Changed method name
                          onScanNew: _scanNewDocument,
                        ),
                        // Dotted file drop zone - Now using Consumer to listen to provider changes
                        Padding(
                          padding: const EdgeInsets.only(
                              left: 16, right: 16, bottom: 16),
                          child: Consumer<FileProvider>(
                            builder: (context, fileProvider, child) {
                              return DottedFileDropZone(
                                selectedImages: fileProvider.selectedFiles,
                                onTap: _pickImage, // Changed method name
                                onRemoveImage: _removeFile,
                                emptyStateText:
                                    'Click to choose image'.tr, // Changed text
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 30.0, vertical: 26.0),
            child: CustomGradientButton(
              text: 'next'.tr,
              onPressed: _editFile, // Changed method name
            ),
          ),
        ],
      ),
    );
  }
}
