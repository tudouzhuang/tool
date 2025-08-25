import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_ce/hive.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:toolkit/models/file_model.dart';
import 'package:toolkit/services/save_document_service.dart';
import 'package:toolkit/widgets/settings_widgets/result_document_container.dart';
import 'package:toolkit/widgets/settings_widgets/sort_btn.dart';
import '../../utils/app_snackbar.dart';

class AllFilesView extends StatefulWidget {
  final String searchQuery;
  final Function(FileModel, int)? onFileSelected;
  final bool isSelectingFiles;
  final List<FileModel> selectedFiles;

  const AllFilesView({
    super.key,
    required this.searchQuery,
    this.onFileSelected,
    this.isSelectingFiles = false,
    this.selectedFiles = const [],
  });

  @override
  State<AllFilesView> createState() => _AllFilesViewState();
}

class _AllFilesViewState extends State<AllFilesView> {
  late Box<FileModel> filesBox;
  String _sortBy = 'recent'.tr;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initHive();
  }

  Future<void> _initHive() async {
    filesBox = await SaveDocumentService.initFilesBox();
    setState(() => _isLoading = false);
  }

  void _toggleFavorite(int index) async {
    final file = filesBox.getAt(index);
    if (file != null) {
      final updatedFile = FileModel(
        name: file.name,
        path: file.path,
        date: file.date,
        size: file.size,
        isFavorite: !file.isFavorite,
        isLocked: file.isLocked,
        originalPath: file.originalPath,
        isEncrypted: file.isEncrypted,
      );

      await filesBox.putAt(index, updatedFile);
      setState(() {});
    }
  }

  void _toggleLock(int index) async {
    final file = filesBox.getAt(index);
    if (file != null) {
      final updatedFile = FileModel(
        name: file.name,
        path: file.path,
        date: file.date,
        size: file.size,
        isFavorite: file.isFavorite,
        isLocked: !file.isLocked,
        originalPath: file.originalPath,
        isEncrypted: file.isEncrypted,
      );

      await filesBox.putAt(index, updatedFile);

      final success =
          await SaveDocumentService.toggleFileLock(updatedFile, index);

      if (success) {
        setState(() {});
        AppSnackBar.show(
          context,
          message: updatedFile.isLocked
              ? 'file_locked_encrypted'.tr
              : 'file_unlocked_decrypted'.tr,
        );
      } else {
        await filesBox.putAt(index, file);
        AppSnackBar.show(
          context,
          message: 'failed_toggle_file_lock'.tr,
        );
      }
    }
  }

  Future<void> _openFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await OpenFile.open(filePath);
      } else {
        AppSnackBar.show(context, message: 'file_not_found'.tr);
      }
    } catch (e) {
      AppSnackBar.show(context, message: '${'error_opening_file'.tr}: $e');
    }
  }

  void _deleteFile(int index) async {
    final file = filesBox.getAt(index);
    if (file != null) {
      final success = await SaveDocumentService.deleteFile(file);
      if (success) {
        await filesBox.deleteAt(index);
        setState(() {});

        AppSnackBar.show(
          context,
          message: 'file_deleted_successfully'.tr,
        );
      }
    }
  }

  void _renameFile(int index, String newPath) async {
    final file = filesBox.getAt(index);
    if (file != null) {
      final updatedFile = FileModel(
        name: newPath.split('/').last,
        path: newPath,
        date: file.date,
        size: file.size,
        isFavorite: file.isFavorite,
        isLocked: file.isLocked,
        originalPath: file.originalPath,
        isEncrypted: file.isEncrypted,
      );

      await filesBox.putAt(index, updatedFile);
      setState(() {});
    }
  }

  bool _isFileSelected(FileModel file) {
    return widget.isSelectingFiles &&
        widget.selectedFiles.isNotEmpty &&
        widget.selectedFiles.first.path == file.path;
  }

  // Check if file size is within 2MB limit
  bool _isFileSizeValid(String sizeString) {
    try {
      // Extract numeric value and unit from size string (e.g., "1.5 MB", "500 KB")
      final parts = sizeString.trim().split(' ');
      if (parts.length != 2) return false;

      final value = double.tryParse(parts[0]);
      final unit = parts[1].toUpperCase();

      if (value == null) return false;

      // Convert to MB
      double sizeInMB;
      switch (unit) {
        case 'KB':
          sizeInMB = value / 1024;
          break;
        case 'MB':
          sizeInMB = value;
          break;
        case 'GB':
          sizeInMB = value * 1024;
          break;
        case 'B':
        case 'BYTES':
          sizeInMB = value / (1024 * 1024);
          break;
        default:
          return false;
      }

      return sizeInMB <= 2.0; // 2MB limit
    } catch (e) {
      return false;
    }
  }

  void _handleFileSelection(FileModel file, int actualIndex) {
    if (!_isFileSizeValid(file.size)) {
      AppSnackBar.show(
        context,
        message: 'file_size_exceeds_limit'.tr,
      );
      return;
    }

    widget.onFileSelected?.call(file, actualIndex);
  }

  @override
  Widget build(BuildContext context) {
    final allFiles = _isLoading
        ? <FileModel>[]
        : filesBox.values
            .where((file) => !file.isLocked)
            .where((file) => file.name
                .toLowerCase()
                .contains(widget.searchQuery.toLowerCase()))
            .toList();

    if (_sortBy == 'name'.tr) {
      allFiles.sort((a, b) => a.name.compareTo(b.name));
    } else if (_sortBy == 'date'.tr) {
      allFiles.sort((a, b) => b.date.compareTo(a.date));
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(2.0),
          child: Row(
            children: [
              SortButton(
                currentSort: _sortBy,
                onSortSelected: (sortOption) {
                  setState(() {
                    _sortBy = sortOption;
                  });
                },
              ),
              const Spacer(),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  children: [
                    if (allFiles.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 100),
                          child: Text(
                            'no_files_found'.tr,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      )
                    else
                      ...allFiles.asMap().entries.map((entry) {
                        final index = entry.key;
                        final file = entry.value;

                        int actualIndex = -1;
                        for (int i = 0; i < filesBox.length; i++) {
                          final boxFile = filesBox.getAt(i);
                          if (boxFile != null && boxFile.path == file.path) {
                            actualIndex = i;
                            break;
                          }
                        }

                        return Padding(
                          padding: const EdgeInsets.only(left: 6, right: 6),
                          child: Column(
                            children: [
                              ResultDocumentContainer(
                                documentName: file.name,
                                date: DateFormat('yy/MM/dd').format(file.date),
                                time: DateFormat('h:mma').format(file.date),
                                isFavorite: file.isFavorite,
                                isLocked: file.isLocked,
                                filePath: file.displayPath,
                                isSelectable: widget.isSelectingFiles,
                                isSelected: _isFileSelected(file),
                                onFavoriteToggle: () =>
                                    _toggleFavorite(actualIndex),
                                onLockToggle: () => _toggleLock(actualIndex),
                                onDelete: () => _deleteFile(actualIndex),
                                onFileRenamed: (newPath) =>
                                    _renameFile(actualIndex, newPath),
                                onTap: widget.isSelectingFiles
                                    ? () =>
                                        widget.onFileSelected?.call(file, index)
                                    : () => _openFile(file.path),
                              ),
                              const SizedBox(height: 12),
                            ],
                          ),
                        );
                      }),
                    const SizedBox(height: 100),
                  ],
                ),
        ),
      ],
    );
  }
}
