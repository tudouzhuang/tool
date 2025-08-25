// file_options_menu.dart (updated)
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path/path.dart' as path;
import 'package:share_plus/share_plus.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_snackbar.dart';

class FileOptionsMenu extends StatelessWidget {
  final String filePath;
  final Function()? onDelete;
  final Function(String)? onFileRenamed;

  const FileOptionsMenu({
    super.key,
    required this.filePath,
    this.onDelete,
    this.onFileRenamed,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(
        Icons.more_vert,
        color: AppColors.t3SubHeading,
        size: 18,
      ),
      onSelected: (value) async {
        switch (value) {
          case 'edit':
            await _showRenameDialog(context);
            break;
          case 'share':
            await _shareFile(context);
            break;
          case 'delete':
            _showDeleteConfirmation(context);
            break;
        }
      },
      itemBuilder: (BuildContext context) {
        return [
          _buildMenuItem(
            value: 'edit',
            text: 'rename'.tr,
          ),
          const PopupMenuItem<String>(
            enabled: false,
            height: 10,
            padding: EdgeInsets.zero,
            child: Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Divider(
                  height: 1,
                  thickness: 1,
                  color: AppColors.dividerColor,
                ),
              ),
            ),
          ),
          _buildMenuItem(
            value: 'share',
            text: 'share'.tr,
          ),
          const PopupMenuItem<String>(
            enabled: false,
            height: 10,
            padding: EdgeInsets.zero,
            child: Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Divider(
                  height: 1,
                  thickness: 1,
                  color: AppColors.dividerColor,
                ),
              ),
            ),
          ),
          _buildMenuItem(
            value: 'delete',
            text: 'delete'.tr,
          ),
        ];
      },
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: Colors.white,
      elevation: 0.4,
    );
  }

  PopupMenuItem<String> _buildMenuItem({
    required String value,
    required String text,
  }) {
    return PopupMenuItem<String>(
      value: value,
      child: Center(
        child: Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w300,
            color: const Color(0xFF8E8E93),
          ),
        ),
      ),
    );
  }

  Future<void> _shareFile(BuildContext context) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        AppSnackBar.show(context, message: 'file_not_found'.tr);
        return;
      }

      await Share.shareXFiles(
        [XFile(filePath)],
        text: 'sharing_document_from_ocr_tool'.tr,
        subject: 'document_from_ocr_tool'.tr,
      );
    } catch (e) {
      AppSnackBar.show(context, message: '${'error_sharing_file'.tr}: $e');
    }
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 15,
                spreadRadius: 5,
                offset: const Offset(0, 5),
              )
            ],
          ),
          child: AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'delete_file'.tr,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
            content: Text(
              'delete_file_confirmation'.tr,
              style: GoogleFonts.inter(),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: Text(
                        'cancel'.tr,
                        style: GoogleFonts.inter(color: Colors.grey[700]),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () async {
                        try {
                          final file = File(filePath);
                          if (await file.exists()) {
                            await file.delete();

                            if (onDelete != null) {
                              onDelete!();
                            }
                          }
                          Navigator.of(context).pop();
                        } catch (e) {
                          Navigator.of(context).pop();
                          AppSnackBar.show(context,
                              message: '${'error_deleting_file'.tr}: $e');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 2,
                      ),
                      child: Text(
                        'delete'.tr,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Check if a file with the new name already exists in the same directory
  Future<bool> _fileExistsInDirectory(
      String directoryPath, String fileName) async {
    try {
      final newFilePath = path.join(directoryPath, fileName);
      return await File(newFilePath).exists();
    } catch (e) {
      return false;
    }
  }

  Future<void> _showRenameDialog(BuildContext context) async {
    final fileName = File(filePath).uri.pathSegments.last;
    final fileNameWithoutExt = path.basenameWithoutExtension(fileName);
    final fileExtension = path.extension(fileName);
    final controller = TextEditingController(text: fileNameWithoutExt);

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        String? errorMessage;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 15,
                    spreadRadius: 5,
                    offset: const Offset(0, 5),
                  )
                ],
              ),
              child: AlertDialog(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'rename_file'.tr,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Theme(
                      data: Theme.of(context).copyWith(
                        // Override the text selection theme
                        textSelectionTheme: TextSelectionThemeData(
                          cursorColor: AppColors.primary,
                          selectionColor: AppColors.primary.withOpacity(0.2),
                          selectionHandleColor: AppColors.primary,
                        ),
                        // Override the primary color for the input decoration
                        primaryColor: AppColors.primary,
                        colorScheme: Theme.of(context).colorScheme.copyWith(
                          primary: AppColors.primary,
                        ),
                      ),
                      child: TextField(
                        controller: controller,
                        cursorColor: AppColors.primary,
                        selectionControls: MaterialTextSelectionControls(),
                        style: GoogleFonts.inter(
                          color: Colors.black,
                        ),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: errorMessage != null
                                  ? Colors.red
                                  : AppColors.dividerColor,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: errorMessage != null
                                  ? Colors.red
                                  : AppColors.primary,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: errorMessage != null
                                  ? Colors.red
                                  : AppColors.dividerColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (errorMessage != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        errorMessage!,
                        style: GoogleFonts.inter(
                          color: Colors.red,
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ],
                ),
                actions: [
                  Padding(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: Text(
                            'cancel'.tr,
                            style: GoogleFonts.inter(color: Colors.grey[700]),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () async {
                            try {
                              final newName = controller.text.trim();
                              if (newName.isEmpty) {
                                setDialogState(() {
                                  errorMessage = 'please_enter_valid_name'.tr;
                                });
                                return;
                              }

                              setDialogState(() {
                                errorMessage = null;
                              });

                              final file = File(filePath);
                              final newFileName = '$newName$fileExtension';
                              final directoryPath = path.dirname(filePath);

                              final fileExists = await _fileExistsInDirectory(
                                  directoryPath, newFileName);

                              if (fileExists) {
                                setDialogState(() {
                                  errorMessage = 'file_name_already_exists'.tr;
                                });
                                return;
                              }

                              final newPath =
                              path.join(directoryPath, newFileName);
                              await file.rename(newPath);

                              if (onFileRenamed != null) {
                                onFileRenamed!(newPath);
                              }

                              Navigator.of(context).pop();
                              AppSnackBar.show(context,
                                  message: 'file_renamed_successfully'.tr);
                            } catch (e) {
                              setDialogState(() {
                                errorMessage = '${'error_renaming_file'.tr}: $e';
                              });
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 2,
                          ),
                          child: Text(
                            'rename'.tr,
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}