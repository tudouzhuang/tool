import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:toolkit/screens/rearrange_file_screen/rearrange_file_drop.dart';
import 'package:toolkit/utils/app_snackbar.dart';
import '../../widgets/buttons/gradient_btn.dart';
import '../../widgets/tools/custom_svg_image.dart';
import '../../widgets/tools/info_card.dart';
import '../../widgets/tools/tools_app_bar.dart';
import 'rearrange_file_page_selection.dart';

class RearrangeFileScreen extends StatefulWidget {
  const RearrangeFileScreen({super.key});

  @override
  State<RearrangeFileScreen> createState() => _RearrangeFileScreenState();
}

class _RearrangeFileScreenState extends State<RearrangeFileScreen> {
  List<File> selectedFiles = [];
  String _documentErrorText = '';

  Future<void> _pickLocalDocuments() async {
    try {
      setState(() {
        _documentErrorText = "";
      });

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx'],
        allowMultiple: true,
        withData: false,
        withReadStream: true,
      );

      if (result != null && result.files.isNotEmpty) {
        List<File> pickedFiles = result.files
            .where((file) => file.path != null)
            .map((file) => File(file.path!))
            .toList();

        setState(() {
          selectedFiles.addAll(pickedFiles);
          _documentErrorText = '';
        });
      }
    } catch (e) {
      setState(() {
        AppSnackBar.show(context, message: 'Error selecting documents: ${e.toString()}');
      });
      print('Error in file picker: $e');
    }
  }

  void _removeDocument(int index) {
    setState(() {
      if (index >= 0 && index < selectedFiles.length) {
        selectedFiles.removeAt(index);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: ToolsAppBar(
        title: 'rearrange_files'.tr,
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
                    imagePath: 'assets/images/rearrange_image.svg',
                  ),
                  const SizedBox(height: 30),
                  InfoCard(
                    title: 'rearrange_pages_in_files'.tr,
                    description:
                    'rearrange_file_desc'.tr,
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
                        Padding(
                          padding: const EdgeInsets.only(top: 10, left: 16, bottom: 10),
                          child: Align(
                            alignment: Alignment.topLeft,
                            child: Text(
                              'select_file'.tr,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                          child: DottedFileDropZoneRearrange(
                            selectedFiles: selectedFiles,
                            onTap: _pickLocalDocuments,
                            onRemoveFile: _removeDocument,
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
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 26.0),
            child: CustomGradientButton(
              text: 'rearrange_file'.tr,
              onPressed: selectedFiles.isNotEmpty
                  ? () {
                if (selectedFiles.isNotEmpty) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RearrangeFilePageSelection(
                        selectedFile: selectedFiles.first, // Pass the first file
                      ),
                    ),
                  );
                }
              }
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}