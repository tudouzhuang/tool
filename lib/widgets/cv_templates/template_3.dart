import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'dart:io';
import 'package:flutter/rendering.dart';
import 'package:toolkit/widgets/cv_templates/template4.dart';
import 'package:toolkit/widgets/cv_templates/template_1.dart';
import 'package:toolkit/widgets/cv_templates/template_2.dart';
import 'dart:ui' as ui;
import 'dart:math' as math;
import '../../models/user_model_1.dart';
import '../../models/website_model.dart';
import '../../provider/certification_provider.dart';
import '../../provider/education_provider.dart';
import '../../provider/language_provider.dart';
import '../../provider/skills_provider.dart';
import '../../provider/template_provider.dart';
import '../../provider/user_provider.dart';
import '../../provider/work_experience_provider.dart';
import '../../screens/cv_maker_screens/base_cv_template_screen.dart';
import '../../utils/app_colors.dart';
import '../buttons/template_action_btn.dart';
import '../cv_widgets/template_selection_dialog.dart';

class Template3 extends StatefulWidget {
  final List<Website> websites;

  const Template3({super.key, this.websites = const []});

  @override
  State<Template3> createState() => _Template3State();
}

class _Template3State extends State<Template3> {
  final int _currentPage = 1;
  int _totalPages = 1;
  final List<List<Widget>> _rightColumnContent = [];
  final List<List<Widget>> _leftColumnContent = [];
  final double _pageContentHeight = 482.0; // Adjusted for Template3 layout
  List<GlobalKey> _pageKeys = [];
  bool _contentMeasured = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_contentMeasured) {
      setState(() {
        _contentMeasured = false;
      });
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _distributeContent();
    });
  }

  @override
  void initState() {
    super.initState();
    if (widget.websites.isNotEmpty) {
      Provider.of<UserProvider>(context, listen: false)
          .updateWebsites(widget.websites);
    }
  }

  double _estimateTextHeight(String text, TextStyle style, double width) {
    final double charHeight = style.fontSize! * 1.2;
    final double charWidth = style.fontSize! * 0.6;
    final int charsPerLine = (width / charWidth).floor();
    final int lines = (text.length / charsPerLine).ceil();
    return lines * charHeight;
  }

  void _distributeContent() {
    final userData = Provider.of<UserProvider>(context, listen: false).userData;
    final workExperienceProvider =
    Provider.of<WorkExperienceProvider>(context, listen: false);
    final workExperienceItems = workExperienceProvider.workExperienceItems;
    final educationProvider =
    Provider.of<EducationProvider>(context, listen: false);
    final educationItems = educationProvider.educationItems;
    final certificationProvider =
    Provider.of<CertificationProvider>(context, listen: false);
    final certificationItems = certificationProvider.certificationItems;
    final skillItems =
        Provider.of<SkillsProvider>(context, listen: false).skillItems;
    final languageItems =
        Provider.of<LanguageProvider>(context, listen: false).languages;

    _rightColumnContent.clear();
    _leftColumnContent.clear();

    double maxPageHeight = _pageContentHeight - 40;

    // Distribute left column content (Contact, Education, Skills, Languages)
    List<Widget> currentLeftColumnWidgets = [];
    double currentLeftColumnHeight = 0;

    void addWidgetToLeftColumn(Widget widget, double estimatedHeight) {
      // If adding this widget would exceed page height and we already have content,
      // create a new page
      if (currentLeftColumnHeight + estimatedHeight > maxPageHeight &&
          currentLeftColumnWidgets.isNotEmpty) {
        _leftColumnContent.add([...currentLeftColumnWidgets]);
        currentLeftColumnWidgets = [];
        currentLeftColumnHeight = 0;
      }

      currentLeftColumnWidgets.add(widget);
      currentLeftColumnHeight += estimatedHeight;
    }

    // Contact Section
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final List<Website> websites = userProvider.websites;
    bool hasPhone =
        userData.phoneNumber != null && userData.phoneNumber!.isNotEmpty;
    bool hasEmail = userData.email != null && userData.email!.isNotEmpty;
    bool hasWebsites = websites.isNotEmpty;

    if (hasPhone || hasEmail || hasWebsites) {
      final contactSection = _buildContactSection(userData);
      addWidgetToLeftColumn(
          contactSection, 50 + (websites.length * 10)); // Estimated height
      addWidgetToLeftColumn(const SizedBox(height: 6), 16);
    }

    // Education Section
    if (educationItems.isNotEmpty) {
      final educationSection = _buildEducationSection();
      // Estimate height more accurately based on content
      double estimatedHeight = 30; // Base height for section header
      for (var item in educationItems) {
        // Basic height for degree, institute, date
        double itemHeight = 30;

        // Add height for description if present
        if (item.description.isNotEmpty) {
          // Roughly estimate 5 points per line of text
          itemHeight += (item.description.length / 30) * 5;
        }

        estimatedHeight += itemHeight;
      }

      // Check if adding this section would exceed page height
      if (currentLeftColumnHeight + estimatedHeight > maxPageHeight &&
          currentLeftColumnWidgets.isNotEmpty) {
        // Start a new page
        _leftColumnContent.add([...currentLeftColumnWidgets]);
        currentLeftColumnWidgets = [];
        currentLeftColumnHeight = 0;

        // Add education section to new page
        addWidgetToLeftColumn(educationSection, estimatedHeight);
      } else {
        // Add to current page
        addWidgetToLeftColumn(educationSection, estimatedHeight);
      }

      addWidgetToLeftColumn(const SizedBox(height: 6), 16);
    }

    // Skills Section
    if (skillItems.isNotEmpty) {
      final skillsSection = _buildSkillsSection();
      double estimatedHeight = 30 + (skillItems.length * 8);

      // Check if adding this section would exceed page height
      if (currentLeftColumnHeight + estimatedHeight > maxPageHeight &&
          currentLeftColumnWidgets.isNotEmpty) {
        // Start a new page
        _leftColumnContent.add([...currentLeftColumnWidgets]);
        currentLeftColumnWidgets = [];
        currentLeftColumnHeight = 0;

        // Add skills section to new page
        addWidgetToLeftColumn(skillsSection, estimatedHeight);
      } else {
        // Add to current page
        addWidgetToLeftColumn(skillsSection, estimatedHeight);

      }

      addWidgetToLeftColumn(const SizedBox(height: 6), 16);
    }

    // Languages Section
    if (languageItems.isNotEmpty) {
      final languagesSection = _buildLanguagesSection();
      double estimatedHeight = 30 + (languageItems.length * 8);

      // Check if adding this section would exceed page height
      if (currentLeftColumnHeight + estimatedHeight > maxPageHeight &&
          currentLeftColumnWidgets.isNotEmpty) {
        // Start a new page
        _leftColumnContent.add([...currentLeftColumnWidgets]);
        currentLeftColumnWidgets = [];
        currentLeftColumnHeight = 0;

        // Add languages section to new page
        addWidgetToLeftColumn(languagesSection, estimatedHeight);
      } else {
        // Add to current page
        addWidgetToLeftColumn(languagesSection, estimatedHeight);
      }
    }

    // Add remaining left column widgets
    if (currentLeftColumnWidgets.isNotEmpty) {
      _leftColumnContent.add([...currentLeftColumnWidgets]);
    }

    // Make sure we have at least one page in left column
    if (_leftColumnContent.isEmpty) {
      _leftColumnContent.add([Container()]);
    }

    // Distribute right column content (Profile, Experience, Certifications)
    List<Widget> currentRightColumnWidgets = [];
    double currentRightColumnHeight = 0;

    void addWidgetToRightColumn(Widget widget, double estimatedHeight) {
      if (currentRightColumnHeight + estimatedHeight > maxPageHeight &&
          currentRightColumnWidgets.isNotEmpty) {
        _rightColumnContent.add([...currentRightColumnWidgets]);
        currentRightColumnWidgets = [];
        currentRightColumnHeight = 0;
      }

      currentRightColumnWidgets.add(widget);
      currentRightColumnHeight += estimatedHeight;
    }

    // Profile section
    if (userData.careerObjective != null &&
        userData.careerObjective!.isNotEmpty) {
      final profileSection = _buildProfileSection(userData);
      addWidgetToRightColumn(profileSection, 30);
      addWidgetToRightColumn(const SizedBox(height: 8), 6);
      addWidgetToRightColumn(_buildDivider(), 2);
      addWidgetToRightColumn(const SizedBox(height: 4), 6);
    }

    // Work Experience section
    if (workExperienceItems.isNotEmpty) {
      final sectionTitle = _buildSectionTitle('WORK EXPERIENCE');
      addWidgetToRightColumn(sectionTitle, 20);
      addWidgetToRightColumn(const SizedBox(height: 2), 4);

      for (int i = 0; i < workExperienceItems.length; i++) {
        final item = workExperienceItems[i];
        String dateRange = item.isCurrent
            ? "${item.startDate} - Present"
            : "${item.startDate} - ${item.endDate}";

        double itemHeight = 40;
        if (item.description.isNotEmpty) {
          itemHeight += 15 + (item.description.length / 50) * 5;
        }
        if (item.projects.isNotEmpty) {
          itemHeight += item.projects.length * 10;
        }

        final experienceItem = _buildExperienceItem(
          item.position,
          item.company,
          item.description,
          dateRange,
          bulletPoints: item.projects.isNotEmpty ? item.projects : null,
          projectUrls: item.projectUrls.isNotEmpty ? item.projectUrls : null,
        );

        addWidgetToRightColumn(experienceItem, itemHeight);

        if (i < workExperienceItems.length - 1) {
          addWidgetToRightColumn(const SizedBox(height: 2), 4);
        }
      }
      addWidgetToRightColumn(const SizedBox(height: 4), 6);
      addWidgetToRightColumn(_buildDivider(), 2);
      addWidgetToRightColumn(const SizedBox(height: 4), 6);
    }

    // Certifications section
    if (certificationItems.isNotEmpty) {
      final sectionTitle = _buildSectionTitle('CERTIFICATIONS');
      addWidgetToRightColumn(sectionTitle, 20);
      addWidgetToRightColumn(const SizedBox(height: 2), 4);

      for (int i = 0; i < certificationItems.length; i++) {
        final item = certificationItems[i];
        String dateRange =
        item.isCompleted ? "${item.startDate} " : "${item.startDate} ";

        double itemHeight = 30;
        if (item.description.isNotEmpty) {
          itemHeight += 10 + (item.description.length / 50) * 5;
        }

        final certItem = _buildCertificationItem(
          item.certificationName,
          item.description,
          dateRange,
        );

        addWidgetToRightColumn(certItem, itemHeight);

        if (i < certificationItems.length - 1) {
          addWidgetToRightColumn(const SizedBox(height: 2), 4);
        }
      }
    }

    // Add remaining right column widgets
    if (currentRightColumnWidgets.isNotEmpty) {
      _rightColumnContent.add([...currentRightColumnWidgets]);
    }

    // Make sure we have at least one page in right column
    if (_rightColumnContent.isEmpty) {
      _rightColumnContent.add([Container()]);
    }

    // Calculate total pages needed
    _totalPages =
        math.max(_leftColumnContent.length, _rightColumnContent.length);

    // Ensure both columns have the same number of pages
    while (_leftColumnContent.length < _totalPages) {
      _leftColumnContent.add([Container()]);
    }

    while (_rightColumnContent.length < _totalPages) {
      _rightColumnContent.add([Container()]);
    }

    _pageKeys = List.generate(_totalPages, (index) => GlobalKey());

    setState(() {
      _contentMeasured = true;
    });
  }

  Widget _buildDivider() {
    return Container(
      height: 1,
      color: AppColors.t3DividerColor,
    );
  }

  Widget _buildBlackDivider() {
    return Container(
      height: 0.4,
      color: AppColors.black,
    );
  }

  Future<void> _exportToPdf() async {
    try {
      final userData =
          Provider.of<UserProvider>(context, listen: false).userData;
      final fileName =
          '${userData.fullName?.replaceAll(' ', '_') ?? 'cv'}_resume.pdf';

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Dialog(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 10),
                  Text('Generating PDF...', style: GoogleFonts.inter()),
                ],
              ),
            ),
          );
        },
      );

      final pdf = pw.Document();
      for (int i = 0; i < _pageKeys.length; i++) {
        final imageBytes = await _capturePageAsImage(_pageKeys[i]);
        if (imageBytes != null) {
          final image = pw.MemoryImage(imageBytes);
          pdf.addPage(
            pw.Page(
              pageFormat: PdfPageFormat.a4,
              build: (pw.Context context) {
                return pw.Center(
                  child: pw.Image(image),
                );
              },
            ),
          );
        }
      }

      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());

      Provider.of<UserProvider>(context, listen: false).clearUserData();
      Navigator.pop(context);

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('PDF Created',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
            content: Text('Your CV has been exported as a PDF.',
                style: GoogleFonts.inter()),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: Text('Close', style: GoogleFonts.inter()),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  OpenFile.open(filePath);
                  Navigator.pop(context);
                },
                child: Text('Open PDF',
                    style: GoogleFonts.inter(color: AppColors.primary)),
              ),
            ],
          );
        },
      );
    } catch (e) {
      if (Navigator.canPop(context)) Navigator.pop(context);
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Error',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
            content: Text('Failed to export PDF: ${e.toString()}',
                style: GoogleFonts.inter()),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('OK', style: GoogleFonts.inter()),
              ),
            ],
          );
        },
      );
    }
  }

  Future<Uint8List?> _capturePageAsImage(GlobalKey key) async {
    try {
      RenderRepaintBoundary? boundary =
          key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;

      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      print('Error capturing page as image: $e');
      return null;
    }
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
        templateScreen = Template3(websites: websites);
    }

    // Replace the current route with the new template
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => templateScreen,
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return BaseCVTemplateScreen(
      cvContent: !_contentMeasured
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          for (int i = 0; i < _totalPages; i++) ...[
            RepaintBoundary(
              key: _pageKeys[i],
              child: _buildPage(i + 1),
            ),
            if (i < _totalPages - 1) const SizedBox(height: 30),
          ]
        ],
      ),
      pageKeys: _pageKeys,
      totalPages: _totalPages,
    );
  }


  Widget _buildPage(int pageIndex) {
    // Use 0-based index for array access
    int arrayIndex = pageIndex - 1;

    // Get content for this page
    List<Widget> leftContent = arrayIndex < _leftColumnContent.length
        ? _leftColumnContent[arrayIndex]
        : [];
    List<Widget> rightContent = arrayIndex < _rightColumnContent.length
        ? _rightColumnContent[arrayIndex]
        : [];

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
      child: Column(
        children: [
          // Header section is always on first page
          if (pageIndex == 1)
            _buildHeader(
                Provider.of<UserProvider>(context, listen: false).userData),

          // Main content with left and right columns
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Left column - Contact, Education, Skills, Languages
                Container(
                  width: 130,
                  color: AppColors.t3LeftColumn,
                  padding: const EdgeInsets.all(10),
                  child: SingleChildScrollView(
                    physics: const NeverScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: leftContent,
                    ),
                  ),
                ),

                // Right column - Profile, Experience, Certifications
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    child: SingleChildScrollView(
                      physics: const NeverScrollableScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: rightContent,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(UserModel userData) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: const BoxDecoration(
        color: AppColors.t3Primary,
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(50),
          bottomRight: Radius.circular(50),
        ),
      ),
      child: Row(
        children: [
          // Name and title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (userData.fullName != null && userData.fullName!.isNotEmpty)
                  Text(
                    userData.fullName!.split(' ').first.toUpperCase(),
                    style: GoogleFonts.inriaSerif(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.white,
                    ),
                  ),
                if (userData.fullName != null &&
                    userData.fullName!.split(' ').length > 1)
                  Text(
                    userData.fullName!.split(' ').last.toUpperCase(),
                    style: GoogleFonts.inriaSerif(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.white,
                    ),
                  ),
                const SizedBox(height: 2),
                if (userData.designation != null &&
                    userData.designation!.isNotEmpty)
                  Text(
                    userData.designation!,
                    style: GoogleFonts.inriaSerif(
                      fontSize: 10,
                      color: AppColors.white,
                    ),
                  ),
              ],
            ),
          ),

          // Profile picture
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.fieldHintColor,
              border: Border.all(
                color: AppColors.white,
                width: 3,
              ),
            ),
            child: userData.profileImagePath != null
                ? ClipOval(
                    child: Image.file(
                      File(userData.profileImagePath!),
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                    ),
                  )
                : const Icon(
                    Icons.person,
                    size: 30,
                    color: AppColors.dividerColor,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactSection(UserModel userData) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final List<Website> websites = userProvider.websites;

    bool hasPhone =
        userData.phoneNumber != null && userData.phoneNumber!.isNotEmpty;
    bool hasEmail = userData.email != null && userData.email!.isNotEmpty;
    bool hasWebsites = websites.isNotEmpty;

    // Only show section if there's at least one contact info
    if (!hasPhone && !hasEmail && !hasWebsites) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CONTACT',
          style: GoogleFonts.poppins(
            fontSize: 8,
            fontWeight: FontWeight.w600,
            color: AppColors.t3Primary,
          ),
        ),
        const SizedBox(height: 4),
        if (hasPhone)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SvgPicture.asset(
                'assets/icons/contact_icon.svg',
                width: 6,
                height: 6,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  userData.phoneNumber!,
                  style: GoogleFonts.poppins(
                    fontSize: 6,
                    color: AppColors.black,
                  ),
                  softWrap: true,
                  overflow: TextOverflow.visible,
                ),
              ),
            ],
          ),
        if (hasEmail) ...[
          const SizedBox(height: 2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SvgPicture.asset(
                'assets/icons/email_icon.svg',
                width: 6,
                height: 6,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  userData.email!,
                  style: GoogleFonts.poppins(
                    fontSize: 6,
                    color: AppColors.black,
                  ),
                  softWrap: true,
                  overflow: TextOverflow.visible,
                ),
              ),
            ],
          ),
        ],
        if (hasWebsites) ...[
          for (Website website in websites) ...[
            const SizedBox(height: 2),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SvgPicture.asset(
                  'assets/icons/url_icon.svg',
                  width: 6,
                  height: 6,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    website.url,
                    style: GoogleFonts.poppins(
                      fontSize: 6,
                      color: AppColors.black,
                    ),
                    softWrap: true,
                    overflow: TextOverflow.visible,
                  ),
                ),
              ],
            ),
          ]
        ],
        const SizedBox(height: 4),
        _buildBlackDivider(),
      ],
    );
  }
  Widget _buildEducationSection() {
    final educationItems =
        Provider.of<EducationProvider>(context, listen: false).educationItems;

    // Only show section if there are education items
    if (educationItems.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'EDUCATION',
          style: GoogleFonts.poppins(
            fontSize: 8,
            fontWeight: FontWeight.w600,
            color: AppColors.t3Primary,
          ),
        ),
        const SizedBox(height: 4),
        ...educationItems.map((item) {
          String dateRange = item.isCompleted
              ? "${item.startDate} - Present"
              : "${item.startDate} - ${item.endDate}";
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.degree ?? '',
                style: GoogleFonts.poppins(
                    fontSize: 8,
                    fontWeight: FontWeight.w400,
                    color: AppColors.t3SubHeading),
              ),
              Text(
                item.institute ?? '',
                style: GoogleFonts.poppins(
                  fontSize: 6,
                  color: AppColors.black,
                  fontStyle: FontStyle.italic,
                ),
              ),
              Text(
                dateRange,
                style: GoogleFonts.poppins(
                  fontSize: 6,
                  color: AppColors.black,
                ),
              ),
              if (item.description.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  item.description,
                  style: GoogleFonts.poppins(
                    fontSize: 6,
                    color: AppColors.black,
                  ),
                ),
              ],
              if (item != educationItems.last) const SizedBox(height: 4),
            ],
          );
        }),
        const SizedBox(height: 4),
        _buildBlackDivider(),
      ],
    );
  }

  Widget _buildSkillsSection() {
    final skillItems =
        Provider.of<SkillsProvider>(context, listen: false).skillItems;

    // Only show section if there are skills
    if (skillItems.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SKILLS & INTERESTS',
          style: GoogleFonts.poppins(
            fontSize: 8,
            fontWeight: FontWeight.w600,
            color: AppColors.t3Primary,
          ),
        ),
        const SizedBox(height: 4),
        ...skillItems.map((skill) => _buildSkillItem(skill.name)),
        const SizedBox(height: 6),
        _buildBlackDivider(),
      ],
    );
  }

  Widget _buildSkillItem(String skill) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          Text(
            '• ',
            style: GoogleFonts.poppins(
              fontSize: 6,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            skill,
            style: GoogleFonts.poppins(
              fontSize: 6,
              color: AppColors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguagesSection() {
    final languageItems =
        Provider.of<LanguageProvider>(context, listen: false).languages;

    // Only show section if there are languages
    if (languageItems.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'LANGUAGES',
          style: GoogleFonts.poppins(
            fontSize: 8,
            fontWeight: FontWeight.w600,
            color: AppColors.t3Primary,
          ),
        ),
        const SizedBox(height: 4),
        ...languageItems
            .map((language) => _buildSkillItem(language.name))
            ,
      ],
    );
  }

  Widget _buildProfileSection(UserModel userData) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PROFILE',
          style: GoogleFonts.poppins(
            fontSize: 8,
            fontWeight: FontWeight.w600,
            color: AppColors.t3Primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          userData.careerObjective ?? '',
          style: GoogleFonts.inter(
            fontSize: 6,
            color: AppColors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 8,
            fontWeight: FontWeight.w600,
            color: AppColors.t3Primary,
          ),
        ),
        // Removed the divider that was here
      ],
    );
  }

  Widget _buildExperienceItem(
      String title, String company, String description, String dateRange,
      {List<String>? bulletPoints, List<String>? projectUrls}) {
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
                      fontWeight: FontWeight.w400,
                      color: AppColors.t3Primary)),
            ),
            Text(
              dateRange,
              style: GoogleFonts.poppins(
                fontSize: 6,
                color: AppColors.black,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          company,
          style: GoogleFonts.poppins(
            fontSize: 7,
            color: AppColors.t3SubHeading,
          ),
        ),
        if (description.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            description,
            style: GoogleFonts.inter(fontSize: 6, color: AppColors.black),
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
                          color: AppColors.black,
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
                    color: AppColors.t3SubHeading),
              ),
            ),
            Text(
              dateRange,
              style: GoogleFonts.poppins(
                fontSize: 6,
                color: AppColors.black,
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
              color: AppColors.black,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTemplateButtons() {
    return TemplateActionButtons(
      onChangeTemplate: () {
        _showTemplateSelectionDialog(context);
      },
      onExport: () {
        _exportToPdf();
      },
    );
  }
}
