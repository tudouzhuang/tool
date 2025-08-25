import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../utils/app_colors.dart';

class OcrCameraScreen extends StatefulWidget {
  const OcrCameraScreen({super.key});

  @override
  State<OcrCameraScreen> createState() => _OcrCameraScreenState();
}

class _OcrCameraScreenState extends State<OcrCameraScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription> cameras = [];
  bool _isCameraInitialized = false;
  bool _isCameraPermissionGranted = false;
  String _errorMessage = '';
  bool _isLoading = true;
  String _selectedScanType = 'Single';
  final List<File> _capturedImages = [];
  final ImagePicker _imagePicker = ImagePicker();
  bool _isFlashOn = false;
  bool _isGridVisible = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _requestCameraPermission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    setState(() {
      _isCameraPermissionGranted = status.isGranted;
      _isLoading = false;
    });

    if (status.isGranted) {
      _initializeControllerAfterPermission();
    } else {
      setState(() {
        _errorMessage = 'camera_permission_required'.tr;
      });
    }
  }

  Future<void> _initializeControllerAfterPermission() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      cameras = await availableCameras();

      if (cameras.isEmpty) {
        setState(() {
          _errorMessage = 'no_cameras_found'.tr;
          _isLoading = false;
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
      });
    } catch (e) {
      setState(() {
        _errorMessage = '${'camera_initialization_failed'.tr}: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _captureImage() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      return;
    }

    try {
      final XFile photo = await _controller!.takePicture();
      final File imageFile = File(photo.path);

      setState(() {
        _capturedImages.add(imageFile);
      });

      if (_selectedScanType == 'Single') {
        _returnWithImages();
      }
    } catch (e) {
      print('Error capturing image: $e');
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final List<XFile> pickedFiles = await _imagePicker.pickMultiImage();
      if (pickedFiles.isNotEmpty) {
        setState(() {
          _capturedImages
              .addAll(pickedFiles.map((file) => File(file.path)).toList());
        });

        if (_selectedScanType == 'Single' && _capturedImages.isNotEmpty) {
          _returnWithImages();
        }
      }
    } catch (e) {
      print('Error selecting images: $e');
    }
  }

  void _returnWithImages() {
    Navigator.pop(context, _capturedImages);
  }

  void _selectScanType(String scanType) {
    setState(() {
      _selectedScanType = scanType;
    });
  }

  void _toggleGrid() {
    setState(() {
      _isGridVisible = !_isGridVisible;
    });
  }

  Widget _buildScanTypeButton(String label, bool isSelected) {
    return GestureDetector(
      onTap: () => _selectScanType(label),
      child: Text(
        label.toLowerCase().tr,
        style: GoogleFonts.inter(
          color: isSelected ? AppColors.primary : AppColors.saveDateColor,
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
      ),
    );
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
        _errorMessage = '${'failed_to_toggle_flash'.tr}: ${e.toString()}';
      });
      print('Error toggling flash: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (!_isCameraPermissionGranted) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.camera_alt, size: 100, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                _errorMessage.isEmpty
                    ? 'camera_permission_not_granted'.tr
                    : _errorMessage,
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _requestCameraPermission,
                child: Text('grant_camera_permission'.tr),
              ),
            ],
          ),
        ),
      );
    }

    if (!_isCameraInitialized) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Text('initializing_camera'.tr),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.primary),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          'file_name'.tr,
          style: GoogleFonts.inter(
            color: Colors.black,
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
        actions: [
          if (_capturedImages.isNotEmpty)
            GestureDetector(
              onTap: () => _returnWithImages(),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'done'.tr,
                  style: GoogleFonts.inter(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            )
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: CameraPreview(_controller!),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 150,
              padding: const EdgeInsets.only(top: 16, left: 16, right: 16),
              decoration: const BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                border: Border(
                  top: BorderSide(
                    color: AppColors.primary,
                    width: 1.0,
                  ),
                ),
              ),
              child: Column(
                children: [
                  // Scan types
                  SizedBox(
                    height: 40,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildScanTypeButton(
                            'Single', _selectedScanType == 'Single'),
                        const SizedBox(width: 24),
                        _buildScanTypeButton(
                            'Batch', _selectedScanType == 'Batch'),
                      ],
                    ),
                  ),
                  // Camera controls
                  Padding(
                    padding: const EdgeInsets.only(top: 4, left: 22, right: 22),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Gallery option
                        IconButton(
                          icon: SvgPicture.asset(
                            'assets/icons/gallery_option_icon.svg',
                            height: 26,
                            width: 26,
                          ),
                          onPressed: _pickImageFromGallery,
                        ),
                        // Capture button
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
                        // Image preview and count for batch mode
                        GestureDetector(
                          onTap: _capturedImages.isNotEmpty
                              ? () {
                            // Optionally show a larger preview or do something
                          }
                              : null,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              if (_capturedImages.isNotEmpty)
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: Image.file(
                                      _capturedImages.last,
                                      fit: BoxFit.cover,
                                      width: 40,
                                      height: 40,
                                    ),
                                  ),
                                ),
                              if (_capturedImages.isNotEmpty)
                                Positioned(
                                  top: 0,
                                  right: 2,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppColors.primary,
                                    ),
                                    child: Text(
                                      _capturedImages.length.toString(),
                                      style: GoogleFonts.inter(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}