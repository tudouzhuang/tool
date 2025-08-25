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
import 'package:toolkit/widgets/cv_templates/template_1.dart';
import 'package:toolkit/widgets/cv_templates/template_2.dart';
import 'package:toolkit/widgets/cv_templates/template_3.dart';
import 'dart:ui' as ui;
import 'dart:math' as math;
import '../../models/language_model.dart';
import '../../models/skills_model.dart';
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

class Template4 extends StatefulWidget {
  final List<Website> websites;

  const Template4({super.key, this.websites = const []});

  @override
  State<Template4> createState() => _Template4State();
}

class _Template4State extends State<Template4> {
  int _totalPages = 1;
  final List<List<Widget>> _mainColumnContent = [];
  final List<List<Widget>> _sideColumnContent = [];
  final double _pageContentHeight = 482.0;
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.websites.isNotEmpty) {
        Provider.of<UserProvider>(context, listen: false)
            .updateWebsites(widget.websites);
      }
    });
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
        templateScreen = Template4(websites: websites);
    }

    // Replace the current route with the new template
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => templateScreen,
      ),
    );
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

    // Clear previous content
    _mainColumnContent.clear();
    _sideColumnContent.clear();

    double maxPageHeight = _pageContentHeight - 40;

    // Distribute main column content (Profile, Experience, Certifications)
    List<Widget> currentMainColumnWidgets = [];
    double currentMainColumnHeight = 0;

    void addWidgetToMainColumn(Widget widget, double estimatedHeight) {
      if (currentMainColumnHeight + estimatedHeight > maxPageHeight &&
          currentMainColumnWidgets.isNotEmpty) {
        _mainColumnContent.add([...currentMainColumnWidgets]);
        currentMainColumnWidgets = [];
        currentMainColumnHeight = 0;
      }

      currentMainColumnWidgets.add(widget);
      currentMainColumnHeight += estimatedHeight;
    }

    // Profile section
    if (userData.careerObjective != null &&
        userData.careerObjective!.isNotEmpty) {
      final profileSection = _buildProfileSection(userData);
      addWidgetToMainColumn(profileSection, 30);
      addWidgetToMainColumn(const SizedBox(height: 0), 6);
      addWidgetToMainColumn(_buildGreyDivider(), 2);
      addWidgetToMainColumn(const SizedBox(height: 0), 6);
    }

    // Work Experience section
    if (workExperienceItems.isNotEmpty) {
      final sectionTitle = _buildSectionTitle('WORK EXPERIENCE');
      addWidgetToMainColumn(sectionTitle, 20);
      addWidgetToMainColumn(const SizedBox(height: 2), 4);

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
          if (item.projectUrls.isNotEmpty) {
            itemHeight +=
                item.projectUrls.length * 5; // Additional space for URLs
          }
        }

        final experienceItem = _buildExperienceItem(
          item.position,
          item.company,
          item.description,
          dateRange,
          bulletPoints: item.projects.isNotEmpty ? item.projects : null,
          projectUrls: item.projectUrls.isNotEmpty ? item.projectUrls : null,
        );

        addWidgetToMainColumn(experienceItem, itemHeight);

        if (i < workExperienceItems.length - 1) {
          addWidgetToMainColumn(const SizedBox(height: 2), 4);
        }
      }
      addWidgetToMainColumn(const SizedBox(height: 4), 6);
      addWidgetToMainColumn(_buildGreyDivider(), 2);
      addWidgetToMainColumn(const SizedBox(height: 4), 6);
    }

    // Certifications section
    if (certificationItems.isNotEmpty) {
      final sectionTitle = _buildSectionTitle('CERTIFICATIONS');
      addWidgetToMainColumn(sectionTitle, 60);
      addWidgetToMainColumn(const SizedBox(height: 2), 4);

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

        addWidgetToMainColumn(certItem, itemHeight);

        if (i < certificationItems.length - 1) {
          addWidgetToMainColumn(const SizedBox(height: 2), 4);
        }
      }
    }

    // Add remaining main column widgets
    if (currentMainColumnWidgets.isNotEmpty) {
      _mainColumnContent.add([...currentMainColumnWidgets]);
    }

    // Make sure we have at least one page in main column
    if (_mainColumnContent.isEmpty) {
      _mainColumnContent.add([Container()]);
    }

    // Distribute side column content (Contact, Education, Skills, Languages)
    List<Widget> currentSideColumnWidgets = [];
    double currentSideColumnHeight = 0;

    void addWidgetToSideColumn(Widget widget, double estimatedHeight) {
      if (currentSideColumnHeight + estimatedHeight > maxPageHeight &&
          currentSideColumnWidgets.isNotEmpty) {
        _sideColumnContent.add([...currentSideColumnWidgets]);
        currentSideColumnWidgets = [];
        currentSideColumnHeight = 0;
      }

      currentSideColumnWidgets.add(widget);
      currentSideColumnHeight += estimatedHeight;
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
      addWidgetToSideColumn(
          contactSection, 50 + (websites.length * 10)); // Estimated height
      addWidgetToSideColumn(const SizedBox(height: 6), 16);
      addWidgetToSideColumn(_buildSidebarDivider(), 1);
      addWidgetToSideColumn(const SizedBox(height: 4), 16);
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
      if (currentSideColumnHeight + estimatedHeight > maxPageHeight &&
          currentSideColumnWidgets.isNotEmpty) {
        // Start a new page
        _sideColumnContent.add([...currentSideColumnWidgets]);
        currentSideColumnWidgets = [];
        currentSideColumnHeight = 0;

        // Add education section to new page
        addWidgetToSideColumn(educationSection, estimatedHeight);
      } else {
        // Add to current page
        addWidgetToSideColumn(educationSection, estimatedHeight);
      }

      addWidgetToSideColumn(const SizedBox(height: 6), 16);
      addWidgetToSideColumn(_buildSidebarDivider(), 1);
      addWidgetToSideColumn(const SizedBox(height: 4), 16);
    }

    // Skills Section
    if (skillItems.isNotEmpty) {
      final skillsSection = _buildSkillsSection(skillItems);
      double estimatedHeight = 30 + (skillItems.length * 8);

      // Check if adding this section would exceed page height
      if (currentSideColumnHeight + estimatedHeight > maxPageHeight &&
          currentSideColumnWidgets.isNotEmpty) {
        // Start a new page
        _sideColumnContent.add([...currentSideColumnWidgets]);
        currentSideColumnWidgets = [];
        currentSideColumnHeight = 0;

        // Add skills section to new page
        addWidgetToSideColumn(skillsSection, estimatedHeight);
      } else {
        // Add to current page
        addWidgetToSideColumn(skillsSection, estimatedHeight);
      }

      addWidgetToSideColumn(const SizedBox(height: 6), 16);
      addWidgetToSideColumn(_buildSidebarDivider(), 1);
      addWidgetToSideColumn(const SizedBox(height: 4), 16);
    }

    // Languages Section
    if (languageItems.isNotEmpty) {
      final languagesSection = _buildLanguagesSection(languageItems);
      double estimatedHeight = 30 + (languageItems.length * 8);

      // Check if adding this section would exceed page height
      if (currentSideColumnHeight + estimatedHeight > maxPageHeight &&
          currentSideColumnWidgets.isNotEmpty) {
        // Start a new page
        _sideColumnContent.add([...currentSideColumnWidgets]);
        currentSideColumnWidgets = [];
        currentSideColumnHeight = 0;

        // Add languages section to new page
        addWidgetToSideColumn(languagesSection, estimatedHeight);
      } else {
        // Add to current page
        addWidgetToSideColumn(languagesSection, estimatedHeight);
      }
    }

    // Add remaining side column widgets
    if (currentSideColumnWidgets.isNotEmpty) {
      _sideColumnContent.add([...currentSideColumnWidgets]);
    }

    // Make sure we have at least one page in side column
    if (_sideColumnContent.isEmpty) {
      _sideColumnContent.add([Container()]);
    }

    // Calculate total pages needed
    _totalPages =
        math.max(_mainColumnContent.length, _sideColumnContent.length);

    // Ensure both columns have the same number of pages
    while (_mainColumnContent.length < _totalPages) {
      _mainColumnContent.add([Container()]);
    }
    while (_sideColumnContent.length < _totalPages) {
      _sideColumnContent.add([Container()]);
    }

    _pageKeys = List.generate(_totalPages, (index) => GlobalKey());

    setState(() {
      _contentMeasured = true;
    });
  }

  Widget _buildGreyDivider() {
    return Container(
      height: 0.5,
      color: Colors.grey.shade300,
      margin: const EdgeInsets.symmetric(vertical: 8),
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
                  const SizedBox(height: 20),
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
    // Get content for this page (0-based index)
    List<Widget> mainContent = pageIndex <= _mainColumnContent.length
        ? _mainColumnContent[pageIndex - 1]
        : [];
    List<Widget> sideContent = pageIndex <= _sideColumnContent.length
        ? _sideColumnContent[pageIndex - 1]
        : [];

    final userData = Provider.of<UserProvider>(context, listen: false).userData;

    return Container(
      constraints: const BoxConstraints(
          maxWidth: 340, minWidth: 340, minHeight: 482, maxHeight: 482),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        children: [
          // Header section is always on first page
          if (pageIndex == 1) _buildHeader(userData),

          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Main column (left)
                Expanded(
                  flex: 3,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    child: SingleChildScrollView(
                      physics: const NeverScrollableScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: mainContent,
                      ),
                    ),
                  ),
                ),

                // Side column (right)
                Container(
                  width: 130,
                  color: const Color(0xFFE0DCD7),
                  padding: const EdgeInsets.all(10),
                  child: SingleChildScrollView(
                    physics: const NeverScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: sideContent,
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

  Widget _buildSidebarDivider() {
    return Container(
      height: 0.5,
      color: const Color(0xFFA81919),
    );
  }

  Widget _buildHeader(UserModel userData) {
    return Stack(
      children: [
        // Make the SVG fill the entire width
        Positioned.fill(
          child: SvgPicture.asset(
            'assets/images/templates/template4_bg.svg',
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          child: Row(
            children: [
              // Profile picture
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey.shade300,
                  border: Border.all(
                    color: Colors.white,
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
                    : Icon(
                        Icons.person,
                        size: 30,
                        color: Colors.grey.shade400,
                      ),
              ),
              const SizedBox(width: 15),

              // Name and title
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (userData.fullName != null &&
                        userData.fullName!.isNotEmpty)
                      Text(
                        userData.fullName!.toUpperCase(),
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    if (userData.designation != null &&
                        userData.designation!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        userData.designation!,
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
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
            fontSize: 7,
            fontWeight: FontWeight.w600,
            color: const Color(0xFFA81919),
          ),
        ),
        const SizedBox(height: 4),
        if (hasPhone)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.phone,
                size: 6,
                color: Color(0xFFA81919),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  userData.phoneNumber!,
                  style: GoogleFonts.poppins(
                    fontSize: 6,
                    color: Colors.black,
                  ),
                  softWrap: true,
                  overflow: TextOverflow.visible,
                ),
              ),
            ],
          ),
        if (hasEmail) ...[
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.email,
                size: 6,
                color: Color(0xFFA81919),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  userData.email!,
                  style: GoogleFonts.poppins(
                    fontSize: 6,
                    color: Colors.black,
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
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.link,
                  size: 6,
                  color: Color(0xFFA81919),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    website.url,
                    style: GoogleFonts.poppins(
                      fontSize: 6,
                      color: Colors.black,
                    ),
                    softWrap: true,
                    overflow: TextOverflow.visible,
                  ),
                ),
              ],
            ),
          ]
        ],
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
            fontSize: 7,
            fontWeight: FontWeight.w600,
            color: const Color(0xFFA81919),
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
      ],
    );
  }

  Widget _buildSkillsSection(List<Skill> skills) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SKILLS',
          style: GoogleFonts.poppins(
            fontSize: 7,
            fontWeight: FontWeight.w600,
            color: const Color(0xFFA81919),
          ),
        ),
        const SizedBox(height: 4),
        ...skills.map((skill) => _buildSkillItem(skill.name)),
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
              color: const Color(0xFFA81919),
            ),
          ),
          Expanded(
            child: Text(
              skill,
              style: GoogleFonts.poppins(
                fontSize: 6,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguagesSection(List<Language> languages) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'LANGUAGES',
          style: GoogleFonts.poppins(
            fontSize: 7,
            fontWeight: FontWeight.w600,
            color: const Color(0xFFA81919),
          ),
        ),
        const SizedBox(height: 4),
        ...languages.map((language) => _buildSkillItem(language.name)),
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
            color: const Color(0xFFA81919),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          userData.careerObjective ?? '',
          style: GoogleFonts.inter(
            fontSize: 6,
            color: Colors.black,
          ),
        ),
        // Add grey divider after profile section
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
            fontSize: 7,
            fontWeight: FontWeight.w600,
            color: const Color(0xFFA81919),
          ),
        ),
      ],
    );
  }

  Widget _buildExperienceItem(
      String title, String company, String description, String dateRange,
      {List<String>? bulletPoints, List<String>? projectUrls}) {
    // Parse the dateRange to handle ongoing positions
    final dates = dateRange.split(' - ');
    final startDate = dates.isNotEmpty ? dates[0] : '';
    final endDate = dates.length > 1 ? dates[1] : 'Present';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 6,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFFA81919),
                  ),
                ),
              ]),
            ),
            Text(
              '$startDate - $endDate',
              style: GoogleFonts.poppins(
                fontSize: 6,
                color: Colors.black54,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          company,
          style: GoogleFonts.poppins(
            fontSize: 6,
            color: Colors.black87,
          ),
        ),
        if (description.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            description,
            style: GoogleFonts.inter(
              fontSize: 6,
              color: Colors.black,
            ),
          ),
        ],
        if (bulletPoints != null && bulletPoints.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            'Projects:',
            style: GoogleFonts.poppins(
              fontSize: 6,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
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
                          fontWeight: FontWeight.bold,
                          fontSize: 6,
                          color: const Color(0xFFA81919),
                        )),
                    Expanded(
                      child: Text(
                        point,
                        style: GoogleFonts.inter(
                          fontSize: 6,
                          color: Colors.black,
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
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFFA81919),
                ),
              ),
            ),
            Text(
              dateRange,
              style: GoogleFonts.poppins(
                fontSize: 6,
                color: Colors.black,
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
              color: Colors.black,
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
