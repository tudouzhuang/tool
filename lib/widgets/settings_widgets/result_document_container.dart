import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path/path.dart' as path;
import 'package:share_plus/share_plus.dart';
import 'package:get/get.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_snackbar.dart';

class ResultDocumentContainer extends StatefulWidget {
  final String documentName;
  final String date;
  final String time;

  final bool isFavorite;
  final bool isLocked;
  final String filePath;
  final VoidCallback onFavoriteToggle;
  final VoidCallback? onDelete;
  final Function(String)? onFileRenamed;
  final Function()? onLockToggle;
  final String documentImage;
  final bool isSelectable;
  final bool isSelected;
  final VoidCallback? onTap;

  const ResultDocumentContainer({
    super.key,
    required this.documentName,
    required this.date,
    required this.time,
    required this.isFavorite,
    required this.isLocked,
    required this.filePath,
    required this.onFavoriteToggle,
    this.onDelete,
    this.onFileRenamed,
    this.onLockToggle,
    this.documentImage = 'assets/images/doc.png',
    this.isSelectable = false,
    this.isSelected = false,
    this.onTap,
  });

  @override
  State<ResultDocumentContainer> createState() => _ResultDocumentContainerState();
}

class _ResultDocumentContainerState extends State<ResultDocumentContainer> {
  String? _fileSize;

  @override
  void initState() {
    super.initState();
    _getFileSize();
  }

  Future<void> _getFileSize() async {
    try {
      final file = File(widget.filePath);
      if (await file.exists()) {
        final size = await file.length();
        setState(() {
          _fileSize = _formatBytes(size);
        });
      }
    } catch (e) {
      setState(() {
        _fileSize = 'Unknown';
      });
    }
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 KB';

    if (bytes < 1024) {
      // For files smaller than 1KB, show in KB with 3 decimal places
      double kbSize = bytes / 1024;
      return '${kbSize.toStringAsFixed(3)} KB';
    } else if (bytes < 1024 * 1024) {
      // For files smaller than 1MB, show in KB with 1 decimal place
      double kbSize = bytes / 1024;
      return '${kbSize.toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      // For files smaller than 1GB, show in MB with 2 decimal places
      double mbSize = bytes / (1024 * 1024);
      return '${mbSize.toStringAsFixed(2)} MB';
    } else {
      // For files 1GB or larger, show in GB with 2 decimal places
      double gbSize = bytes / (1024 * 1024 * 1024);
      return '${gbSize.toStringAsFixed(2)} GB';
    }
  }

  Map<String, dynamic> _getDocumentIcon() {
    final fileExtension = path.extension(widget.filePath).toLowerCase();

    switch (fileExtension) {
      case '.jpg':
      case '.jpeg':
      case '.png':
        return {'path': 'assets/icons/convert_img_icon.svg', 'isSvg': true};

      case '.pdf':
        return {'path': 'assets/icons/convert_pdf.svg', 'isSvg': true};

      case '.doc':
      case '.docx':
        return {'path': 'assets/icons/word_icon.svg', 'isSvg': true};

      case '.zip':
      case '.rar':
      case '.7z':
        return {'path': 'assets/icons/zip.svg', 'isSvg': true};

      default:
        return {'path': widget.documentImage, 'isSvg': false};
    }
  }

  Widget _buildIconWidget(Map<String, dynamic> iconData) {
    final String iconPath = iconData['path'];
    final bool isSvg = iconData['isSvg'];

    try {
      if (isSvg) {
        return SvgPicture.asset(
          iconPath,
          fit: BoxFit.contain,
          width: 40,
          height: 40,
          placeholderBuilder: (BuildContext context) => Container(
            width: 40,
            height: 40,
            color: Colors.grey[300],
            child: const Icon(Icons.description, color: Colors.grey),
          ),
        );
      } else {
        return Image.asset(
          iconPath,
          fit: BoxFit.contain,
          width: 40,
          height: 40,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: 40,
              height: 40,
              color: Colors.grey[300],
              child: const Icon(Icons.description, color: Colors.grey),
            );
          },
        );
      }
    } catch (e) {
      // Fallback widget in case of any error
      return Container(
        width: 40,
        height: 40,
        color: Colors.grey[300],
        child: const Icon(Icons.description, color: Colors.grey),
      );
    }
  }

  String _buildFileInfoText() {
    final date = widget.date;
    final time = widget.time;
    final size = _fileSize ?? 'Loading...';
    return '$date | $time | $size';
  }

  @override
  Widget build(BuildContext context) {
    final iconData = _getDocumentIcon();

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.16),
              blurRadius: 3,
              offset: const Offset(0, 0),
            ),
          ],
          // Only show border when selectable AND selected
          border: (widget.isSelectable && widget.isSelected)
              ? Border.all(color: AppColors.primary, width: 2)
              : null,
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Center(
                    child: Stack(
                      children: [
                        _buildIconWidget(iconData),
                        if (widget.isLocked)
                          const Positioned(
                            bottom: 2,
                            right: 2,
                            child: Icon(
                              Icons.lock,
                              size: 16,
                              color: Colors.grey,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              Container(
                width: 1,
                color: Colors.grey.shade300,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.documentName,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _buildFileInfoText(),
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.w400,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              if (!widget.isSelectable) ...[
                Padding(
                  padding: const EdgeInsets.only(left: 10, right: 5),
                  child: GestureDetector(
                    onTap: widget.onFavoriteToggle,
                    child: Icon(
                      widget.isFavorite ? Icons.star : Icons.star_border,
                      color: widget.isFavorite ? Colors.amber : Colors.grey,
                      size: 24,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  padding: EdgeInsets.zero,
                  icon: SvgPicture.asset(
                    'assets/icons/more_icon.svg',
                    height: 20,
                    width: 20,
                  ),
                  onSelected: (value) async {
                    switch (value) {
                      case 'edit':
                        await _showRenameDialog(context);
                        break;
                      case 'share':
                        await _shareFile(context);
                        break;
                      case 'lock':
                        if (widget.onLockToggle != null) widget.onLockToggle!();
                        break;
                      case 'delete':
                        if (widget.onDelete != null) widget.onDelete!();
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
                            padding: EdgeInsets.symmetric(horizontal: 8),
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
                        value: 'lock',
                        text: widget.isLocked ? 'unlock'.tr : 'lock'.tr,
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
                ),
              ] else ...[
                const SizedBox(width: 8),
                Icon(
                  Icons.check_circle,
                  color: widget.isSelected ? AppColors.primary : Colors.transparent,
                  size: 24,
                ),
              ],
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
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
      final file = File(widget.filePath);
      if (!await file.exists()) {
        AppSnackBar.show(context, message: 'file_not_found'.tr);
        return;
      }

      await Share.shareXFiles(
        [XFile(widget.filePath)],
        text: 'sharing_document_from_ocr_tool'.tr,
        subject: 'document_from_ocr_tool'.tr,
      );
    } catch (e) {
      AppSnackBar.show(context, message: '${'error_sharing_file'.tr}: $e');
    }
  }

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
    if (widget.onFileRenamed == null) return;

    final fileName = File(widget.filePath).uri.pathSegments.last;
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
                        textSelectionTheme: TextSelectionThemeData(
                          cursorColor: AppColors.primary,
                          selectionColor: AppColors.primary.withOpacity(0.2),
                          selectionHandleColor: AppColors.primary,
                        ),
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

                              final file = File(widget.filePath);
                              final newFileName = '$newName$fileExtension';
                              final directoryPath = path.dirname(widget.filePath);

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

                              if (widget.onFileRenamed != null) {
                                widget.onFileRenamed!(newPath);
                              }

                              Navigator.of(context).pop();
                              AppSnackBar.show(context,
                                  message: 'file_renamed_successfully'.tr);
                            } catch (e) {
                              setDialogState(() {
                                errorMessage =
                                '${'error_renaming_file'.tr}: $e';
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