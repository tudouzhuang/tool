import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:open_file/open_file.dart';
import '../../models/file_model.dart';
import '../../services/save_document_service.dart';
import '../../services/save_zip_png_service.dart';
import '../../utils/app_colors.dart';
import '../../widgets/custom_appbar.dart';
import '../../widgets/tools/animated_loaded_container.dart';
import '../../widgets/tools/document_container.dart';
import 'file_transfer_screen.dart';

class QRResultScreen extends StatefulWidget {
  final FileModel fileModel;
  final Map<String, dynamic> qrData;

  const QRResultScreen({
    super.key,
    required this.fileModel,
    required this.qrData,
  });

  @override
  State<QRResultScreen> createState() => _QRResultScreenState();
}

class _QRResultScreenState extends State<QRResultScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  bool _animationCompleted = false;
  bool _isDownloading = false;
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimation();
  }

  void _initAnimation() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _progressAnimation.addListener(() => setState(() {}));

    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _isLoading = false;
          _animationCompleted = true;
        });
      }
    });

    _animationController.forward();
  }

  Future<void> _openDocument() async {
    try {
      final result = await OpenFile.open(widget.fileModel.path);
      if (result.type != ResultType.done) {}
    } catch (e) {}
  }

  // Add this import at the top of your QRResultScreen file:
// import '../file_transfer_screen/file_transfer_screen.dart';

  Future<void> _downloadFile() async {
    if (_isDownloading) return;

    setState(() {
      _isDownloading = true;
    });

    try {
      final file = File(widget.fileModel.path);

      if (!await file.exists()) {
        return;
      }

      // Get file extension to determine file type
      final fileExtension = widget.fileModel.path.split('.').last.toLowerCase();

      bool success = false;

      // Handle different file types
      switch (fileExtension) {
        case 'docx':
        case 'doc':
          // Use SaveDocumentService for document files
          final result = await SaveDocumentService.saveDocument(
            context,
            file,
            skipTimestamp: false,
          );
          success = result == true;
          break;

        case 'pdf':
        case 'png':
        case 'jpg':
        case 'jpeg':
        case 'zip':
        case 'xlsx':
        case 'pptx':
        default:
          // Use SaveFileService for other file types
          try {
            await SaveFileService.saveFile(context, file, fileExtension);
            success = true;
          } catch (e) {
            success = false;
            debugPrint('Error using SaveFileService: $e');
          }
          break;
      }

      if (success) {
        // Navigate to FileTransferScreen and clear selected file
        _navigateToFileTransferScreen();
      } else {}
    } finally {
      setState(() {
        _isDownloading = false;
      });
    }
  }

  void _navigateToFileTransferScreen() {
    // Navigate to FileTransferScreen and clear intermediate screens but keep main/home screen
    Get.offUntil(
      GetPageRoute(page: () => const FileTransferScreen()),
      (route) => route
          .isFirst, // This keeps the first route (usually your main/home screen)
    );

    // Alternative: If you know your main screen route name
    // Get.offNamedUntil('/fileTransfer', ModalRoute.withName('/main'));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: 'qr_result'.tr,
        onBackPressed: () => Navigator.of(context).pop(),
      ),
      body: WillPopScope(
        onWillPop: () async {
          Navigator.of(context).pop();
          return false;
        },
        child: Column(
          children: [
            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      if (_isLoading || _animationCompleted)
                        AnimatedLoadingContainer(
                          animationController: _animationController,
                          animationCompleted: _animationCompleted,
                        ),
                      const SizedBox(height: 36),
                      if (!_isLoading) ...[
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'scanned_file'.tr,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        DocumentContainer(
                          filePath: widget.fileModel.path,
                          onTap: _openDocument,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            // Button fixed at bottom
            if (!_isLoading)
              Container(
                padding: const EdgeInsets.all(20),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          AppColors.gradientStart,
                          AppColors.gradientEnd,
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ElevatedButton(
                      onPressed: _isDownloading ? null : _downloadFile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 24),
                      ),
                      child: _isDownloading
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Downloading'.tr,
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            )
                          : Text(
                              'Download'.tr,
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
