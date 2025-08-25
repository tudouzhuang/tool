import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:get/get.dart';
import '../../utils/app_snackbar.dart';
import '../../widgets/buttons/gradient_btn.dart';
import '../../widgets/tools/custom_svg_image.dart';
import '../../widgets/tools/file_selection_container.dart';
import '../../widgets/tools/info_card.dart';
import '../../widgets/tools/tools_app_bar.dart';
import 'format_selection_screen.dart';

class ConvertImgMainScreen extends StatefulWidget {
  const ConvertImgMainScreen({super.key});

  @override
  State<ConvertImgMainScreen> createState() => _ConvertImgMainScreenState();
}

class _ConvertImgMainScreenState extends State<ConvertImgMainScreen> {
  List<File> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImages() async {
    try {
      final List<XFile> pickedFiles = await _picker.pickMultiImage();

      if (pickedFiles.isNotEmpty) {
        setState(() {
          _selectedImages
              .addAll(pickedFiles.map((file) => File(file.path)).toList());
        });
      }
    } catch (e) {
      AppSnackBar.show(context, message: '${'error_selecting_images'.tr}: $e');
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _convertImages() async {
    if (_selectedImages.isEmpty) {
      AppSnackBar.show(context,
          message: 'please_select_at_least_one_image_first'.tr);
      return;
    }

    setState(() {});

    try {
      // Simulate short delay
      await Future.delayed(const Duration(milliseconds: 500));

      setState(() {});

      // Pass all selected images to SelectFormatScreen and wait for result
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              SelectFormatScreen(selectedImages: _selectedImages),
        ),
      );

      // Check if we need to clear images (result will be true if file was deleted)
      if (result == true) {
        setState(() {
          _selectedImages = [];
        });
      }
    } catch (e) {
      setState(() {});
      AppSnackBar.show(context, message: '${'error_processing_images'.tr}: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: ToolsAppBar(
        title: 'convert_image'.tr,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(30.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const CustomSvgImage(imagePath: 'assets/images/convert_image.svg'),
                  const SizedBox(height: 30),
                  InfoCard(
                    title: 'convert_image_format'.tr,
                    description: 'convert_image_description'.tr,
                  ),
                  const SizedBox(height: 24),
                  // Combined container with shadow
                  FileSelectionContainer(
                    title: 'select_images'.tr,
                    emptyStateText: 'click_to_choose_file'.tr,
                    selectedFiles: _selectedImages,
                    onTap: _pickImages,
                    onRemoveFile: _removeImage,
                    isMultipleSelection: true,
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding:
            const EdgeInsets.symmetric(horizontal: 30.0, vertical: 20.0),
            child: CustomGradientButton(
              text: 'next'.tr,
              onPressed: _convertImages,
            ),
          ),
        ],
      ),
    );
  }
}