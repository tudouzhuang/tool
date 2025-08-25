import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as path;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:toolkit/screens/file_transfer_screen/qr_display_screen.dart';
import 'package:crypto/crypto.dart';
import '../../models/file_model.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_snackbar.dart';
import '../../widgets/buttons/gradient_btn.dart';
import '../../widgets/tools/custom_svg_image.dart';
import '../../widgets/tools/file_transfer_dropzone.dart';
import '../../widgets/tools/info_card.dart';
import '../../widgets/tools/tools_app_bar.dart';
import '../../widgets/tools/file_transfer_selection.dart';
import '../files_screens/files_main_screen.dart';
import '../settings_screens/continue_with_google_screen.dart';
import '../../services/auth_service.dart';

class FileTransferScreen extends StatefulWidget {
  const FileTransferScreen({super.key});

  @override
  State<FileTransferScreen> createState() => _FileTransferScreenState();
}

class _FileTransferScreenState extends State<FileTransferScreen> {
  FileModel? _selectedFile;
  bool _shouldClearFile = false;
  bool _isGeneratingQR = false;
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<void> _navigateToFileSelection() async {
    final List<FileModel>? selectedFiles = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const FilesMainScreen(isSelectingFiles: true),
      ),
    );

    if (selectedFiles != null && selectedFiles.isNotEmpty) {
      setState(() {
        _selectedFile = selectedFiles.first;
        _shouldClearFile = false;
      });
    }
  }

  // Generate unique file hash based on content and metadata
  Future<String> _generateFileHash(FileModel fileModel) async {
    try {
      final file = File(fileModel.displayPath);
      final bytes = await file.readAsBytes();

      // Create hash from file content + name + size for uniqueness
      final content = bytes +
          utf8.encode(fileModel.name) +
          utf8.encode(fileModel.size.toString());
      final digest = sha256.convert(content);

      return digest.toString();
    } catch (e) {
      print('Error generating file hash: $e');
      // Fallback to simple hash if file reading fails
      final content = utf8.encode(
          '${fileModel.name}_${fileModel.size}_${fileModel.date.toIso8601String()}');
      return sha256.convert(content).toString();
    }
  }

  // Check if file already exists in storage and Firestore
  Future<Map<String, dynamic>?> _checkExistingFile(String fileHash) async {
    try {
      final user = _authService.currentUser;
      if (user == null) return null;

      // Query Firestore for existing file with same hash
      final querySnapshot = await _firestore
          .collection('qr_codes')
          .where('fileHash', isEqualTo: fileHash)
          .where('userId', isEqualTo: user.uid)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        final data = doc.data();

        // Verify that the file still exists in storage
        try {
          final storageRef = _storage.refFromURL(data['downloadUrl']);
          await storageRef
              .getDownloadURL(); // This will throw if file doesn't exist

          return {
            'qrId': doc.id,
            'data': data,
          };
        } catch (e) {
          // File no longer exists in storage, mark as inactive
          await doc.reference.update({'isActive': false});
          return null;
        }
      }

      return null;
    } catch (e) {
      print('Error checking existing file: $e');
      return null;
    }
  }

  Future<String?> _uploadFileToStorage(
      FileModel fileModel, String fileHash) async {
    try {
      // Use hash as filename to prevent duplicates
      final fileExtension = path.extension(fileModel.name);
      final fileName = '$fileHash$fileExtension';
      final storageRef = _storage.ref().child('shared_files/$fileName');

      try {
        // Check if file already exists in storage
        final existingUrl = await storageRef.getDownloadURL();
        print('File already exists in storage, reusing: $existingUrl');
        return existingUrl;
      } catch (e) {
        // File doesn't exist, proceed with upload
        print('File not found in storage, uploading new file');
      }

      final file = File(fileModel.displayPath);
      if (!await file.exists()) {
        throw Exception('File not found at path: ${fileModel.displayPath}');
      }

      final uploadTask = storageRef.putFile(file);
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print('Error uploading file to storage: $e');
      rethrow;
    }
  }

  Future<void> _generateQRCode() async {
    final user = _authService.currentUser;
    if (user == null) {
      _showLoginRequiredDialog();
      return;
    }

    // Check if no file is selected and show snackbar
    if (_selectedFile == null) {
      AppSnackBar.show(context, message: 'Please select a file first'.tr);
      return;
    }

    setState(() => _isGeneratingQR = true);

    try {
      // Generate file hash for uniqueness check
      final fileHash = await _generateFileHash(_selectedFile!);

      // Check if file already exists
      final existingFile = await _checkExistingFile(fileHash);

      if (existingFile != null) {
        // File already exists, reuse existing QR code
        final existingData = existingFile['data'];
        final qrId = existingFile['qrId'];

        // Update access count and timestamp
        await _firestore.collection('qr_codes').doc(qrId).update({
          'lastAccessed': FieldValue.serverTimestamp(),
          'accessCount': FieldValue.increment(1),
        });

        // Navigate to QR display with existing data
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => QrCodeDisplayScreen(
              qrData: existingData['qrData'],
              fileName: existingData['name'],
              fileSize: existingData['size'].toString(),
              qrId: qrId,
            ),
          ),
        );

        setState(() => _isGeneratingQR = false);
        return;
      }

      final downloadUrl = await _uploadFileToStorage(_selectedFile!, fileHash);
      final fileExtension = path.extension(_selectedFile!.name).toLowerCase();
      final fileType = _getFileTypeFromExtension(fileExtension);

      final fileInfo = {
        'name': _selectedFile!.name,
        'size': _selectedFile!.size,
        'originalPath': _selectedFile!.displayPath,
        'downloadUrl': downloadUrl,
        'type': fileType,
        'extension': fileExtension,
        'date': _selectedFile!.date.toIso8601String(),
        'isEncrypted': _selectedFile!.isEncrypted,
        'isFavorite': _selectedFile!.isFavorite,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'userId': user.uid,
        'fileHash': fileHash, // Add file hash for future lookups
      };

      final qrDataString = jsonEncode(fileInfo);
      final qrDocRef = await _firestore.collection('qr_codes').add({
        ...fileInfo,
        'qrData': qrDataString,
        'createdAt': FieldValue.serverTimestamp(),
        'lastAccessed': FieldValue.serverTimestamp(),
        'isActive': true,
        'scanned': false,
        'scannedBy': null,
        'scannedAt': null,
        'ownerId': user.uid,
        'ownerEmail': user.email,
        'fileUploaded': true,
        'downloadCount': 0,
        'accessCount': 1, // Initial access count
      });

      final qrCodeData = {
        ...fileInfo,
        'qrId': qrDocRef.id,
      };

      final finalQrDataString = jsonEncode(qrCodeData);
      await qrDocRef.update({'qrData': finalQrDataString});

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => QrCodeDisplayScreen(
            qrData: finalQrDataString,
            fileName: _selectedFile!.name,
            fileSize: _selectedFile!.size,
            qrId: qrDocRef.id,
          ),
        ),
      );

      setState(() => _isGeneratingQR = false);
    } catch (e) {
      setState(() => _isGeneratingQR = false);
      // Optional: Show error snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating QR code: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
  }

  void _showLoginRequiredDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.qr_code,
                    color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                  child: Text('Sign in Required'.tr,
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87))),
            ],
          ),
          content: Text(
              'Please sign in to generate QR codes for your files.'.tr,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Colors.black54)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'.tr,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600])),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            const ContinueWithGoogleScreen()));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              child: Text('Sign in'.tr,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w500)),
            ),
          ],
        );
      },
    );
  }

  void _removeFile() {
    setState(() => _selectedFile = null);
  }

  void _clearSelectedFile() {
    setState(() {
      _selectedFile = null;
      _shouldClearFile = true;
    });
  }

  String _getFileTypeFromExtension(String extension) {
    switch (extension.toLowerCase()) {
      case '.pdf':
        return 'PDF Document';
      case '.doc':
      case '.docx':
        return 'Word Document';
      case '.jpg':
      case '.jpeg':
        return 'JPEG Image';
      case '.png':
        return 'PNG Image';
      case '.zip':
        return 'ZIP Archive';
      case '.txt':
        return 'Text Document';
      case '.mp4':
        return 'Video File';
      case '.mp3':
        return 'Audio File';
      default:
        return 'Unknown File';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: ToolsAppBar(title: 'file_transfer'.tr),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(30.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const CustomSvgImage(
                      imagePath: 'assets/images/file_transfer_image.svg'),
                  const SizedBox(height: 30),
                  InfoCard(
                      title: 'easy_transfer_file'.tr,
                      description:
                          'Transfer files instantly while keeping quality, resolution, and clarity intact.'),
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
                        )
                      ],
                    ),
                    child: Column(
                      children: [
                        FileTransferSelectionSection(
                          sectionTitle: 'choose_file'.tr,
                          onSelectFiles: _navigateToFileSelection,
                          onImportFile: _navigateToFileSelection,
                        ),
                        Padding(
                          padding: const EdgeInsets.only(
                              left: 16, right: 16, bottom: 16),
                          child: FileTransferDropZone(
                            selectedFile: _selectedFile,
                            onTap: _navigateToFileSelection,
                            onRemoveFile: _removeFile,
                            isEmpty: _shouldClearFile || _selectedFile == null,
                            emptyStateText: 'Generate QR Code'.tr,
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
                const EdgeInsets.symmetric(horizontal: 20.0, vertical: 30.0),
            child: CustomGradientButton(
              text: _isGeneratingQR
                  ? 'Generating QR Code...'.tr
                  : 'Generate QR Code'.tr,
              onPressed: _isGeneratingQR ? null : _generateQRCode,
            ),
          ),
        ],
      ),
    );
  }
}
