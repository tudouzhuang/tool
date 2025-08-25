import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;
import '../../utils/app_snackbar.dart';
import '../../widgets/buttons/gradient_btn.dart';
import '../../widgets/tools/custom_svg_image.dart';
import '../../widgets/tools/dotted_file_drop.dart';
import '../../widgets/tools/info_card.dart';
import '../../widgets/tools/ocr_file_selection.dart';
import '../../widgets/tools/tools_app_bar.dart';
import 'extracted_text_screen.dart';
import 'ocr_camera_screen.dart';

class OcrScreen extends StatefulWidget {
  const OcrScreen({super.key});

  @override
  State<OcrScreen> createState() => _OcrScreenState();
}

class _OcrScreenState extends State<OcrScreen> {
  final List<File> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();
  String _extractedText = '';
  bool _shouldClearImages = false;
  bool _isProcessing = false;

  Future<void> _pickImages(ImageSource source) async {
    try {
      if (source == ImageSource.camera) {
        final List<File>? capturedImages = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const OcrCameraScreen(),
          ),
        );

        if (capturedImages != null && capturedImages.isNotEmpty) {
          setState(() {
            _selectedImages.addAll(capturedImages);
            _shouldClearImages = false;
          });
        }
      } else {
        final List<XFile> pickedFiles = await _picker.pickMultiImage();
        if (pickedFiles.isNotEmpty) {
          setState(() {
            _selectedImages
                .addAll(pickedFiles.map((file) => File(file.path)).toList());
            _shouldClearImages = false;
          });
        }
      }
    } catch (e) {
      print('error_picking_images'.trParams({'error': e.toString()}));
    }
  }

  // Enhanced image preprocessing for better OCR accuracy
  Future<File> _preprocessImage(File imageFile) async {
    try {
      // Read the image
      final bytes = await imageFile.readAsBytes();
      img.Image? image = img.decodeImage(bytes);

      if (image == null) return imageFile;

      if (image.width < 300 || image.height < 300) {
        final scale =
            300 / (image.width < image.height ? image.width : image.height);
        image = img.copyResize(image,
            width: (image.width * scale).round(),
            height: (image.height * scale).round(),
            interpolation: img.Interpolation.cubic);
      }

      image = img.grayscale(image);

      image = _enhanceContrast(image);

      image = img.gaussianBlur(image, radius: 1);

      // 5. Sharpen the image slightly
      image = _sharpenImage(image);

      // Save the processed image temporarily
      final processedBytes = img.encodePng(image);
      final tempDir = Directory.systemTemp;
      final processedFile = File(
          '${tempDir.path}/processed_${DateTime.now().millisecondsSinceEpoch}.png');
      await processedFile.writeAsBytes(processedBytes);

      return processedFile;
    } catch (e) {
      print('error_preprocessing_image'.trParams({'error': e.toString()}));
      return imageFile; // Return original if preprocessing fails
    }
  }

  // Enhance contrast using simple histogram stretching
  img.Image _enhanceContrast(img.Image image) {
    // Find min and max pixel values
    int min = 255, max = 0;
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        final gray = img.getLuminance(pixel).round();
        if (gray < min) min = gray;
        if (gray > max) max = gray;
      }
    }

    // Stretch histogram if there's contrast to improve
    if (max > min) {
      final scale = 255.0 / (max - min);
      for (int y = 0; y < image.height; y++) {
        for (int x = 0; x < image.width; x++) {
          final pixel = image.getPixel(x, y);
          final gray = img.getLuminance(pixel).round();
          final newGray = ((gray - min) * scale).round().clamp(0, 255);
          image.setPixel(x, y, img.ColorRgb8(newGray, newGray, newGray));
        }
      }
    }

    return image;
  }

  // Simple sharpening filter
  img.Image _sharpenImage(img.Image image) {
    return img.convolution(image,
        filter: [0, -1, 0, -1, 5, -1, 0, -1, 0], div: 3);
  }

  // Clean up extracted text
  String _cleanExtractedText(String text) {
    text = text.replaceAll(RegExp(r'\s+'), ' ');
    text = text.replaceAll(RegExp(r'\n\s*\n'), '\n\n');

    // Fix common OCR errors
    text = text.replaceAll(RegExp(r'\b0(?=\w)'), 'O'); // 0 -> O in words
    text = text.replaceAll(RegExp(r'\b1(?=\w)'), 'I'); // 1 -> I in words
    text = text.replaceAll(RegExp(r'rn'), 'm'); // Common rn -> m error
    text = text.replaceAll(RegExp(r'\|'), 'I'); // | -> I

    return text.trim();
  }

  Future<void> _extractTextFromImages() async {
    if (_selectedImages.isEmpty) {
      AppSnackBar.show(context, message: 'select_at_least_one_image'.tr);
      return;
    }

    setState(() {
      _extractedText = '';
      _isProcessing = true;
    });

    try {
      // Create text recognizer with Latin script for better accuracy
      final textRecognizer =
          TextRecognizer(script: TextRecognitionScript.latin);

      StringBuffer combinedText = StringBuffer();
      bool textFound = false;
      List<File> tempFiles = []; // Keep track of temporary preprocessed files

      for (int i = 0; i < _selectedImages.length; i++) {
        // Preprocess image for better OCR
        final preprocessedImage = await _preprocessImage(_selectedImages[i]);
        tempFiles.add(preprocessedImage);

        final inputImage = InputImage.fromFilePath(preprocessedImage.path);
        final RecognizedText recognizedText =
            await textRecognizer.processImage(inputImage);

        if (recognizedText.text.isNotEmpty) {
          textFound = true;

          // Add image separator if multiple images
          if (_selectedImages.length > 1) {
            combinedText.writeln(
                'image_header'.trParams({'number': (i + 1).toString()}));
          }

          // Clean and add the extracted text
          final cleanedText = _cleanExtractedText(recognizedText.text);
          combinedText.writeln(cleanedText);
          combinedText.writeln();
        }
      }

      textRecognizer.close();

      // Clean up temporary files
      for (final tempFile in tempFiles) {
        if (tempFile.path !=
            _selectedImages[tempFiles.indexOf(tempFile)].path) {
          try {
            await tempFile.delete();
          } catch (e) {
            print('error_deleting_temp_file'.trParams({'error': e.toString()}));
          }
        }
      }

      setState(() {
        _extractedText = combinedText.toString();
        _isProcessing = false;
      });

      if (textFound) {
        final shouldClear = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                ExtractedTextScreen(extractedText: _extractedText),
          ),
        );

        if (shouldClear == true) {
          _clearSelectedImages();
        }
      } else {
        AppSnackBar.show(context, message: 'no_text_in_images'.tr);
      }
    } catch (e) {
      print('error_in_ocr'.trParams({'error': e.toString()}));
      AppSnackBar.show(context,
          message: 'error_processing_images'.trParams({'error': e.toString()}));
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  void _clearSelectedImages() {
    setState(() {
      _selectedImages.clear();
      _extractedText = '';
      _shouldClearImages = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: ToolsAppBar(
        title: 'ocr'.tr,
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
                      imagePath: 'assets/images/ocr_image.svg'),
                  const SizedBox(height: 30),
                  InfoCard(
                    title: 'extract_text_from_files'.tr,
                    description: 'extract_text_description'.tr,
                  ),
                  const SizedBox(height: 24),
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
                        FileSelectionSection(
                          sectionTitle: 'choose_file'.tr,
                          onSelectFiles: () => _pickImages(ImageSource.gallery),
                          onScanNew: () => _pickImages(ImageSource.camera),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(
                              left: 16, right: 16, bottom: 16),
                          child: DottedFileDropZone(
                            selectedImages: _selectedImages,
                            onTap: () => _pickImages(ImageSource.gallery),
                            onRemoveImage: _removeImage,
                            isEmpty:
                                _shouldClearImages || _selectedImages.isEmpty,
                            emptyStateText: 'click_to_choose_files'.tr,
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
                const EdgeInsets.symmetric(horizontal: 30.0, vertical: 20.0),
            child: CustomGradientButton(
              text: _isProcessing ? 'processing'.tr : 'extract_text'.tr,
              onPressed: _isProcessing ? null : _extractTextFromImages,
            ),
          ),
        ],
      ),
    );
  }
}
