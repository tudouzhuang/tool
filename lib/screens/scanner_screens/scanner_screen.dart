import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../services/document_scanner_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_snackbar.dart';
import '../../widgets/scanner_widgets/batch_scan.dart';
import '../../widgets/scanner_widgets/camera_appbar.dart';
import '../../widgets/scanner_widgets/document_crop_frame.dart';
import '../../widgets/scanner_widgets/single_scan.dart';
import 'batch_result_screen.dart';
import 'document_edit_screen.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription> cameras = [];
  bool _isCameraInitialized = false;
  bool _isCameraPermissionGranted = false;
  File? _imageFile;
  String _errorMessage = '';
  bool _isLoading = true;
  String? _selectedScanType = 'batch';
  int _retryCount = 0;
  static const int maxRetryCount = 3;
  final List<File> _recentImages = [];
  List<File> _batchImages = [];
  bool _isBatchModeActive = false;
  final GlobalKey _bottomContainerKey = GlobalKey();
  double _bottomContainerHeight = 150;
  bool _isFlashOn = false;
  bool _isGridVisible = true;
  final ImagePicker _imagePicker = ImagePicker();

  // Document type crop dimensions
  static const double businessCardCropWidth = 324;
  static const double businessCardCropHeight = 194;
  static const double passportCropWidth = 304;
  static const double passportCropHeight = 304;
  static const double legalCropWidth = 350;
  static const double legalCropHeight = 572;
  static const double letterCropWidth = 324;
  static const double letterCropHeight = 421;
  static const double idCardCropWidth = 304;
  static const double idCardCropHeight = 194;
  List<File> _idCardImages = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _measureBottomContainerHeight();
    });
  }

  void _measureBottomContainerHeight() {
    if (_bottomContainerKey.currentContext != null) {
      final RenderBox box =
      _bottomContainerKey.currentContext!.findRenderObject() as RenderBox;
      setState(() {
        _bottomContainerHeight = box.size.height;
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _disposeCamera();
    super.dispose();
  }

  Future<void> _disposeCamera() async {
    try {
      await _controller?.dispose();
    } catch (e) {
      print('Error disposing camera: $e');
    }
    _controller = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _controller;

    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    switch (state) {
      case AppLifecycleState.paused:
        _disposeCamera();
        setState(() {
          _isCameraInitialized = false;
        });
        break;
      case AppLifecycleState.resumed:
        if (!_isCameraInitialized && _isCameraPermissionGranted) {
          _initializeControllerAfterPermission();
        }
        break;
      case AppLifecycleState.inactive:
        try {
          cameraController.pausePreview();
        } catch (e) {
          print('Error pausing camera preview: $e');
        }
        break;
      case AppLifecycleState.detached:
        _disposeCamera();
        break;
      case AppLifecycleState.hidden:
        break;
    }
  }

  Future<void> _initializeCamera() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _retryCount = 0;
    });

    await _requestCameraPermission();
  }

  Future<void> _requestCameraPermission() async {
    try {
      final status = await Permission.camera.request();

      if (status.isDenied) {
        setState(() {
          _errorMessage =
              'camera_permission_denied_message'.tr;
          _isLoading = false;
          _isCameraPermissionGranted = false;
        });
        return;
      }

      if (status.isPermanentlyDenied) {
        setState(() {
          _errorMessage =
              'camera_permission_permanently_denied_message'.tr;
          _isLoading = false;
          _isCameraPermissionGranted = false;
        });
        return;
      }

      setState(() {
        _isCameraPermissionGranted = status.isGranted;
      });

      if (status.isGranted) {
        await _initializeControllerAfterPermission();
      } else {
        setState(() {
          _errorMessage = 'camera_permission_required_message'.tr;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage =
        '${'failed_to_request_camera_permission'.tr}: ${e.toString()}';
        _isLoading = false;
        _isCameraPermissionGranted = false;
      });
      print('Permission request error: $e');
    }
  }

  Future<void> _initializeControllerAfterPermission() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      await _disposeCamera();
      cameras = await availableCameras();

      if (cameras.isEmpty) {
        setState(() {
          _errorMessage = 'no_cameras_found_message'.tr;
          _isLoading = false;
          _isCameraInitialized = false;
        });
        return;
      }

      _controller = CameraController(
        cameras[0],
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _controller!.initialize();

      if (!mounted) return;

      setState(() {
        _isCameraInitialized = true;
        _isLoading = false;
        _retryCount = 0;
      });

      print('Camera initialized successfully');
    } catch (e) {
      if (!mounted) return;

      print('Camera initialization error: $e');

      setState(() {
        _errorMessage = _getCameraErrorMessage(e);
        _isLoading = false;
        _isCameraInitialized = false;
      });

      if (_retryCount < maxRetryCount) {
        _retryCount++;
        final delay = Duration(seconds: _retryCount * 2);
        print(
            'Retrying camera initialization in ${delay
                .inSeconds} seconds (attempt $_retryCount)');

        Future.delayed(delay, () {
          if (mounted && _isCameraPermissionGranted && !_isCameraInitialized) {
            _initializeControllerAfterPermission();
          }
        });
      }
    }
  }

  String _getCameraErrorMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('permission')) {
      return 'camera_permission_check_message'.tr;
    } else if (errorString.contains('already in use') || errorString.contains('busy')) {
      return 'camera_in_use_message'.tr;
    } else if (errorString.contains('not available') || errorString.contains('not found')) {
      return 'camera_not_available_message'.tr;
    } else if (errorString.contains('initialization')) {
      return 'camera_initialization_failed_message'.tr;
    } else {
      return 'camera_error_generic_message'.tr;
    }
  }

  Future<void> _retryInitialization() async {
    setState(() {
      _errorMessage = '';
      _retryCount = 0;
    });
    await _initializeCamera();
  }

  Future<void> _openAppSettings() async {
    try {
      await openAppSettings();
    } catch (e) {
      print('Error opening app settings: $e');
    }
  }

  Future<void> _toggleFlash() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      return;
    }

    try {
      setState(() {
        _isFlashOn = !_isFlashOn;
      });

      await _controller!.setFlashMode(
        _isFlashOn ? FlashMode.torch : FlashMode.off,
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'failed_to_toggle_flash'.tr + ': ${e.toString()}';
      });
      print('Error toggling flash: $e');

      setState(() {
        _isFlashOn = !_isFlashOn;
      });
    }
  }

  void _toggleGrid() {
    setState(() {
      _isGridVisible = !_isGridVisible;
    });
  }

  Future<void> _pickImageFromGallery() async {
    try {
      if (_selectedScanType == 'batch') {
        final List<XFile> pickedFiles = await _imagePicker.pickMultiImage();

        if (pickedFiles.isNotEmpty) {
          List<File> selectedImages =
          pickedFiles.map((file) => File(file.path)).toList();

          if (_isBatchModeActive) {
            setState(() {
              _batchImages.addAll(selectedImages);
            });

            AppSnackBar.show(context,
                message: '${'added_images_to_batch'.tr} ${selectedImages.length} ${'images'.tr}. ${'total'.tr}: ${_batchImages.length}');
          } else {
            setState(() {
              _batchImages = selectedImages;
              _isBatchModeActive = true;
            });

            _navigateToBatchPreviewScreen();
          }
        }
      } else if (_selectedScanType == 'id_card') {
        final XFile? pickedFile = await _imagePicker.pickImage(
          source: ImageSource.gallery,
        );

        if (pickedFile != null) {
          final File imageFile = File(pickedFile.path);
          setState(() {
            _idCardImages.add(imageFile);
            _recentImages.insert(0, imageFile);
          });
          _navigateToIdCardPreviewScreen();
        }
      } else {
        final XFile? pickedFile = await _imagePicker.pickImage(
          source: ImageSource.gallery,
        );

        if (pickedFile != null) {
          final File imageFile = File(pickedFile.path);
          setState(() {
            _imageFile = imageFile;
            _recentImages.insert(0, imageFile);
          });

          _navigateToPreviewScreen(imageFile);
        }
      }
    } catch (e) {
      print('${'error_picking_image_from_gallery'.tr}: $e');
      AppSnackBar.show(context,
          message: 'failed_to_pick_image_from_gallery'.tr);
    }
  }

  Future<void> _captureImage() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      AppSnackBar.show(context, message: 'camera_not_ready_message'.tr);
      return;
    }

    try {
      final XFile photo = await _controller!.takePicture();
      final directory = await getApplicationDocumentsDirectory();
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final File originalImage = File(photo.path);

      final screenWidth = MediaQuery.of(context).size.width;
      final screenHeight = MediaQuery.of(context).size.height - _bottomContainerHeight;

      // Check for specific document types using keys directly
      if (_selectedScanType == 'business_card' ||
          _selectedScanType == 'passport' ||
          _selectedScanType == 'legal' ||
          _selectedScanType == 'letter' ||
          _selectedScanType == 'id_card') {

        double frameWidth, frameHeight;

        // Use switch with keys directly
        switch (_selectedScanType) {
          case 'business_card':
            frameWidth = businessCardCropWidth;
            frameHeight = businessCardCropHeight;
            break;
          case 'passport':
            frameWidth = passportCropWidth;
            frameHeight = passportCropHeight;
            break;
          case 'legal':
            frameWidth = legalCropWidth;
            frameHeight = legalCropHeight;
            break;
          case 'letter':
            frameWidth = letterCropWidth;
            frameHeight = letterCropHeight;
            break;
          case 'id_card':
            frameWidth = idCardCropWidth;
            frameHeight = idCardCropHeight;
            break;
          default:
            frameWidth = 0;
            frameHeight = 0;
        }

        final File? framedImage = await FrameCaptureService.captureWithinFrame(
          originalImage: originalImage,
          frameWidth: frameWidth,
          frameHeight: frameHeight,
          screenWidth: screenWidth,
          screenHeight: screenHeight,
        );

        if (framedImage == null) {
          throw Exception('Failed to capture within frame');
        }

        final File? enhancedImage = await FrameCaptureService.enhanceDocumentImage(framedImage);
        final File savedImage = enhancedImage ?? framedImage;
        final File permanentFile = await savedImage.copy('${directory.path}/$fileName');

        setState(() {
          _recentImages.insert(0, permanentFile);
        });

        if (_selectedScanType == 'id_card') {
          setState(() {
            _idCardImages.add(permanentFile);
          });
          _navigateToIdCardPreviewScreen();
        } else {
          setState(() {
            _imageFile = permanentFile;
          });
          _navigateToPreviewScreen(permanentFile);
        }
      } else if (_selectedScanType == 'batch') {
        final File savedImage = await originalImage.copy('${directory.path}/$fileName');
        setState(() {
          _batchImages.add(savedImage);
          _isBatchModeActive = true;
          _recentImages.insert(0, savedImage);
        });
      } else {
        final File savedImage = await originalImage.copy('${directory.path}/$fileName');
        setState(() {
          _imageFile = savedImage;
          _recentImages.insert(0, savedImage);
        });
        _navigateToPreviewScreen(savedImage);
      }
    } catch (e) {
      print('Error capturing image: $e');
      AppSnackBar.show(context, message: 'failed_to_capture_image_try_again'.tr);
    }
  }

  void _navigateToPreviewScreen(File imageFile) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            DocumentEditScreen(
              imageFile: imageFile,
              isBatchMode: false,
              isBusinessCard: _selectedScanType == 'business_card',
              isPassport: _selectedScanType == 'passport',
              isLegal: _selectedScanType == 'legal',
              isLetter: _selectedScanType == 'letter',
              isIdCard: _selectedScanType == 'id_card',
              cropRect: null,
            ),
      ),
    );
  }

  void _navigateToIdCardPreviewScreen() {
    if (_idCardImages.isEmpty) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            DocumentEditScreen(
              imageFile: _idCardImages[0],
              isBatchMode: false,
              isIdCard: true,
              cropRect: null,
            ),
      ),
    );
  }

  void _navigateToBatchPreviewScreen() {
    if (_batchImages.isEmpty) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            DocumentEditScreen(
              imageFile: _batchImages[0],
              isBatchMode: true,
              batchImages: _batchImages,
              currentIndex: 0,
            ),
      ),
    );
  }

  void _viewRecentImage() {
    if (_recentImages.isNotEmpty) {
      if (_selectedScanType == 'id_card' && _idCardImages.isNotEmpty) {
        _navigateToIdCardPreviewScreen();
      } else {
        _navigateToPreviewScreen(_recentImages[0]);
      }
    }
  }

  void _completeBatchCapture() {
    if (_batchImages.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              BatchResultScreen(
                batchImages: _batchImages,
              ),
        ),
      );
    }
  }

  void _selectScanType(String scanType) {
    if (_selectedScanType == 'batch' &&
        scanType != 'batch' &&
        _batchImages.isNotEmpty) {
      showDialog(
        context: context,
        builder: (context) =>
            AlertDialog(
              title: Text('discard_batch_title'.tr),
              content: Text(
                  'discard_batch_message'.tr),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text('cancel'.tr,
                      style: GoogleFonts.inter(color: AppColors.primary)),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() {
                      _selectedScanType = scanType;
                      _batchImages = [];
                      _isBatchModeActive = false;
                      _idCardImages = [];
                    });
                  },
                  child: Text('discard'.tr,
                      style: GoogleFonts.inter(color: AppColors.primary)),
                ),
              ],
            ),
      );
    } else {
      setState(() {
        _selectedScanType = scanType;
        if (scanType == 'batch') {
          _isBatchModeActive = false;
          _batchImages = [];
        } else if (scanType == 'id_card') {
          _idCardImages = [];
        }
      });
    }
  }

  Widget _buildScanTypeButton(String label, bool isSelected) {
    return GestureDetector(
      onTap: () => _selectScanType(label),
      child: Text(
        label.tr, // Only translate for display
        style: GoogleFonts.inter(
            color: isSelected ? AppColors.primary : AppColors.saveDateColor,
            fontWeight: FontWeight.w500,
            fontSize: 14),
      ),
    );
  }

  Widget _buildErrorScreen() {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'camera_error'.tr,
          style: GoogleFonts.inter(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.camera_alt_outlined,
                size: 100,
                color: Colors.grey,
              ),
              const SizedBox(height: 24),
              Text(
                _errorMessage.tr,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              if (_errorMessage.contains('permission'.tr))
                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _openAppSettings,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'open_settings'.tr,
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _retryInitialization,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _errorMessage.contains('permission'.tr)
                        ? Colors.grey[300]
                        : AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'retry'.tr,
                    style: GoogleFonts.inter(
                      color: _errorMessage.contains('permission'.tr)
                          ? Colors.grey[700]
                          : Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                color: AppColors.primary,
              ),
              SizedBox(height: 16),
              Text(
                'initializing_camera'.tr,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (!_isCameraPermissionGranted || _errorMessage.isNotEmpty) {
      return _buildErrorScreen();
    }

    if (!_isCameraInitialized) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                color: AppColors.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'setting_up_camera'.tr,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: CameraAppBar(
        isFlashOn: _isFlashOn,
        isGridVisible: _isGridVisible,
        showGridIcon:
        _selectedScanType == 'single' || _selectedScanType == 'batch',
        onClosePressed: () => Navigator.pop(context),
        onFlashPressed: _toggleFlash,
        onGridPressed: _toggleGrid,
      ),
      extendBodyBehindAppBar: true,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = constraints.maxWidth;
            final screenHeight = constraints.maxHeight - _bottomContainerHeight;

            double cropWidth;
            double cropHeight;
            String documentType = 'single';

            // Use switch with keys directly
            switch (_selectedScanType) {
              case 'business_card':
                cropWidth = businessCardCropWidth;
                cropHeight = businessCardCropHeight;
                documentType = 'business_card';
                break;
              case 'passport':
                cropWidth = passportCropWidth;
                cropHeight = passportCropHeight;
                documentType = 'passport';
                break;
              case 'legal':
                cropWidth = legalCropWidth;
                cropHeight = legalCropHeight;
                documentType = 'legal';
                break;
              case 'letter':
                cropWidth = letterCropWidth;
                cropHeight = letterCropHeight;
                documentType = 'letter';
                break;
              case 'id_card':
                cropWidth = idCardCropWidth;
                cropHeight = idCardCropHeight;
                documentType = 'id_card';
                break;
              default:
                cropWidth = 0;
                cropHeight = 0;
            }

            final left = (screenWidth - cropWidth) / 2;
            final top = (screenHeight - cropHeight) / 2;

            return Stack(
              children: [
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  bottom: _bottomContainerHeight - 20,
                  child: CameraPreview(_controller!),
                ),
                if (_selectedScanType == 'business_card' ||
                    _selectedScanType == 'passport' ||
                    _selectedScanType == 'legal' ||
                    _selectedScanType == 'letter' ||
                    _selectedScanType == 'id_card')
                  DocumentCropFrame(
                    width: cropWidth,
                    height: cropHeight,
                    left: left,
                    top: top,
                    documentType: documentType,
                  )
                else if (_selectedScanType == 'batch')
                  BatchScan(
                    isGridVisible: _isGridVisible,
                    bottomPadding: _bottomContainerHeight,
                  )
                else if (_selectedScanType == 'single')
                    SingleScan(
                      isGridVisible: _isGridVisible,
                      bottomPadding: _bottomContainerHeight,
                    ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    key: _bottomContainerKey,
                    height: 150,
                    padding:
                    const EdgeInsets.only(top: 16, left: 16, right: 16),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                      border: Border(
                        top: BorderSide(
                          color: AppColors.primary,
                          width: 1,
                        ),
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        SizedBox(
                          height: 40,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: [
                              _buildScanTypeButton('business_card',
                                  _selectedScanType == 'business_card'),
                              const SizedBox(width: 18),
                              _buildScanTypeButton(
                                  'single', _selectedScanType == 'single'),
                              const SizedBox(width: 18),
                              _buildScanTypeButton(
                                  'batch', _selectedScanType == 'batch'),
                              const SizedBox(width: 18),
                              _buildScanTypeButton(
                                  'id_card', _selectedScanType == 'id_card'),
                              const SizedBox(width: 18),
                              _buildScanTypeButton('passport',
                                  _selectedScanType == 'passport'),
                              const SizedBox(width: 18),
                              _buildScanTypeButton(
                                  'legal', _selectedScanType == 'legal'),
                              const SizedBox(width: 18),
                              _buildScanTypeButton(
                                  'letter', _selectedScanType == 'letter'),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(
                              top: 4, left: 22, right: 22),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                icon: SvgPicture.asset(
                                  'assets/icons/gallery_option_icon.svg',
                                  height: 26,
                                  width: 26,
                                ),
                                onPressed: _pickImageFromGallery,
                              ),
                              GestureDetector(
                                onTap: _captureImage,
                                child: Container(
                                  width: 64,
                                  height: 64,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: AppColors.primary, width: 3),
                                  ),
                                  child: const Padding(
                                    padding: EdgeInsets.all(3.0),
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              (_isBatchModeActive && _batchImages.isNotEmpty) ||
                                  _recentImages.isNotEmpty
                                  ? GestureDetector(
                                onTap: _isBatchModeActive
                                    ? _completeBatchCapture
                                    : _viewRecentImage,
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    borderRadius:
                                    BorderRadius.circular(8),
                                    border: Border.all(
                                      color: AppColors.primary
                                          .withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: _isBatchModeActive
                                      ? Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      ClipRRect(
                                        borderRadius:
                                        BorderRadius.circular(
                                            7),
                                        child: Image.file(
                                          _batchImages.last,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      Positioned(
                                        top: 0,
                                        right: 0,
                                        child: Container(
                                          padding:
                                          const EdgeInsets.all(
                                              2),
                                          decoration:
                                          const BoxDecoration(
                                            color:
                                            AppColors.primary,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Text(
                                            '${_batchImages.length}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight:
                                              FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                      : ClipRRect(
                                    borderRadius:
                                    BorderRadius.circular(7),
                                    child: Image.file(
                                      _recentImages[0],
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              )
                                  : const SizedBox(width: 40, height: 40),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}