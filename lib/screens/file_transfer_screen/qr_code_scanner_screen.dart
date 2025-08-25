import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:dio/dio.dart';
import 'package:hive_ce/hive.dart';
import '../../models/file_model.dart';
import '../../services/auth_service.dart';
import '../../widgets/custom_appbar.dart';
import '../../utils/app_colors.dart';
import 'qr_result_screen.dart';

class QRCodeScannerScreen extends StatefulWidget {
  const QRCodeScannerScreen({super.key});

  @override
  State<QRCodeScannerScreen> createState() => _QRCodeScannerScreenState();
}

class _QRCodeScannerScreenState extends State<QRCodeScannerScreen> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  String? scannedData;
  bool isProcessingQR = false;
  bool hasScanned = false;
  bool isFlashOn = false;

  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  @override
  void initState() {
    super.initState();
    _requestCameraPermission();
  }

  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    if (status != PermissionStatus.granted) {}
  }

  Future<void> _createScanRecord(String qrId, Map<String, dynamic> fileData,
      Map<String, dynamic> qrDocData) async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) return;

      final scanRecordId = _firestore.collection('scan_records').doc().id;

      final scanRecord = {
        'scanId': scanRecordId,
        'qrId': qrId,
        'scannerId': currentUser.uid,
        'scannerEmail': currentUser.email ?? 'Unknown',
        'scannerDisplayName': currentUser.displayName ?? 'Unknown User',
        'ownerId': qrDocData['ownerId'],
        'ownerEmail': qrDocData['ownerEmail'] ?? 'Unknown',
        'ownerDisplayName': qrDocData['ownerDisplayName'] ?? 'Unknown User',
        'fileName': fileData['name'] ?? 'Unknown',
        'fileSize': fileData['size'] ?? 'Unknown',
        'fileType': fileData['type'] ?? 'Unknown',
        'fileExtension': fileData['extension'] ?? '',
        'qrCodeCreatedAt': qrDocData['createdAt'],
        'qrCodeExpiresAt': qrDocData['expiresAt'],
        'scannedAt': FieldValue.serverTimestamp(),
        'scanTimestamp': DateTime.now().millisecondsSinceEpoch,
        'deviceInfo': {
          'platform': Platform.isAndroid ? 'Android' : 'iOS',
          'timestamp': DateTime.now().toIso8601String(),
        },
      };

      await _firestore
          .collection('scan_records')
          .doc(scanRecordId)
          .set(scanRecord);

      await _firestore.collection('qr_codes').doc(qrId).update({
        'lastScannedAt': FieldValue.serverTimestamp(),
        'lastScannedBy': currentUser.uid,
        'lastScannerEmail': currentUser.email ?? 'Unknown',
        'totalScans': FieldValue.increment(1),
        'scanRecords': FieldValue.arrayUnion([scanRecordId]),
      });
    } catch (e) {
      print('Error creating scan record: $e');
    }
  }

  Future<void> _updateScanRecordOnDownloadComplete(
      String qrId, FileModel fileModel) async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) return;

      final scanQuery = await _firestore
          .collection('scan_records')
          .where('qrId', isEqualTo: qrId)
          .where('scannerId', isEqualTo: currentUser.uid)
          .orderBy('scannedAt', descending: true)
          .limit(1)
          .get();

      if (scanQuery.docs.isNotEmpty) {
        final scanRecordId = scanQuery.docs.first.id;

        await _firestore.collection('scan_records').doc(scanRecordId).update({
          'downloadStatus': 'completed',
          'downloadCompleted': true,
          'downloadCompletedAt': FieldValue.serverTimestamp(),
          'downloadedFilePath': fileModel.path,
          'downloadedFileName': fileModel.name,
          'downloadInfo': {
            'originalFileName': fileModel.name,
            'savedPath': fileModel.path,
            'downloadSize': fileModel.size,
            'downloadedAt': DateTime.now().toIso8601String(),
          }
        });
      }
    } catch (e) {
      print('Error updating scan record on download complete: $e');
    }
  }

  Future<void> _updateScanRecordOnDownloadFailure(
      String qrId, String errorMessage) async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) return;

      final scanQuery = await _firestore
          .collection('scan_records')
          .where('qrId', isEqualTo: qrId)
          .where('scannerId', isEqualTo: currentUser.uid)
          .orderBy('scannedAt', descending: true)
          .limit(1)
          .get();

      if (scanQuery.docs.isNotEmpty) {
        final scanRecordId = scanQuery.docs.first.id;

        await _firestore.collection('scan_records').doc(scanRecordId).update({
          'downloadStatus': 'failed',
          'downloadCompleted': false,
          'downloadFailedAt': FieldValue.serverTimestamp(),
          'downloadError': errorMessage,
          'errorInfo': {
            'errorMessage': errorMessage,
            'failedAt': DateTime.now().toIso8601String(),
          }
        });
      }
    } catch (e) {
      print('Error updating scan record on download failure: $e');
    }
  }

  Future<void> _processScannedQR(String qrData) async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      final Map<String, dynamic> fileData = jsonDecode(qrData);

      if (!fileData.containsKey('qrId')) {
        throw Exception('Invalid QR code: Missing QR ID');
      }

      final String qrId = fileData['qrId'];
      final qrDoc = await _firestore.collection('qr_codes').doc(qrId).get();

      if (!qrDoc.exists) {
        _showError('qr_code_not_found'.tr);
        return;
      }

      final qrDocData = qrDoc.data()!;

      if (!qrDocData['isActive'] || qrDocData['fileDeleted'] == true) {
        _showError('qr_code_inactive'.tr);
        return;
      }

      final currentUser = _authService.currentUser;
      if (currentUser != null && qrDocData['ownerId'] == currentUser.uid) {
        _showError('cannot_scan_own_qr'.tr);
        return;
      }

      await _createScanRecord(qrId, fileData, qrDocData);
      await _downloadAndSaveFile(fileData, qrDocData, qrId);
    } catch (e) {
      print('Error processing QR code: $e');
      _showError('invalid_qr_code'.tr);
    }
  }

  Future<void> _downloadAndSaveFile(Map<String, dynamic> fileData,
      Map<String, dynamic> qrDocData, String qrId) async {
    try {
      final downloadUrl = qrDocData['downloadUrl'];
      if (downloadUrl == null) {
        throw Exception('Download URL not found');
      }

      final appDir = await getApplicationDocumentsDirectory();
      final downloadsDir = Directory('${appDir.path}/ReceivedFiles');
      if (!await downloadsDir.exists()) {
        await downloadsDir.create(recursive: true);
      }

      final originalFileName = fileData['name'];
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = originalFileName.split('.').last;
      final nameWithoutExtension =
          originalFileName.replaceAll('.$extension', '');
      final uniqueFileName = '${nameWithoutExtension}_$timestamp.$extension';
      final filePath = '${downloadsDir.path}/$uniqueFileName';

      final dio = Dio();
      await dio.download(downloadUrl, filePath);

      final fileModel = FileModel(
        name: originalFileName,
        path: filePath,
        date: DateTime.now(),
        size: fileData['size'] ?? '0 B',
        isFavorite: false,
        isLocked: false,
        isEncrypted: false,
      );

      final box = await Hive.openBox<FileModel>('files');
      await box.add(fileModel);

      await _updateQRCodeScanStats(qrId);
      await _updateScanRecordOnDownloadComplete(qrId, fileModel);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => QRResultScreen(
            fileModel: fileModel,
            qrData: qrDocData,
          ),
        ),
      );
    } catch (e) {
      print('Error downloading file: $e');
      await _updateScanRecordOnDownloadFailure(qrId, e.toString());
      _showError('download_failed'.tr);
      _resetScanner();
    }
  }

  Future<void> _updateQRCodeScanStats(String qrId) async {
    try {
      final currentUser = _authService.currentUser;
      await _firestore.collection('qr_codes').doc(qrId).update({
        'scanned': true,
        'scannedAt': FieldValue.serverTimestamp(),
        'scannedBy': currentUser?.uid ?? 'anonymous',
        'scannedByEmail': currentUser?.email ?? 'anonymous',
        'downloadCount': FieldValue.increment(1),
      });
    } catch (e) {
      print('Error updating scan stats: $e');
    }
  }

  void _showError(String message) {
    _resetScanner();
  }

  void _resetScanner() {
    setState(() {
      hasScanned = false;
      isProcessingQR = false;
      scannedData = null;
    });
    controller?.resumeCamera();
  }

  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller?.pauseCamera();
    } else if (Platform.isIOS) {
      controller?.resumeCamera();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        appBar: CustomAppBar(
          title: 'QR Camera'.tr,
        ),
        body: Stack(
          children: [
            // Camera View
            Positioned.fill(
              child: QRView(
                key: qrKey,
                onQRViewCreated: _onQRViewCreated,
                overlay: QrScannerOverlayShape(
                  borderColor: Colors.transparent,
                  // Hide default corners
                  borderRadius: 0,
                  borderLength: 0,
                  borderWidth: 0,
                  cutOutSize: MediaQuery.of(context).size.width * 0.7,
                  // overlayColor: Colors.white.withOpacity(0.8),
                ),
                onPermissionSet: (ctrl, p) =>
                    _onPermissionSet(context, ctrl, p),
              ),
            ),

            // Full border around scanning area
            Positioned.fill(
              child: Center(
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.7,
                  height: MediaQuery.of(context).size.width * 0.7,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: AppColors.primary,
                      width: 1, // Regular border width
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            // Thick corner edges on top of the full border
            Positioned.fill(
              child: Center(
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.7,
                  height: MediaQuery.of(context).size.width * 0.7,
                  child: Stack(
                    children: [
                      // Top Left Corner
                      Positioned(
                        top: -3, // Offset to align with border
                        left: -3,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            border: Border(
                              top: BorderSide(
                                  color: AppColors.primary, width: 8),
                              left: BorderSide(
                                  color: AppColors.primary, width: 8),
                            ),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(12),
                            ),
                          ),
                        ),
                      ),

                      // Top Right Corner
                      Positioned(
                        top: -3,
                        right: -3,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            border: Border(
                              top: BorderSide(
                                  color: AppColors.primary, width: 8),
                              right: BorderSide(
                                  color: AppColors.primary, width: 8),
                            ),
                            borderRadius: BorderRadius.only(
                              topRight: Radius.circular(12),
                            ),
                          ),
                        ),
                      ),

                      // Bottom Left Corner
                      Positioned(
                        bottom: -3,
                        left: -3,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                  color: AppColors.primary, width: 8),
                              left: BorderSide(
                                  color: AppColors.primary, width: 8),
                            ),
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(12),
                            ),
                          ),
                        ),
                      ),

                      // Bottom Right Corner
                      Positioned(
                        bottom: -3,
                        right: -3,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                  color: AppColors.primary, width: 8),
                              right: BorderSide(
                                  color: AppColors.primary, width: 8),
                            ),
                            borderRadius: BorderRadius.only(
                              bottomRight: Radius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Instruction Text
            Positioned(
              top: MediaQuery.of(context).size.height * 0.63,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  'Scan the QR code here',
                  style: GoogleFonts.inter(
                    color: AppColors.primary,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),

            // Processing Overlay
            if (isProcessingQR)
              Container(
                color: Colors.white.withOpacity(0.95),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(AppColors.primary),
                          strokeWidth: 3,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'processing_qr_code'.tr,
                          style: TextStyle(
                            color: Colors.grey[800],
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ));
  }

  void _onQRViewCreated(QRViewController controller) {
    setState(() {
      this.controller = controller;
    });

    controller.scannedDataStream.listen((scanData) {
      if (!hasScanned && !isProcessingQR && scanData.code != null) {
        setState(() {
          hasScanned = true;
          isProcessingQR = true;
          scannedData = scanData.code;
        });
        controller.pauseCamera();
        _processScannedQR(scanData.code!);
      }
    });
  }

  void _onPermissionSet(BuildContext context, QRViewController ctrl, bool p) {
    if (!p) {}
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}
