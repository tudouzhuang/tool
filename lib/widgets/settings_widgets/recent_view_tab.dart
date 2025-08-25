import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_ce/hive.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;
import 'package:get/get.dart';
import 'package:toolkit/widgets/settings_widgets/sort_btn.dart';
import 'package:toolkit/widgets/settings_widgets/result_document_container.dart';
import '../../models/file_model.dart';
import '../../services/save_document_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_snackbar.dart';
import 'package:open_file/open_file.dart';

class RecentsViewTab extends StatefulWidget {
  final String searchQuery;
  final Function(FileModel, int)? onFileSelected;
  final bool isSelectingFiles;
  const RecentsViewTab({super.key, required this.searchQuery,this.onFileSelected,
    this.isSelectingFiles = false,});

  @override
  State<RecentsViewTab> createState() => _RecentsViewTabState();
}

class _RecentsViewTabState extends State<RecentsViewTab> {
  late Box<FileModel> filesBox;
  String _sortBy = 'Recent';
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

  void _toggleFavorite(int index) {
    setState(() {
      final file = filesBox.getAt(index);
      if (file != null) {
        filesBox.putAt(
            index,
            FileModel(
              name: file.name,
              path: file.path,
              date: file.date,
              size: file.size,
              isFavorite: !file.isFavorite,
              isLocked: file.isLocked,
            ));
      }
    });
  }

  Future<void> _toggleLock(int index) async {
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

      // Then handle encryption/decryption
      final success = await SaveDocumentService.toggleFileLock(updatedFile, index);

      if (success) {
        setState(() {});
        AppSnackBar.show(context,
            message: updatedFile.isLocked
                ? 'file_locked_encrypted'.tr  // Localized
                : 'file_unlocked_decrypted'.tr); // Localized
      } else {
        // Revert the lock status if encryption/decryption failed
        await filesBox.putAt(index, file);
        AppSnackBar.show(context, message: 'failed_toggle_file_lock'.tr); // Localized
      }
    }
  }

  List<MapEntry<int, FileModel>> _getRecentFiles() {
    if (_isLoading || filesBox.isEmpty) return [];

    List<MapEntry<int, FileModel>> allFilesWithIndex = [];
    for (int i = 0; i < filesBox.length; i++) {
      final file = filesBox.getAt(i);
      if (file != null && !file.isLocked) { // Only include non-locked files
        allFilesWithIndex.add(MapEntry(i, file));
      }
    }

    allFilesWithIndex.sort((a, b) => b.value.date.compareTo(a.value.date));

    return allFilesWithIndex.take(10).toList();
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

  Future<void> _renameFile(int index, String newPath) async {
    try {
      final file = filesBox.getAt(index);
      if (file == null) return;

      final oldFile = File(file.path);
      final newFile = File(newPath);

      if (await oldFile.exists()) {
        await oldFile.rename(newPath);
      }

      final newFileName = path.basename(newPath);
      setState(() {
        filesBox.putAt(
            index,
            FileModel(
              name: newFileName,
              path: newPath,
              date: file.date,
              size: file.size,
              isFavorite: file.isFavorite,
              isLocked: file.isLocked,
            ));
      });

      AppSnackBar.show(context, message: 'file_renamed_successfully'.tr); // Localized
    } catch (e) {
      AppSnackBar.show(context, message: '${'error_renaming_file'.tr}: $e'); // Localized
    }
  }

  void _deleteFile(int index) {
    setState(() {
      filesBox.deleteAt(index);
    });

    AppSnackBar.show(context, message: 'file_deleted'.tr); // Localized
  }

  @override
  Widget build(BuildContext context) {
    final recentFilesWithIndex = _getRecentFiles();

    final filteredFiles = recentFilesWithIndex
        .where((entry) => entry.value.name
        .toLowerCase()
        .contains(widget.searchQuery.toLowerCase()))
        .toList();

    if (_sortBy == 'Name') {
      filteredFiles.sort((a, b) => a.value.name.compareTo(b.value.name));
    } else if (_sortBy == 'Date') {
      filteredFiles.sort((a, b) => b.value.date.compareTo(a.value.date));
    }

    return Column(
      children: [
        Row(
          children: [
            Padding(
              padding: const EdgeInsets.all(2.0),
              child: SortButton(
                currentSort: _sortBy,
                onSortSelected: (sortOption) {
                  setState(() {
                    _sortBy = sortOption;
                  });
                },
              ),
            ),
            const Spacer(),
          ],
        ),
        const SizedBox(height: 10),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary,))
              : ListView(
            children: [
              if (filteredFiles.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 100),
                    child: Text(
                      'no_recent_documents_found'.tr,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                )
              else
                ...filteredFiles.map((entry) {
                  final index = entry.key;
                  final file = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: Column(
                      children: [
                        Padding(
                            padding: const EdgeInsets.only(left: 6, right: 6),
                            child:  ResultDocumentContainer(
                              documentName: file.name,
                              date: DateFormat('yy/MM/dd').format(file.date),
                              time: DateFormat('h:mma').format(file.date),

                              isFavorite: file.isFavorite,
                              isLocked: file.isLocked,
                              filePath: file.path,
                              isSelectable: widget.isSelectingFiles,
                              onFavoriteToggle: () => _toggleFavorite(index),
                              onDelete: () => _deleteFile(index),
                              onFileRenamed: (newPath) => _renameFile(index, newPath),
                              onLockToggle: () => _toggleLock(index),
                              onTap: widget.isSelectingFiles
                                  ? () => widget.onFileSelected?.call(file, index)
                                  : () => _openFile(file.path),
                            )
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