import 'package:flutter/material.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';
import 'package:toolkit/screens/compress_files_screen/file_drop_compress.dart';
import 'package:toolkit/utils/app_colors.dart';
import 'package:toolkit/utils/app_snackbar.dart';
import '../../widgets/buttons/gradient_btn.dart';
import '../../widgets/tools/custom_svg_image.dart';
import '../../widgets/tools/info_card.dart';
import '../../widgets/tools/tools_app_bar.dart';
import 'compress_file_result_screen.dart';
import 'compression_result_class.dart';
import 'file_compression_service.dart';

class CompressFileScreen extends StatefulWidget {
  const CompressFileScreen({super.key});

  @override
  State<CompressFileScreen> createState() => _CompressFileScreenState();
}

class _CompressFileScreenState extends State<CompressFileScreen> {
  String? _fileErrorText;

  final List<File> _selectedFiles = [];
  bool _isCompressing = false;
  double _compressionQuality = 50;

  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return 'file_size_format'.trParams({
        'size': bytes.toString(),
        'unit': 'bytes'.tr
      });
    } else if (bytes < 1024 * 1024) {
      return 'file_size_format'.trParams({
        'size': (bytes / 1024).toStringAsFixed(1),
        'unit': 'kilobytes'.tr
      });
    } else {
      return 'file_size_format'.trParams({
        'size': (bytes / (1024 * 1024)).toStringAsFixed(1),
        'unit': 'megabytes'.tr
      });
    }
  }

  Future<void> _pickFiles() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'ppt', 'pptx', 'jpg', 'jpeg', 'png'],
      );

      if (result != null && result.paths.isNotEmpty) {
        final validExtensions = ['pdf', 'doc', 'docx', 'ppt', 'pptx', 'jpg', 'jpeg', 'png'];
        const int minFileSizeMB = 1;
        const int minFileSizeBytes = minFileSizeMB * 1024 * 1024;

        List<File> pickedFiles = result.paths
            .where((path) => path != null)
            .map((path) => File(path!))
            .toList();

        List<File> validFiles = [];
        List<String> rejectedFiles = [];
        List<String> invalidExtensionFiles = [];
        List<String> duplicateFiles = [];

        final existingFileNames = _selectedFiles.map((f) => f.path.split('/').last).toSet();

        for (File file in pickedFiles) {
          final fileName = file.path.split('/').last;
          final ext = fileName.split('.').last.toLowerCase();

          // Extension check
          if (!validExtensions.contains(ext)) {
            invalidExtensionFiles.add(fileName);
            continue;
          }

          // Duplicate file name check
          if (existingFileNames.contains(fileName)) {
            duplicateFiles.add(fileName);
            continue;
          }

          try {
            final fileSize = await file.length();

            if (fileSize < minFileSizeBytes) {
              rejectedFiles.add('$fileName (${'too_small'.tr}: ${_formatFileSize(fileSize)})');
            } else {
              validFiles.add(file);
            }
          } catch (e) {
            invalidExtensionFiles.add(fileName);
          }
        }

        if (mounted) {
          setState(() {
            _selectedFiles.addAll(validFiles);

            _fileErrorText = [
              if (invalidExtensionFiles.isNotEmpty) 'invalid_file_formats'.tr,
              if (rejectedFiles.isNotEmpty) 'files_must_be_at_least_mb'.tr,
              if (duplicateFiles.isNotEmpty) 'duplicate_files_skipped'.tr,
              if (validFiles.isEmpty && pickedFiles.isNotEmpty) 'no_valid_files_selected'.tr,
            ].join(' | ');
          });

          // Show warning message if any file is rejected
          final warnings = [
            if (duplicateFiles.isNotEmpty) '${duplicateFiles.length} ${'duplicates'.tr}',
            if (rejectedFiles.isNotEmpty) '${rejectedFiles.length} ${'rejected_too_small'.tr}',
            if (invalidExtensionFiles.isNotEmpty) '${invalidExtensionFiles.length} ${'invalid_formats'.tr}',
          ];

          if (warnings.isNotEmpty) {
            AppSnackBar.show(
              context,
              message: '${'some_files_were_skipped'.tr}: ${warnings.join(', ')}',
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _fileErrorText = '${'error_selecting_files'.tr}: $e';
        });
      }
    }
  }

  Future<void> _compressFiles() async {
    if (_selectedFiles.isEmpty) {
      if (mounted) {
        AppSnackBar.show(context, message: 'please_select_at_least_one_file'.tr);
      }
      return;
    }

    if (!mounted) return;

    setState(() {
      _isCompressing = true;
    });

    try {
      List<CompressionResult> compressionResults = await FileCompressor.compressBatchWithStatus(
        _selectedFiles,
        quality: _compressionQuality.round(),
      );
      List<File> compressedFiles = compressionResults.map((result) => result.file).toList();

      if (!mounted) return;

      setState(() {
        _isCompressing = false;
      });

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => CompressedFileResultScreen(
            originalFiles: _selectedFiles,
            compressedFiles: compressedFiles,
            compressionResults: compressionResults,
          ),
        ),
      ).then((deletedIndices) {
        // Handle returned deleted file indices
        if (deletedIndices != null && deletedIndices is List<int>) {
          setState(() {
            // Sort indices in descending order to avoid index shifting issues
            deletedIndices.sort((a, b) => b.compareTo(a));
            for (int index in deletedIndices) {
              if (index < _selectedFiles.length) {
                _selectedFiles.removeAt(index);
              }
            }
          });
        }
      });

    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isCompressing = false;
      });

      AppSnackBar.show(context, message: '${'error_compressing_files'.tr}: $e');
    }
  }

  void _removeFile(int index) {
    if (mounted) {
      setState(() {
        _selectedFiles.removeAt(index);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: ToolsAppBar(
        title: ('compress_file'.tr),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const CustomSvgImage(
                      imagePath: 'assets/images/compress_file_image.svg'),
                  const SizedBox(height: 30),
                  InfoCard(
                    title: ('reduce_file_size'.tr),
                    description: ('reduce_file_size_description'.tr),
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
                              ('select_file'.tr),
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
                          child: DottedFileDropZoneCompress(
                            selectedFiles: _selectedFiles,
                            onTap: _pickFiles,
                            onRemoveFile: _removeFile,
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (_fileErrorText != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12.0),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _fileErrorText!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),

                  if (_selectedFiles.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'compression_quality'.tr,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Text('maximum_compression'.tr),
                              Expanded(
                                child: Slider(
                                  value: _compressionQuality,
                                  min: 25,
                                  max: 100,
                                  divisions: 3,
                                  label: _compressionQuality.round().toString(),
                                  activeColor: AppColors.primary,
                                  onChanged: (double value) {
                                    if (mounted) {
                                      setState(() {
                                        _compressionQuality = value;
                                      });
                                    }
                                  },
                                ),
                              ),
                              Text('maximum_quality'.tr),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 26.0),
            child: CustomGradientButton(
              text: _isCompressing ? 'compressing'.tr : 'compress'.tr,
              onPressed: _isCompressing ? null : _compressFiles,
            ),
          ),
        ],
      ),
    );
  }
}