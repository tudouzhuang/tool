import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_cropper/image_cropper.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;
import 'package:toolkit/screens/scanner_screens/result_screen.dart';
import '../../services/word_images_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_snackbar.dart';
import '../../widgets/batch_app_bar.dart';
import '../../widgets/scanner_widgets/document_preview.dart';
import 'package:provider/provider.dart';
import '../../widgets/scanner_widgets/filter_selector.dart';

class FilterProvider extends ChangeNotifier {
  String _selectedFilter = 'original'.tr;
  final Map<String, File> _filterCache = {};
  File? _baseImage;

  String get selectedFilter => _selectedFilter;

  Map<String, File> get filterCache => _filterCache;

  File? get baseImage => _baseImage;

  void setBaseImage(File image) {
    _baseImage = image;
    notifyListeners();
  }

  void setFilter(String filterName) {
    _selectedFilter = filterName;
    notifyListeners();
  }

  void addToCache(String filterName, File imageFile) {
    _filterCache[filterName] = imageFile;
  }

  void clearCache() {
    _filterCache.clear();
  }
}

class DocumentEditScreen extends StatefulWidget {
  final File imageFile;
  final bool isBatchMode;
  final List<File>? batchImages;
  final int? currentIndex;
  final bool isBusinessCard;
  final bool isPassport;
  final bool isLegal;
  final bool isLetter;
  final bool isIdCard;
  final Rect? cropRect;

  const DocumentEditScreen({
    super.key,
    required this.imageFile,
    this.isBatchMode = false,
    this.batchImages,
    this.currentIndex,
    this.isBusinessCard = false,
    this.cropRect,
    this.isPassport = false,
    this.isLegal = false,
    this.isLetter = false,
    this.isIdCard = false,
  });

  @override
  State<DocumentEditScreen> createState() => _DocumentEditScreenState();
}

class _DocumentEditScreenState extends State<DocumentEditScreen>
    with SingleTickerProviderStateMixin {
  File? _processedImage;
  bool _isRotating = false;
  bool _isFiltering = false;
  double _rotationAngle = 0;
  bool _hasChanges = false;
  late AnimationController _animationController;
  late Animation<double> _animation;
  bool _isApplyingFilter = false;
  late int _currentIndex;
  List<File> _editHistory = [];
  int _currentHistoryIndex = 0;
  final Map<String, File> _filterPreviews = {};
  bool _previewsReady = false;
  late FilterProvider _filterProvider;
  File? _baseImage;

  List<String> get _filterOptions => [
        'original'.tr,
        'cool_tone'.tr,
        'warm_tone'.tr,
        'grayscale'.tr,
        'blue_light'.tr,
        'sepia'.tr,
        'soft_pastel'.tr
      ];

  @override
  void initState() {
    super.initState();
    _processedImage = widget.imageFile;
    _baseImage = widget.imageFile;
    _currentIndex = widget.currentIndex ?? 0;
    _filterProvider = FilterProvider()..setBaseImage(_baseImage!);
    _editHistory.add(widget.imageFile);

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _animation = Tween<double>(begin: 0, end: 1).animate(_animationController)
      ..addListener(() {
        setState(() {});
      })
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          setState(() {
            _isApplyingFilter = false;
          });
        }
      });

    _preGenerateFilterPreviews();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _cropImage() async {
    if (_processedImage == null) return;

    setState(() {
      _isRotating = true;
    });

    try {
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.manual,
        overlays: [SystemUiOverlay.bottom],
      );

      final croppedFile = await ImageCropper().cropImage(
        sourcePath: _processedImage!.path,
        compressFormat: ImageCompressFormat.jpg,
        compressQuality: 90,
        maxWidth: 3000,
        maxHeight: 3000,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'crop_document'.tr,
            toolbarColor: AppColors.primary,
            toolbarWidgetColor: Colors.white,
            statusBarColor: AppColors.primary,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
            hideBottomControls: false,
            backgroundColor: Colors.white,
            activeControlsWidgetColor: AppColors.primary,
            dimmedLayerColor: Colors.black.withOpacity(0.6),
            cropFrameColor: AppColors.primary,
            cropFrameStrokeWidth: 3,
            cropGridColor: AppColors.primary.withOpacity(0.5),
            cropGridStrokeWidth: 1,
            showCropGrid: true,
            cropGridRowCount: 3,
            cropGridColumnCount: 3,
          ),
          IOSUiSettings(
            title: 'crop_document'.tr,
            aspectRatioLockEnabled: false,
            resetAspectRatioEnabled: false,
            aspectRatioPickerButtonHidden: true,
            doneButtonTitle: 'done'.tr,
            cancelButtonTitle: 'cancel'.tr,
            rotateButtonsHidden: true,
            rotateClockwiseButtonHidden: true,
            hidesNavigationBar: false,
            minimumAspectRatio: 0.1,
            rectX: 0.0,
            rectY: 0.0,
            rectWidth: 1.0,
            rectHeight: 1.0,
          ),
        ],
      );

      if (croppedFile != null) {
        setState(() {
          _processedImage = File(croppedFile.path);
          _baseImage = File(croppedFile.path);
          _filterProvider.setBaseImage(_baseImage!);
          _hasChanges = true;
        });

        _addToHistory(File(croppedFile.path));
        _filterProvider.clearCache();
        _preGenerateFilterPreviews();
      }
    } catch (e) {
      debugPrint('${'error_cropping_image'.tr}: $e');
      if (mounted) {
        AppSnackBar.show(context, message: 'failed_to_crop_image'.tr);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRotating = false;
        });
      }
    }
  }

  Future<void> _preGenerateFilterPreviews() async {
    for (String filter in _filterOptions) {
      File preview = await _generateFilterPreview(filter);
      _filterPreviews[filter] = preview;
    }

    if (mounted) {
      setState(() {
        _previewsReady = true;
      });
    }
  }

  Future<void> _rotateImage() async {
    setState(() {
      _isRotating = true;
    });

    try {
      final imageBytes = await _processedImage!.readAsBytes();
      final image = img.decodeImage(imageBytes)!;
      final rotatedImage = img.copyRotate(image, angle: 90);
      final newPath = await _saveTempImage(rotatedImage);

      setState(() {
        _rotationAngle += 90;
        _processedImage = File(newPath);
        _baseImage = File(newPath);
        _filterProvider.setBaseImage(_baseImage!);
        _hasChanges = true;
      });

      _addToHistory(File(newPath));
      _filterProvider.clearCache();
      _preGenerateFilterPreviews();
    } catch (e) {
      if (kDebugMode) {
        print('${'error_rotating_image'.tr}: $e');
      }
    } finally {
      setState(() {
        _isRotating = false;
      });
    }
  }

  void _addToHistory(File imageFile) {
    if (_currentHistoryIndex < _editHistory.length - 1) {
      _editHistory = _editHistory.sublist(0, _currentHistoryIndex + 1);
    }

    _editHistory.add(imageFile);
    _currentHistoryIndex = _editHistory.length - 1;
  }

  void _undo() {
    if (_currentHistoryIndex > 0) {
      _currentHistoryIndex--;
      setState(() {
        _processedImage = _editHistory[_currentHistoryIndex];
        _hasChanges = true;
      });
    }
  }

  void _redo() {
    if (_currentHistoryIndex < _editHistory.length - 1) {
      _currentHistoryIndex++;
      setState(() {
        _processedImage = _editHistory[_currentHistoryIndex];
        _hasChanges = true;
      });
    }
  }

  Future<void> _applyFilter(String filterName) async {
    _filterProvider.setFilter(filterName);

    if (filterName == 'original'.tr) {
      setState(() {
        _processedImage = _baseImage;
        _hasChanges = true;
      });
      _addToHistory(_baseImage!);
      return;
    }

    setState(() {
      _isApplyingFilter = true;
    });
    _animationController.reset();
    _animationController.forward();

    try {
      final cacheKey = '${_baseImage!.path}_$filterName';

      if (_filterProvider.filterCache.containsKey(cacheKey)) {
        setState(() {
          _processedImage = _filterProvider.filterCache[cacheKey];
          _hasChanges = true;
        });
        _addToHistory(_filterProvider.filterCache[cacheKey]!);
        return;
      }

      final imageBytes = await _baseImage!.readAsBytes();
      var image = img.decodeImage(imageBytes)!;

      if (filterName == 'sepia'.tr) {
        image = img.sepia(image);
        image = img.adjustColor(image, contrast: 1.3);
      } else if (filterName == 'cool_tone'.tr) {
        image = img.colorOffset(image, blue: 20, green: 10);
        image = img.adjustColor(image, contrast: 1.2, gamma: 1.0);
      } else if (filterName == 'warm_tone'.tr) {
        image = img.colorOffset(image, red: 20, green: 10);
        image = img.adjustColor(image, contrast: 1.2, gamma: 1.0);
      } else if (filterName == 'grayscale'.tr) {
        image = img.grayscale(image);
        image = img.adjustColor(image, contrast: 1.4);
      } else if (filterName == 'blue_light'.tr) {
        image = img.colorOffset(image, blue: 30);
        image = img.adjustColor(image, contrast: 1.25);
      } else if (filterName == 'soft_pastel'.tr) {
        image = img.adjustColor(image, saturation: 0.5, contrast: 1.1);
      } else {
        image = img.adjustColor(image, contrast: 1.1);
      }

      final newPath = await _saveTempImage(image);
      File filteredImage = File(newPath);

      _filterProvider.addToCache(cacheKey, filteredImage);

      setState(() {
        _processedImage = filteredImage;
        _hasChanges = true;
      });

      _addToHistory(filteredImage);
    } catch (e) {
      if (kDebugMode) {
        print('${'error_applying_filter'.tr}: $e');
      }
      if (mounted) {
        AppSnackBar.show(context, message: 'failed_to_apply_filter'.tr);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isApplyingFilter = false;
        });
      }
    }
  }

  Future<String> _saveTempImage(img.Image image) async {
    final directory = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final newPath = '${directory.path}/filtered_$timestamp.jpg';
    await File(newPath).writeAsBytes(img.encodeJpg(image));
    return newPath;
  }

  void _saveDocument() async {
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final newPath = '${directory.path}/edited_document_$timestamp.jpg';
    await _processedImage!.copy(newPath);

    if (mounted) {
      Navigator.pop(context, File(newPath));
    }
  }

  void _retakePhoto() {
    Navigator.pop(context, null);
  }

  void _toggleFilterView() {
    setState(() {
      _isFiltering = !_isFiltering;
    });
  }

  void _handleSave() async {
    if (_isFiltering) {
      setState(() {
        _isFiltering = false;
      });
    } else {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      );

      try {
        List<File> imagesToSave = [];
        if (widget.isBatchMode && widget.batchImages != null) {
          imagesToSave = widget.batchImages!;
        } else if (_processedImage != null) {
          imagesToSave = [_processedImage!];
        }

        final wordFile =
            await WordImagesService.createWordDocument(imagesToSave);

        if (mounted) {
          Navigator.pop(context);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ResultScreen(wordDocument: wordFile),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          Navigator.pop(context);
          AppSnackBar.show(context,
              message: '${'failed_to_create_document'.tr}: $e');
        }
      }
    }
  }

  Future<File> _generateFilterPreview(String filterName) async {
    final originalImageBytes = await _baseImage!.readAsBytes();
    var image = img.decodeImage(originalImageBytes)!;
    image = img.copyResize(image, width: 100);

    if (filterName == 'sepia'.tr) {
      image = img.sepia(image);
    } else if (filterName == 'cool_tone'.tr) {
      image = img.colorOffset(image, blue: 20, green: 10);
    } else if (filterName == 'warm_tone'.tr) {
      image = img.colorOffset(image, red: 20, green: 10);
    } else if (filterName == 'grayscale'.tr) {
      image = img.grayscale(image);
    } else if (filterName == 'blue_light'.tr) {
      image = img.colorOffset(image, blue: 30);
    } else if (filterName == 'soft_pastel'.tr) {
      image = img.adjustColor(image, saturation: 0.5, contrast: 0.9);
    }

    final directory = await getTemporaryDirectory();
    final newPath =
        '${directory.path}/preview_${filterName}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    await File(newPath).writeAsBytes(img.encodeJpg(image));
    return File(newPath);
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _filterProvider,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
          systemNavigationBarColor: Colors.white,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
        child: Scaffold(
          backgroundColor: AppColors.scannerBackground,
          appBar: BatchAppBar(
            onNextPressed: _handleSave,
            onBackPressed: () {
              if (_isFiltering) {
                setState(() {
                  _isFiltering = false;
                });
              } else {
                Navigator.pop(context);
              }
            },
            actionText: 'done'.tr,
          ),
          body: Column(
            children: [
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (_processedImage != null)
                      Center(
                        child: DocumentPreview(
                          image: _processedImage!,
                        ),
                      ),
                    Positioned(
                      bottom: 38,
                      child: Container(
                        height: 32,
                        width: 100,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            GestureDetector(
                              onTap: _currentHistoryIndex > 0 ? _undo : null,
                              child: SvgPicture.asset(
                                'assets/icons/undo_icon.svg',
                                width: 16,
                                height: 16,
                                color: _currentHistoryIndex > 0
                                    ? AppColors.primary
                                    : Colors.grey.shade400,
                              ),
                            ),
                            GestureDetector(
                              onTap:
                                  _currentHistoryIndex < _editHistory.length - 1
                                      ? _redo
                                      : null,
                              child: SvgPicture.asset(
                                'assets/icons/redo_icon.svg',
                                width: 16,
                                height: 16,
                                color: _currentHistoryIndex <
                                        _editHistory.length - 1
                                    ? AppColors.primary
                                    : Colors.grey.shade400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_isApplyingFilter)
                      Positioned.fill(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 100),
                              height: constraints.maxHeight * 0.03,
                              width: constraints.maxWidth,
                              margin: EdgeInsets.only(
                                top: constraints.maxHeight * (_animation.value),
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    AppColors.primary.withOpacity(0.8),
                                    AppColors.primary.withOpacity(0.0),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 6,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    if (_isFiltering)
                      Expanded(
                        child: FilterSelector(
                          filterOptions: _filterOptions,
                          onFilterSelected: _applyFilter,
                          filterPreviews: _filterPreviews,
                          previewsReady: _previewsReady,
                        ),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildEditToolButton(
                              assetPath: 'assets/icons/retake_icon.svg',
                              label: 'retake'.tr,
                              onTap: _retakePhoto,
                            ),
                            _buildEditToolButton(
                              assetPath: 'assets/icons/filters_icon.svg',
                              label: 'filters'.tr,
                              isActive: _isFiltering,
                              onTap: _toggleFilterView,
                            ),
                            _buildEditToolButton(
                              assetPath: 'assets/icons/crop_icon.svg',
                              label: 'crop'.tr,
                              onTap: _cropImage,
                            ),
                            _buildEditToolButton(
                              assetPath: 'assets/icons/rotate_icon.svg',
                              label: 'rotate'.tr,
                              onTap: _rotateImage,
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
    );
  }

  Widget _buildEditToolButton({
    required String assetPath,
    required String label,
    bool isActive = false,
    bool disabled = false,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: Opacity(
        opacity: disabled ? 0.5 : 1.0,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isActive
                    ? AppColors.primary.withOpacity(0.1)
                    : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isActive ? AppColors.primary : Colors.grey.shade300,
                  width: 1,
                ),
              ),
              child: Center(
                child: SvgPicture.asset(
                  assetPath,
                  width: 22,
                  height: 22,
                  color: disabled ? Colors.grey : null,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w400,
                color: disabled ? Colors.grey : AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
