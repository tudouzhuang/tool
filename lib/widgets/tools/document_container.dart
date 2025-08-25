import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';
import '../tools/file_options_menu.dart';

class DocumentContainer extends StatefulWidget {
  final String filePath;
  final String? date;
  final VoidCallback? onDelete;
  final Function(String)? onFileRenamed;
  final VoidCallback? onTap;

  const DocumentContainer({
    super.key,
    required this.filePath,
    this.date,
    this.onDelete,
    this.onFileRenamed,
    this.onTap,
  });

  @override
  State<DocumentContainer> createState() => _DocumentContainerState();
}

class _DocumentContainerState extends State<DocumentContainer> {
  late String _currentFilePath;
  String? _fileSize;

  @override
  void initState() {
    super.initState();
    _currentFilePath = widget.filePath;
    _getFileSize();
  }

  // Function to get file size
  Future<void> _getFileSize() async {
    try {
      final file = File(_currentFilePath);
      if (await file.exists()) {
        final size = await file.length();
        setState(() {
          _fileSize = _formatFileSize(size);
        });
      }
    } catch (e) {
      // Handle error silently or set default size
      setState(() {
        _fileSize = 'Unknown';
      });
    }
  }

  // Function to format file size in human readable format
  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '${bytes} B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  // Function to get the appropriate icon based on file extension
  String _getFileIcon(String filePath) {
    String extension = filePath.toLowerCase().split('.').last;

    switch (extension) {
      case 'docx':
      case 'doc':
        return 'assets/icons/word_icon.svg';
      case 'pdf':
        return 'assets/icons/convert_pdf.svg';
      case 'zip':
        return 'assets/icons/zip.svg';
      default:
        return 'assets/icons/file.svg';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
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
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Center(
                    child: SvgPicture.asset(
                      _getFileIcon(_currentFilePath),
                      // Dynamic icon based on file extension
                      width: 30,
                      height: 30,
                    ),
                  ),
                ),
              ),
              Container(width: 1, color: Colors.grey.shade300),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _currentFilePath.split('/').last,
                        style: GoogleFonts.inter(
                          fontSize: 10,
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
              ),
              if (widget.onDelete != null || widget.onFileRenamed != null)
                FileOptionsMenu(
                  filePath: _currentFilePath,
                  onDelete: widget.onDelete,
                  onFileRenamed: (newName) {
                    setState(() {
                      _currentFilePath = newName;
                    });
                    // Recalculate file size for renamed file
                    _getFileSize();
                    if (widget.onFileRenamed != null) {
                      widget.onFileRenamed!(newName);
                    }
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Function to build the file info text with date and size
  String _buildFileInfoText() {
    final date = widget.date ?? DateTime.now().toString().substring(0, 16);
    final size = _fileSize ?? 'Loading...';
    return '$date | $size';
  }
}