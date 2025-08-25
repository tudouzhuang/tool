import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:open_file/open_file.dart';
import 'package:provider/provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:flutter/rendering.dart';
import 'package:toolkit/widgets/cv_templates/template4.dart';
import 'package:toolkit/widgets/cv_templates/template_2.dart';
import 'package:toolkit/widgets/cv_templates/template_3.dart';
import 'dart:ui' as ui;

import '../../models/language_model.dart';
import '../../models/skills_model.dart';
import '../../models/user_model_1.dart';
import '../../models/website_model.dart';
import '../../provider/certification_provider.dart';
import '../../provider/education_provider.dart';
import '../../provider/language_provider.dart';
import '../../provider/saved_cv_provider.dart';
import '../../provider/skills_provider.dart';
import '../../provider/template_provider.dart';
import '../../provider/user_provider.dart';
import '../../provider/work_experience_provider.dart';
import '../../screens/cv_maker_screens/base_cv_template_screen.dart';
import '../../screens/cv_maker_screens/create_cv_screen.dart'
    show CreateCvScreen;
import '../../utils/app_colors.dart';
import '../../utils/app_snackbar.dart';
import '../cv_widgets/template_selection_dialog.dart';

class Template1 extends StatefulWidget {
  final List<Website> websites;

  const Template1({super.key, this.websites = const []});

  @override
  State<Template1> createState() => _Template1State();
}

class _Template1State extends State<Template1> {
  int _currentPage = 1;
  int _totalPages = 1;
  List<Widget> _allContentWidgets = [];
  final Map<Key, double> _widgetHeights = {};
  final double _pageContentHeight = 462;
  List<GlobalKey> _pageKeys = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Build content sections when dependencies change
    _buildAllContent();
    _calculateTotalPages();
    _initializePageKeys();
  }

  void _initializePageKeys() {
    _pageKeys = List.generate(_totalPages, (index) => GlobalKey());
  }

  void _buildAllContent() {
    final userData = Provider.of<UserProvider>(context).userData;
    final workExperienceProvider = Provider.of<WorkExperienceProvider>(context);
    final workExperienceItems = workExperienceProvider.workExperienceItems;
    final educationProvider = Provider.of<EducationProvider>(context);
    final educationItems = educationProvider.educationItems;
    final certificationProvider = Provider.of<CertificationProvider>(context);
    final certificationItems = certificationProvider.certificationItems;
    final skillsProvider = Provider.of<SkillsProvider>(context);
    final skillItems = skillsProvider.skillItems;
    final languageProvider = Provider.of<LanguageProvider>(context);
    final languageItems = languageProvider.languages;

    _allContentWidgets = [];

    // Add header with a key for height calculation - always on first page
    final headerKey = GlobalKey();
    _allContentWidgets.add(KeyedSubtree(
      key: headerKey,
      child: _buildHeader(userData),
    ));

    // Objective section with key
    if (userData.careerObjective != null &&
        userData.careerObjective!.isNotEmpty) {
      final objTitleKey = GlobalKey();
      final objContentKey = GlobalKey();

      _allContentWidgets.add(KeyedSubtree(
        key: objTitleKey,
        child: _buildSectionWithDivider('Objective'),
      ));
      _allContentWidgets.add(const SizedBox(height: 4));
      _allContentWidgets.add(KeyedSubtree(
        key: objContentKey,
        child: _buildObjectiveContent(userData),
      ));
      _allContentWidgets.add(const SizedBox(height: 6));
    }

    // Work Experience section with keys
    if (workExperienceItems.isNotEmpty) {
      final expTitleKey = GlobalKey();
      _allContentWidgets.add(KeyedSubtree(
        key: expTitleKey,
        child: _buildSectionWithDivider('EXPERIENCES'),
      ));
      _allContentWidgets.add(const SizedBox(height: 4));

      // Each work experience item gets its own key
      for (int i = 0; i < workExperienceItems.length; i++) {
        final expItemKey = GlobalKey();
        final item = workExperienceItems[i];

        String dateRange = item.isCurrent
            ? "${item.startDate} - Present"
            : "${item.startDate} - ${item.endDate}";

        _allContentWidgets.add(KeyedSubtree(
          key: expItemKey,
          child: _buildExperienceItem(
            item.position,
            item.company,
            item.description,
            dateRange,
            bulletPoints: item.projects.isNotEmpty ? item.projects : null,
            projectUrls: item.projectUrls.isNotEmpty ? item.projectUrls : null,
          ),
        ));

        // Add spacing between items but not after the last one
        if (i < workExperienceItems.length - 1) {
          _allContentWidgets.add(const SizedBox(height: 4));
        }
      }

      _allContentWidgets.add(const SizedBox(height: 6));
    }

    // Education section with keys
    if (educationItems.isNotEmpty) {
      final eduTitleKey = GlobalKey();
      _allContentWidgets.add(KeyedSubtree(
        key: eduTitleKey,
        child: _buildSectionWithDivider('EDUCATION'),
      ));
      _allContentWidgets.add(const SizedBox(height: 4));

      // Each education item gets its own key
      for (int i = 0; i < educationItems.length; i++) {
        final eduItemKey = GlobalKey();
        final item = educationItems[i];

        String dateRange = item.isCompleted
            ? "${item.startDate} - Present"
            : "${item.startDate} - ${item.endDate}";

        _allContentWidgets.add(KeyedSubtree(
          key: eduItemKey,
          child: _buildEducationItem(
            item.degree,
            item.institute,
            dateRange,
            description: item.description,
          ),
        ));

        // Add spacing between items but not after the last one
        if (i < educationItems.length - 1) {
          _allContentWidgets.add(const SizedBox(height: 4));
        }
      }

      _allContentWidgets.add(const SizedBox(height: 6));
    }

    // Certifications section with keys
    if (certificationItems.isNotEmpty) {
      final certTitleKey = GlobalKey();
      _allContentWidgets.add(KeyedSubtree(
        key: certTitleKey,
        child: _buildSectionWithDivider('CERTIFICATIONS'),
      ));
      _allContentWidgets.add(const SizedBox(height: 4));

      // Each certification item gets its own key
      for (int i = 0; i < certificationItems.length; i++) {
        final certItemKey = GlobalKey();
        final item = certificationItems[i];

        String dateRange = item.startDate;

        _allContentWidgets.add(KeyedSubtree(
          key: certItemKey,
          child: _buildCertificationItem(
            item.certificationName,
            item.description,
            dateRange,
          ),
        ));

        // Add spacing between items but not after the last one
        if (i < certificationItems.length - 1) {
          _allContentWidgets.add(const SizedBox(height: 4));
        }
      }

      _allContentWidgets.add(const SizedBox(height: 6));
    }

    // Skills section with key
    if (skillItems.isNotEmpty) {
      final skillsTitleKey = GlobalKey();
      final skillsContentKey = GlobalKey();

      _allContentWidgets.add(KeyedSubtree(
        key: skillsTitleKey,
        child: _buildSectionWithDivider('Skills'),
      ));
      _allContentWidgets.add(const SizedBox(height: 4));
      _allContentWidgets.add(KeyedSubtree(
        key: skillsContentKey,
        child: _buildSkillsList(skillItems),
      ));
      _allContentWidgets.add(const SizedBox(height: 6));
    }

    // Languages section with key
    if (languageItems.isNotEmpty) {
      final langTitleKey = GlobalKey();
      final langContentKey = GlobalKey();

      _allContentWidgets.add(KeyedSubtree(
        key: langTitleKey,
        child: _buildSectionWithDivider('LANGUAGES'),
      ));
      _allContentWidgets.add(const SizedBox(height: 4));
      _allContentWidgets.add(KeyedSubtree(
        key: langContentKey,
        child: _buildLanguagesList(languageItems),
      ));
      _allContentWidgets.add(const SizedBox(height: 6));
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _measureActualWidgetHeights();
    });
  }

  void _measureActualWidgetHeights() {
    // Clear previous measurements
    _widgetHeights.clear();

    // Measure each widget with a key
    for (var widget in _allContentWidgets) {
      if (widget is KeyedSubtree && widget.key != null) {
        final RenderBox? renderBox = (widget.key as GlobalKey)
            .currentContext
            ?.findRenderObject() as RenderBox?;
        if (renderBox != null && renderBox.hasSize) {
          _widgetHeights[widget.key!] = renderBox.size.height;
        }
      }
    }

    // Recalculate pagination with actual measurements
    _calculateTotalPages();
    setState(() {});
  }

  void _showTemplateSelectionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const TemplateSelectionDialog(),
    ).then((selectedTemplateId) {
      if (selectedTemplateId != null) {
        _changeTemplate(selectedTemplateId);
      }
    });
  }

  Future<Map<String, dynamic>> _collectAllFormData() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final workExpProvider =
        Provider.of<WorkExperienceProvider>(context, listen: false);
    final educationProvider =
        Provider.of<EducationProvider>(context, listen: false);
    final certificationProvider =
        Provider.of<CertificationProvider>(context, listen: false);
    final skillsProvider = Provider.of<SkillsProvider>(context, listen: false);
    final languageProvider =
        Provider.of<LanguageProvider>(context, listen: false);
    final templateProvider =
        Provider.of<TemplateProvider>(context, listen: false);

    return {
      'personalInfo': {
        'fullName': userProvider.userData.fullName,
        'designation': userProvider.userData.designation,
        'email': userProvider.userData.email,
        'phoneNumber': userProvider.userData.phoneNumber,
        'profileImagePath': userProvider.userData.profileImagePath,
      },
      'careerObjective': userProvider.userData.careerObjective,
      'education':
          educationProvider.educationItems.map((e) => e.toMap()).toList(),
      'workExperience':
          workExpProvider.workExperienceItems.map((e) => e.toMap()).toList(),
      'certifications': certificationProvider.certificationItems
          .map((e) => e.toMap())
          .toList(),
      'skills': skillsProvider.skillItems.map((e) => e.toMap()).toList(),
      'languages': languageProvider.languages.map((e) => e.toMap()).toList(),
      // 'websites': userProvider.websites.map((e) => e.toMap()).toList(),
      'templateId': templateProvider.selectedTemplateId,
    };
  }

  Future<void> _exportAsPdf({required bool openAfterExport}) async {
    try {
      // First collect all form data
      final formData = await _collectAllFormData();

      final pdf = pw.Document();
      List<Uint8List> pageImages = [];

      // Capture all pages as images
      for (int i = 0; i < _pageKeys.length; i++) {
        final imageBytes = await _capturePageAsImage(_pageKeys[i]);
        if (imageBytes != null) {
          pageImages.add(imageBytes);
          pdf.addPage(
            pw.Page(
              pageFormat: PdfPageFormat.a4,
              build: (pw.Context context) {
                return pw.Center(child: pw.Image(pw.MemoryImage(imageBytes)));
              },
            ),
          );
        }
      }

      // Get the Downloads directory
      Directory? directory;
      if (Platform.isAndroid) {
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          directory = await getExternalStorageDirectory();
        }
      } else if (Platform.isIOS) {
        directory = await getApplicationDocumentsDirectory();
      }

      if (directory == null) {
        throw Exception('Could not access storage directory');
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'CV_$timestamp.pdf';
      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);

      await file.writeAsBytes(await pdf.save());

      // Create a thumbnail from the first page
      Uint8List? thumbnailBytes;
      if (pageImages.isNotEmpty) {
        thumbnailBytes = await _createThumbnail(pageImages.first);
      }

      // Get template ID
      final templateProvider =
          Provider.of<TemplateProvider>(context, listen: false);
      final templateId = templateProvider.selectedTemplateId;

      // Save to SavedCVProvider with all required parameters
      final savedCVProvider =
          Provider.of<SavedCVProvider>(context, listen: false);
      await savedCVProvider.addSavedCV(
        fileName: fileName,
        filePath: filePath,
        thumbnailBytes: thumbnailBytes,
        templateId: templateId,
        formData: formData,
      );

      if (mounted) {
        AppSnackBar.show(
          context,
          message: 'PDF saved successfully',
        );
      }

      // Open the file if requested
      if (openAfterExport) {
        if (Platform.isAndroid || Platform.isIOS) {
          await OpenFile.open(filePath);
        }
      }

      // Clear all provider data after successful export
      _clearAllData();
    } catch (e) {
      if (mounted) {
        AppSnackBar.show(
          context,
          message: 'Error: ${e.toString()}',
        );
      }
      debugPrint('Export error: $e');
    }
  }

  Future<Uint8List> _createThumbnail(Uint8List imageBytes) async {
    try {
      // Create a smaller version of the image for thumbnail
      final codec = await ui.instantiateImageCodec(
        imageBytes,
        targetWidth: 200, // Adjust thumbnail size as needed
      );
      final frame = await codec.getNextFrame();
      final byteData =
          await frame.image.toByteData(format: ui.ImageByteFormat.png);
      return byteData!.buffer.asUint8List();
    } catch (e) {
      debugPrint('Error creating thumbnail: $e');
      rethrow;
    }
  }

// Add this method to clear all provider data
  void _clearAllData() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final workExpProvider =
        Provider.of<WorkExperienceProvider>(context, listen: false);
    final educationProvider =
        Provider.of<EducationProvider>(context, listen: false);
    final certificationProvider =
        Provider.of<CertificationProvider>(context, listen: false);
    final skillsProvider = Provider.of<SkillsProvider>(context, listen: false);
    final languageProvider =
        Provider.of<LanguageProvider>(context, listen: false);

    // Clear all data from providers
    userProvider.clearUserData();
    workExpProvider.clearWorkExperienceItems();
    educationProvider.clearEducationItems();
    certificationProvider.clearCertificationItems();
    skillsProvider.clearSkillItems();
    languageProvider.clearLanguages();
  }

// Modify the redirect method to also clear data
  void _redirectToCreateCvScreen() {
    // Clear data before redirecting (as a backup)
    _clearAllData();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const CreateCvScreen()),
      (Route<dynamic> route) => false,
    );
  }

// Method to handle template change
  void _changeTemplate(int templateId) {
    final templateProvider =
        Provider.of<TemplateProvider>(context, listen: false);
    templateProvider.setTemplate(templateId, 'Template $templateId');

    final websites = Provider.of<UserProvider>(context, listen: false).websites;

    Widget templateScreen;

    switch (templateId) {
      case 1:
        templateScreen = Template1(websites: websites);
        break;
      case 2:
        templateScreen = Template2(websites: websites);
        break;
      case 3:
        templateScreen = Template3(websites: websites);
        break;
      case 4:
        templateScreen = Template4(websites: websites);
        break;
      default:
        templateScreen = Template1(websites: websites);
    }

    // Replace the current route with the new template
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => templateScreen,
      ),
    );
  }

  void _calculateTotalPages() {
    double totalHeight = 0;

    for (var widget in _allContentWidgets) {
      if (widget is KeyedSubtree && widget.key != null) {
        totalHeight += _widgetHeights[widget.key!] ?? 0;
      } else if (widget is SizedBox) {
        totalHeight += widget.height ?? 0;
      }
    }

    // Calculate pages based on actual total height
    _totalPages = (totalHeight / _pageContentHeight).ceil();
    if (_totalPages < 1) _totalPages = 1;

    // Reset current page if it's now out of range
    if (_currentPage > _totalPages) {
      _currentPage = 1;
    }

    // Re-initialize page keys if the number of pages changed
    if (_pageKeys.length != _totalPages) {
      _initializePageKeys();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseCVTemplateScreen(
      cvContent: Column(
        children: [
          for (int i = 1; i <= _totalPages; i++) ...[
            RepaintBoundary(
              key: _pageKeys[i - 1],
              child: _buildPage(i),
            ),
            if (i < _totalPages) const SizedBox(height: 30),
          ]
        ],
      ),
      pageKeys: _pageKeys,
      totalPages: _totalPages,
    );
  }

  Widget _buildPage(int pageIndex) {
    // Get content for this page
    List<Widget> contentForPage = _getContentForPage(pageIndex);

    return Container(
      constraints: const BoxConstraints(
          maxWidth: 340, minWidth: 340, minHeight: 482, maxHeight: 482),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(10),
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        // Prevent scrolling within the page
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, // Important to prevent overflow
          children: [
            // Show page number at the top right if not the first page
            if (pageIndex > 1) ...[
              Align(
                alignment: Alignment.topRight,
                child: Text(
                  'Page $pageIndex',
                  style: GoogleFonts.poppins(
                    fontSize: 8,
                    color: Colors.grey,
                  ),
                ),
              ),
              const SizedBox(height: 4),
            ],

            // Content for this page
            ...contentForPage,
          ],
        ),
      ),
    );
  }

  List<Widget> _getContentForPage(int pageIndex) {
    if (_allContentWidgets.isEmpty) return [];

    // Calculate which widgets should be on this page based on actual heights
    double currentHeight = 0;
    int startIndex = 0;
    int endIndex = 0;

    // First, find the start index for the current page
    if (pageIndex == 1) {
      startIndex = 0; // First page always starts at the beginning
    } else {
      // For subsequent pages, calculate where the previous page ended
      int currentPage = 1;
      double pageHeight = 0;

      for (int i = 0; i < _allContentWidgets.length; i++) {
        Widget widget = _allContentWidgets[i];
        double widgetHeight = 0;

        if (widget is KeyedSubtree && widget.key != null) {
          widgetHeight = _widgetHeights[widget.key!] ?? 0;
        } else if (widget is SizedBox) {
          widgetHeight = widget.height ?? 0;
        }

        // If adding this widget would exceed the page height,
        // move to the next page
        if (pageHeight + widgetHeight > _pageContentHeight) {
          currentPage++;
          pageHeight = widgetHeight; // Start the new page with this widget
        } else {
          pageHeight += widgetHeight;
        }

        // If we've reached the requested page, this is our start index
        if (currentPage == pageIndex) {
          startIndex = i;
          break;
        }
      }
    }

    // Now find the end index for the content that fits on this page
    currentHeight = 0;
    bool pageHasContent = false;

    for (int i = startIndex; i < _allContentWidgets.length; i++) {
      Widget widget = _allContentWidgets[i];
      double widgetHeight = 0;

      if (widget is KeyedSubtree && widget.key != null) {
        widgetHeight = _widgetHeights[widget.key!] ?? 0;
      } else if (widget is SizedBox) {
        widgetHeight = widget.height ?? 0;
      }

      // If adding this widget would exceed the page height,
      // this is our end index
      if (currentHeight + widgetHeight > _pageContentHeight && pageHasContent) {
        endIndex = i;
        break;
      } else {
        currentHeight += widgetHeight;
        pageHasContent = true;
        endIndex = i + 1; // Include this widget
      }
    }

    // Return the widgets for this page
    if (startIndex < _allContentWidgets.length) {
      return _allContentWidgets.sublist(startIndex, endIndex);
    } else {
      return [];
    }
  }

  // PDF Export Functionality

  Future<Uint8List?> _capturePageAsImage(GlobalKey key) async {
    try {
      final RenderRepaintBoundary boundary =
          key.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData != null) {
        return byteData.buffer.asUint8List();
      }
      return null;
    } catch (e) {
      print('Error capturing page as image: $e');
      return null;
    }
  }

  // Widget building methods remain the same
  Widget _buildHeader(UserModel userData) {
    // Get all websites from the UserProvider
    final websites = Provider.of<UserProvider>(context).websites;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          userData.fullName ?? '',
          style: GoogleFonts.inriaSerif(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          userData.designation ?? '',
          style: GoogleFonts.inriaSerif(
            fontSize: 10,
            color: AppColors.black,
          ),
        ),
        const SizedBox(height: 6),

        // Modified contact info layout to wrap properly
        Wrap(
          spacing: 12, // Space between items on same line
          runSpacing: 4, // Space between lines
          children: [
            // Phone number
            if (userData.phoneNumber != null &&
                userData.phoneNumber!.isNotEmpty)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SvgPicture.asset(
                    'assets/icons/contact_icon.svg',
                    width: 6,
                    height: 6,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    userData.phoneNumber!,
                    style: GoogleFonts.inriaSerif(
                      fontSize: 8,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),

            // Email
            if (userData.email != null && userData.email!.isNotEmpty)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SvgPicture.asset(
                    'assets/icons/email_icon.svg',
                    width: 6,
                    height: 6,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    userData.email!,
                    style: GoogleFonts.inriaSerif(
                      fontSize: 8,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),

            // Website URL from UserModel (if present)
            if (userData.websiteUrl != null &&
                userData.websiteUrl!.isNotEmpty &&
                !websites.any((website) => website.url == userData.websiteUrl))
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SvgPicture.asset(
                    'assets/icons/url_icon.svg',
                    width: 6,
                    height: 6,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    userData.websiteUrl!,
                    style: GoogleFonts.inriaSerif(
                      fontSize: 8,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),

            // All additional websites from provider
            ...websites
                .map((website) => Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SvgPicture.asset(
                          'assets/icons/url_icon.svg',
                          width: 6,
                          height: 6,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          website.url,
                          style: GoogleFonts.inriaSerif(
                            fontSize: 8,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ))
                ,
          ],
        ),
        // Add spacing before the first section (Objective)
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildSectionWithDivider(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 8,
            fontWeight: FontWeight.w600,
          ),
        ),
        Container(
          height: 1,
          color: Colors.grey.shade300,
        ),
      ],
    );
  }

  Widget _buildObjectiveContent(UserModel userData) {
    return Text(
      userData.careerObjective ?? '',
      style: GoogleFonts.inter(
        fontSize: 6,
        color: Colors.grey.shade800,
      ),
    );
  }

  Widget _buildExperienceItem(
      String? title, String? company, String? description, String dateRange,
      {List<String>? bulletPoints, List<String>? projectUrls}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                title ?? '',
                style: GoogleFonts.poppins(
                  fontSize: 8,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Text(
              dateRange,
              style: GoogleFonts.poppins(
                fontSize: 7,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          company ?? '',
          style: GoogleFonts.poppins(
            fontSize: 7,
            color: Colors.grey.shade700,
            fontStyle: FontStyle.italic,
          ),
        ),
        if (description != null && description.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            description,
            style: GoogleFonts.inter(
              fontSize: 6,
              color: Colors.grey.shade800,
            ),
          ),
        ],
        if (bulletPoints != null && bulletPoints.isNotEmpty) ...[
          const SizedBox(height: 2),
          ...bulletPoints.asMap().entries.map((entry) {
            final index = entry.key;
            final point = entry.value;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('• ',
                        style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold, fontSize: 6)),
                    Expanded(
                      child: Text(
                        point,
                        style: GoogleFonts.inter(
                          fontSize: 6,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
                // Add project URL if available
                if (projectUrls != null &&
                    index < projectUrls.length &&
                    projectUrls[index].isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 6, top: 1),
                    child: GestureDetector(
                      onTap: () {
                        // Handle URL tap if needed
                      },
                      child: Text(
                        projectUrls[index],
                        style: GoogleFonts.inter(
                          fontSize: 6,
                          color: Colors.blue,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
              ],
            );
          }),
        ]
      ],
    );
  }

  Widget _buildEducationItem(String degree, String university, String years,
      {String? description}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    degree,
                    style: GoogleFonts.poppins(
                      fontSize: 7,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    university,
                    style: GoogleFonts.poppins(
                      fontSize: 6,
                      color: Colors.grey.shade700,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              years,
              style: GoogleFonts.poppins(
                fontSize: 6,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        if (description != null && description.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            description,
            style: GoogleFonts.inter(
              fontSize: 6,
              color: Colors.grey.shade800,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCertificationItem(
      String title, String description, String dateRange) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 7,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              dateRange,
              style: GoogleFonts.poppins(
                fontSize: 7,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        if (description.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            description,
            style: GoogleFonts.inter(
              fontSize: 6,
              color: Colors.grey.shade800,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSkillsList(List<Skill> skills) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: skills.map((skill) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '• ',
              style: GoogleFonts.inter(
                fontSize: 6,
                fontWeight: FontWeight.bold,
              ),
            ),
            Expanded(
              child: Text(
                skill.name,
                style: GoogleFonts.poppins(
                  fontSize: 6,
                  color: Colors.grey.shade800,
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildLanguagesList(List<Language> languages) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: languages.map((language) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '• ',
              style: GoogleFonts.inter(
                fontSize: 6,
                fontWeight: FontWeight.bold,
              ),
            ),
            Expanded(
              child: Text(
                language.name,
                style: GoogleFonts.poppins(
                  fontSize: 6,
                  color: Colors.grey.shade800,
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}
