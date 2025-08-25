import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'dart:io';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:provider/provider.dart';
import 'package:toolkit/models/skills_model.dart';
import 'package:toolkit/widgets/cv_templates/template4.dart';
import 'package:toolkit/widgets/cv_templates/template_1.dart';
import 'package:toolkit/widgets/cv_templates/template_3.dart';
import 'dart:math' as math;

import '../../models/education_item_model.dart';
import '../../models/language_model.dart';
import '../../models/user_model_1.dart';
import '../../models/website_model.dart';
import '../../provider/education_provider.dart';
import '../../provider/language_provider.dart';
import '../../provider/skills_provider.dart';
import '../../provider/template_provider.dart';
import '../../provider/user_provider.dart';
import '../../provider/work_experience_provider.dart';
import '../../provider/certification_provider.dart';
import '../../screens/cv_maker_screens/base_cv_template_screen.dart';
import '../../utils/app_colors.dart';
import '../buttons/template_action_btn.dart';
import '../cv_widgets/template_selection_dialog.dart';

class Template2 extends StatefulWidget {
  final List<Website> websites;

  const Template2({super.key, this.websites = const []});

  @override
  State<Template2> createState() => _Template2State();
}

class _Template2State extends State<Template2> {
  final int _currentPage = 1;
  int _totalPages = 1;
  final List<List<Widget>> _rightColumnContent = [];
  final List<List<Widget>> _leftColumnContent = [];
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
    if (widget.websites.isNotEmpty) {
      Provider.of<UserProvider>(context, listen: false)
          .updateWebsites(widget.websites);
    }
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
      addWidgetToLeftColumn(contactSection, 50 + (websites.length * 10));
      addWidgetToLeftColumn(const SizedBox(height: 2), 16);
    }

    // Education Section
    if (educationItems.isNotEmpty) {
      final educationSection = _buildEducationSection(educationItems);
      double estimatedHeight = 30;
      for (var item in educationItems) {
        double itemHeight = 30;
        if (item.description.isNotEmpty) {
          itemHeight += (item.description.length / 30) * 5;
        }
        estimatedHeight += itemHeight;
      }

      if (currentLeftColumnHeight + estimatedHeight > maxPageHeight &&
          currentLeftColumnWidgets.isNotEmpty) {
        _leftColumnContent.add([...currentLeftColumnWidgets]);
        currentLeftColumnWidgets = [];
        currentLeftColumnHeight = 0;
        addWidgetToLeftColumn(educationSection, estimatedHeight);
      } else {
        addWidgetToLeftColumn(educationSection, estimatedHeight);
      }

      addWidgetToLeftColumn(const SizedBox(height: 2), 16);
    }

    // Skills Section
    if (skillItems.isNotEmpty) {
      final skillsSection = _buildSkillsSection(skillItems);
      double estimatedHeight = 30 + (skillItems.length * 8);

      if (currentLeftColumnHeight + estimatedHeight > maxPageHeight &&
          currentLeftColumnWidgets.isNotEmpty) {
        _leftColumnContent.add([...currentLeftColumnWidgets]);
        currentLeftColumnWidgets = [];
        currentLeftColumnHeight = 0;
        addWidgetToLeftColumn(skillsSection, estimatedHeight);
      } else {
        addWidgetToLeftColumn(skillsSection, estimatedHeight);
      }

      addWidgetToLeftColumn(const SizedBox(height: 2), 16);
    }

    // Languages Section
    if (languageItems.isNotEmpty) {
      final languagesSection = _buildLanguagesSection(languageItems);
      double estimatedHeight = 30 + (languageItems.length * 8);

      if (currentLeftColumnHeight + estimatedHeight > maxPageHeight &&
          currentLeftColumnWidgets.isNotEmpty) {
        _leftColumnContent.add([...currentLeftColumnWidgets]);
        currentLeftColumnWidgets = [];
        currentLeftColumnHeight = 0;
        addWidgetToLeftColumn(languagesSection, estimatedHeight);
      } else {
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

    // Distribute right column content (Objective, Experience, Certifications)
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

    // Objective section
    if (userData.careerObjective != null &&
        userData.careerObjective!.isNotEmpty) {
      final objectiveSection = _buildObjectiveSection(userData);
      addWidgetToRightColumn(objectiveSection, 30);
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
          item.position ?? '',
          '${item.company ?? ''} | $dateRange',
          item.description ?? '',
          bulletPoints: item.projects ?? [],
          projectUrls: item.projectUrls ?? [],
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
          item.certificationName ?? '',
          item.organizationName ?? '',
          item.description ?? '',
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
      height: 0.5,
      color: AppColors.Cv2PurpleColor,
    );
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
        templateScreen = Template2(websites: websites);
    }

    // Replace the current route with the new template
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => templateScreen,
      ),
    );
  }

  Future<void> _exportToPdf() async {
    try {
      final userData =
          Provider.of<UserProvider>(context, listen: false).userData;
      final fileName = userData.fullName != null &&
              userData.fullName!.isNotEmpty
          ? '${userData.fullName!.toLowerCase().replaceAll(' ', '_')}_resume.pdf'
          : 'resume.pdf';
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
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

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
                onPressed: () {
                  Navigator.pop(context);
                },
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

  @override
  Widget build(BuildContext context) {
    return BaseCVTemplateScreen(
      cvContent: !_contentMeasured
          ? const Center(child: CircularProgressIndicator())
          : Column(
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
    int arrayIndex = pageIndex - 1;

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
        color: Colors.white,
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
      child: Stack(
        children: [
          // Background gray design element (only on first page)
          if (pageIndex == 1)
            Positioned(
              left: 0,
              top: 0,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: const BorderRadius.only(
                    bottomRight: Radius.circular(100),
                  ),
                ),
              ),
            ),

          // Main content
          Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              children: [
                // Header with profile image and name (only on first page)
                if (pageIndex == 1)
                  _buildHeaderRow(
                      Provider.of<UserProvider>(context, listen: false)
                          .userData),

                // Two column layout for the rest of the content
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left column (narrower)
                      Expanded(
                        flex: 2,
                        child: SingleChildScrollView(
                          physics: const NeverScrollableScrollPhysics(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: leftContent,
                          ),
                        ),
                      ),

                      // Small space between columns
                      const SizedBox(width: 15),

                      // Right column (wider)
                      Expanded(
                        flex: 3,
                        child: SingleChildScrollView(
                          physics: const NeverScrollableScrollPhysics(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: rightContent,
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
    );
  }

  Widget _buildHeaderRow(userData) {
    return Row(
      children: [
        // Profile image with white outline and purple border
        Stack(
          children: [
            const SizedBox(
              width: 100, // Space for positioning
              height: 100,
            ),
            Positioned(
              top: 0, // Adjust to move image
              right: 0,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.Cv2PurpleColor,
                    width: 3,
                  ),
                ),
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white, // White outline
                    shape: BoxShape.circle,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(2), // Inner space
                    child: ClipOval(
                      child: userData.profileImagePath != null &&
                              userData.profileImagePath.isNotEmpty
                          ? Image.file(
                              File(userData.profileImagePath),
                              fit: BoxFit.cover,
                            )
                          : Container(
                              color: Colors.grey.shade400, // Placeholder
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 16),

        // Name and designation shifted slightly upward
        Expanded(
          child: Transform.translate(
            offset: const Offset(0, -14), // Move text up slightly
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (userData.fullName != null && userData.fullName.isNotEmpty)
                  Text(
                    userData.fullName.toUpperCase(),
                    style: GoogleFonts.inriaSerif(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.Cv2PurpleColor,
                      letterSpacing: 1.6,
                    ),
                  ),
                if (userData.designation != null &&
                    userData.designation.isNotEmpty)
                  Text(
                    userData.designation,
                    style: GoogleFonts.poly(
                      fontSize: 8,
                      color: const Color(0xFFA3A3A3),
                      letterSpacing: 1,
                    ),
                  ),
              ],
            ),
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

    if (!hasPhone && !hasEmail && !hasWebsites) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(
          'CONTACT',
        ),
        const SizedBox(height: 4),
        if (hasPhone) _buildContactItem(Icons.phone, userData.phoneNumber!),
        if (hasEmail) _buildContactItem(Icons.email, userData.email!),
        if (hasWebsites)
          for (Website website in websites)
            _buildContactItem(Icons.link, website.url),
      ],
    );
  }

  Widget _buildEducationSection(List<EducationItem> educationItems) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(
          'EDUCATION',
        ),
        const SizedBox(height: 4),
        ...educationItems.map((item) {
          return Column(
            children: [
              _buildEducationItem(
                item.degree.toUpperCase() ?? '',
                item.institute ?? '',
                '${item.startDate ?? ''} ${item.endDate.isNotEmpty ? '- ${item.endDate}' : ''}',
                item.description ?? '',
              ),
              const SizedBox(height: 4),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildSkillsSection(List<Skill> skillItems) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(
          'SKILLS',
        ),
        const SizedBox(height: 4),
        ...skillItems
            .where((skill) => skill.name.isNotEmpty)
            .map((skill) => _buildBulletItem(skill.name))
            ,
      ],
    );
  }

  Widget _buildLanguagesSection(List<Language> languageItems) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(
          'LANGUAGES',
        ),
        const SizedBox(height: 4),
        ...languageItems
            .where((language) =>
                language.name.isNotEmpty)
            .map((language) => _buildBulletItem(language.name))
            ,
      ],
    );
  }

  Widget _buildObjectiveSection(UserModel userData) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(
          'Objective',
        ),
        const SizedBox(height: 4),
        Text(
          userData.careerObjective!,
          style: GoogleFonts.inter(
            fontSize: 7,
            color: Colors.grey.shade800,
            height: 1.4,
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
            fontSize: 7,
            fontWeight: FontWeight.w600,
            color: AppColors.Cv2PurpleColor,
          ),
        ),
      ],
    );
  }

  Widget _buildContactItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 8, color: Colors.grey.shade700),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 6,
                color: Colors.grey.shade700,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEducationItem(
      String degree, String major, String institution, String years) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (degree.isNotEmpty)
          Text(
            degree,
            style: GoogleFonts.poppins(
              fontSize: 7,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
        if (major.isNotEmpty)
          Text(
            major,
            style: GoogleFonts.poppins(
              fontSize: 6,
              color: Colors.grey.shade700,
            ),
          ),
        if (institution.isNotEmpty)
          Text(
            institution,
            style: GoogleFonts.poppins(
              fontSize: 6,
              fontStyle: FontStyle.italic,
              color: Colors.grey.shade700,
            ),
          ),
        if (years.trim().isNotEmpty)
          Text(
            years,
            style: GoogleFonts.poppins(
              fontSize: 6,
              color: Colors.grey.shade600,
            ),
          ),
      ],
    );
  }

  Widget _buildBulletItem(String text) {
    if (text.isEmpty) return Container();

    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: GoogleFonts.poppins(
              fontSize: 6,
              color: Colors.grey.shade800,
            ),
          ),
          Flexible(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 6,
                color: Colors.grey.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExperienceItem(String title, String company, String description,
      {List<String>? bulletPoints, List<String>? projectUrls}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title.isNotEmpty)
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 8,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
        if (company.trim().isNotEmpty)
          Text(
            company,
            style: GoogleFonts.poppins(
              fontSize: 7,
              color: Colors.grey.shade600,
              fontStyle: FontStyle.italic,
            ),
          ),
        if (title.isNotEmpty || company.trim().isNotEmpty)
          const SizedBox(height: 3),
        if (description.isNotEmpty)
          Text(
            description,
            style: GoogleFonts.inter(
              fontSize: 6,
              color: Colors.grey.shade800,
              height: 1.4,
            ),
          ),
        if (bulletPoints != null && bulletPoints.isNotEmpty) ...[
          const SizedBox(height: 4),
          ...bulletPoints.asMap().entries.map((entry) {
            final index = entry.key;
            final point = entry.value;
            if (point.trim().isEmpty) return Container();

            return Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '• ',
                        style: GoogleFonts.poppins(
                          fontSize: 6,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      Flexible(
                        child: Text(
                          point,
                          style: GoogleFonts.poppins(
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
                          style: GoogleFonts.poppins(
                            fontSize: 6,
                            color: Colors.blue,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          }).where((widget) => widget != Container()),
        ],
      ],
    );
  }

  Widget _buildCertificationItem(
      String title, String institution, String description) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title.isNotEmpty)
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 8,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
        if (institution.trim().isNotEmpty)
          Text(
            institution,
            style: GoogleFonts.poppins(
              fontSize: 7,
              color: Colors.grey.shade600,
              fontStyle: FontStyle.italic,
            ),
          ),
        if (title.isNotEmpty || institution.trim().isNotEmpty)
          const SizedBox(height: 3),
        if (description.isNotEmpty)
          Text(
            description,
            style: GoogleFonts.inter(
              fontSize: 6,
              color: Colors.grey.shade800,
              height: 1.4,
            ),
          ),
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
