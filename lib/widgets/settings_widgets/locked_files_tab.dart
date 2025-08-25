import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_ce/hive.dart';
import 'package:intl/intl.dart';
import 'package:toolkit/models/file_model.dart';
import 'package:toolkit/services/save_document_service.dart';
import 'package:toolkit/widgets/settings_widgets/sort_btn.dart';

import '../../utils/app_snackbar.dart';

class LockedFilesView extends StatefulWidget {
  final String searchQuery;

  const LockedFilesView({super.key, required this.searchQuery});

  @override
  State<LockedFilesView> createState() => _LockedFilesViewState();
}

class _LockedFilesViewState extends State<LockedFilesView> {
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

  void _toggleLock(int index) async {
    final file = filesBox.getAt(index);
    if (file != null) {
      // First update the lock status
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

      // Then handle encryption/decryption using SaveDocumentService
      final success =
      await SaveDocumentService.toggleFileLock(updatedFile, index);

      if (success) {
        setState(() {});

        AppSnackBar.show(
          context,
          message: updatedFile.isLocked
              ? 'File locked and encrypted'
              : 'File unlocked and decrypted',
        );
      } else {
        // Revert the lock status if encryption/decryption failed
        await filesBox.putAt(index, file);
        setState(() {});

        AppSnackBar.show(
          context,
          message:'Failed to toggle file lock',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get all locked files
    final lockedFiles = _isLoading
        ? []
        : filesBox.values
        .where((file) => file.isLocked)
        .where((file) => file.name
        .toLowerCase()
        .contains(widget.searchQuery.toLowerCase()))
        .toList();

    // Sort files
    if (_sortBy == 'Name') {
      lockedFiles.sort((a, b) => a.name.compareTo(b.name));
    } else if (_sortBy == 'Date') {
      lockedFiles.sort((a, b) => b.date.compareTo(a.date));
    }

    return Column(
      children: [
        // Sort button with container and custom icon
        Padding(
          padding: const EdgeInsets.all(2.0),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 40, left: 20),
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
        ),
        const SizedBox(height: 12),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
            children: [
              if (lockedFiles.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 300),
                    child: Text(
                      'No locked files found',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                )
              else
                ...lockedFiles.asMap().entries.map((entry) {
                  final index = entry.key;
                  final file = entry.value;

                  // Find the actual index in the box
                  int actualIndex = -1;
                  for (int i = 0; i < filesBox.length; i++) {
                    final boxFile = filesBox.getAt(i);
                    if (boxFile != null && boxFile.path == file.path) {
                      actualIndex = i;
                      break;
                    }
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        _buildFileItem(
                          context,
                          documentName: file.name,
                          date: DateFormat('yy/MM/dd').format(file.date),
                          time: DateFormat('h:mma').format(file.date),
                          size: file.size,
                          isFavorite: file.isFavorite,
                          onFavoriteToggle: () =>
                              _toggleFavorite(actualIndex),
                          onLockToggle: () => _toggleLock(actualIndex),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  );
                }),
              const SizedBox(height: 100), // Extra space for nav bar
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFileItem(
      BuildContext context, {
        required String documentName,
        required String date,
        required String time,
        required String size,
        required bool isFavorite,
        required VoidCallback onFavoriteToggle,
        required VoidCallback onLockToggle,
      }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.16),
            blurRadius: 4,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                width: 50,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Center(
                  child: Stack(
                    children: [
                      Image.asset(
                        'assets/images/doc.png',
                        fit: BoxFit.fill,
                      ),
                      Positioned(
                        right: 2,
                        top: 2,
                        child: Icon(
                          Icons.lock,
                          size: 16,
                          color: Colors.grey[700],
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
                    documentName,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$date | $time | $size',
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.w400,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: onFavoriteToggle,
              child: Icon(
                isFavorite ? Icons.star : Icons.star_border,
                color: isFavorite ? Colors.amber : Colors.grey,
                size: 24,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.lock_open),
              onPressed: onLockToggle,
            ),
          ],
        ),
      ),
    );
  }
}