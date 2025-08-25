import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart'; // Add this import for localization
import 'package:toolkit/screens/cv_maker_screens/personal_info_screen.dart';
import 'package:toolkit/screens/cv_maker_screens/skills_screen.dart';
import 'package:toolkit/screens/cv_maker_screens/website_screen.dart';
import 'package:toolkit/screens/cv_maker_screens/work_experience_screen.dart';
import '../../models/certification_model.dart';
import '../../models/education_item_model.dart';
import '../../models/language_model.dart';
import '../../models/skills_model.dart';
import '../../models/website_model.dart';
import '../../models/work_experience_model.dart';
import '../../provider/certification_provider.dart';
import '../../provider/education_provider.dart';
import '../../provider/language_provider.dart';
import '../../provider/skills_provider.dart';
import '../../provider/user_provider.dart';
import '../../provider/work_experience_provider.dart';
import '../../utils/app_snackbar.dart';
import '../../widgets/buttons/gradient_btn.dart';
import '../../widgets/cv_progress_indicator.dart';
import '../../widgets/custom_appbar.dart';
import '../../provider/template_provider.dart';
import '../../widgets/cv_templates/template_1.dart';
import '../../widgets/cv_templates/template_2.dart';
import '../../widgets/cv_templates/template_3.dart';
import '../../widgets/cv_templates/template4.dart';
import 'career_objectives_screen.dart';
import 'certifications_screen.dart';
import 'education_details_screen.dart';
import 'language_screen.dart';

class MainCVScreen extends StatefulWidget {
  final int templateId;
  final String templateName;
  final dynamic editData;
  final bool isEditing;
  final GlobalKey<PersonalInfoPageState> personalInfoKey = GlobalKey();
  final GlobalKey<CareerObjectivesPageState> careerObjectivesKey = GlobalKey();
  final GlobalKey<EducationDetailPageState> educationKey = GlobalKey();

  MainCVScreen({
    super.key,
    required this.templateId,
    required this.templateName,
    this.editData,
    this.isEditing = false,
  });

  @override
  State<MainCVScreen> createState() => _MainCVScreenState();
}

class _MainCVScreenState extends State<MainCVScreen> {
  int currentStep = 1;
  final PageController _pageController = PageController(initialPage: 0);
  bool _isLoadingEditData = false;

  // Localized step titles
  final List<String> stepTitles = [
    'personal_information'.tr,
    'career_objectives'.tr,
    'education_details'.tr,
    'work_experience'.tr,
    'certification_and_training'.tr,
    'skills'.tr,
    'languages'.tr,
    'website_and_social_link'.tr,
  ];

  @override
  void initState() {
    super.initState();
    if (widget.isEditing && widget.editData != null) {
      _loadEditDataIntoProviders();
    }
  }

  void _loadEditDataIntoProviders() async {
    if (_isLoadingEditData) return;
    _isLoadingEditData = true;

    final convertedData = _convertToStringMap(widget.editData);
    if (convertedData == null) {
      _isLoadingEditData = false;
      return;
    }

    try {
      // Wait for the next frame to ensure the widget tree is built
      await Future.delayed(Duration.zero);

      if (!mounted) {
        _isLoadingEditData = false;
        return;
      }

      // Personal Info
      final personalInfo = _convertToStringMap(convertedData['personalInfo']);
      if (personalInfo != null) {
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        userProvider.updateUserData(
          fullName: personalInfo['fullName'],
          designation: personalInfo['designation'],
          email: personalInfo['email'],
          phoneNumber: personalInfo['phoneNumber'],
          profileImagePath: personalInfo['profileImagePath'],
        );

        if (convertedData['careerObjective'] != null) {
          userProvider.updateCareerObjective(convertedData['careerObjective']);
        }
      }

      // Use a small delay between provider updates to prevent conflicts
      await _loadEducationData(convertedData);
      await _loadWorkExperienceData(convertedData);
      await _loadCertificationData(convertedData);
      await _loadSkillsData(convertedData);
      await _loadLanguagesData(convertedData);
      await _loadWebsitesData(convertedData);
    } catch (e) {
      debugPrint('${'error_loading_edit_data'.tr}: $e');
    } finally {
      _isLoadingEditData = false;
    }
  }

  Future<void> _loadEducationData(Map<String, dynamic> convertedData) async {
    await Future.delayed(const Duration(milliseconds: 50));
    if (!mounted) return;

    final educationData = _getNestedListData('education');
    if (educationData != null) {
      final educationProvider =
      Provider.of<EducationProvider>(context, listen: false);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        educationProvider.clearEducationItems();

        for (var item in educationData) {
          educationProvider.addEducationItem(EducationItem(
            degree: item['degree'] ?? '',
            institute: item['institute'] ?? '',
            startDate: item['startDate'] ?? '',
            endDate: item['endDate'] ?? '',
            description: item['description'] ?? '',
            isCompleted: item['isCompleted'] ?? false,
          ));
        }
      });
    }
  }

  Future<void> _loadWorkExperienceData(
      Map<String, dynamic> convertedData) async {
    await Future.delayed(const Duration(milliseconds: 50));
    if (!mounted) return;

    final workExpData = _getNestedListData('workExperience');
    if (workExpData != null) {
      final workExpProvider =
      Provider.of<WorkExperienceProvider>(context, listen: false);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        workExpProvider.clearWorkExperienceItems();

        for (var item in workExpData) {
          workExpProvider.addWorkExperience(WorkExperienceItem(
            position: item['position'] ?? '',
            company: item['company'] ?? '',
            startDate: item['startDate'] ?? '',
            endDate: item['endDate'] ?? '',
            projects: List<String>.from(item['projects'] ?? []),
            projectUrls: List<String>.from(item['projectUrls'] ?? []),
            description: item['description'] ?? '',
            isCurrent: item['isCurrent'] ?? false,
          ));
        }
      });
    }
  }

  Future<void> _loadCertificationData(
      Map<String, dynamic> convertedData) async {
    if (_isLoadingEditData) return;

    try {
      // Add a small delay to ensure the widget tree is ready
      await Future.delayed(const Duration(milliseconds: 50));

      if (!mounted) return;

      debugPrint('${'loading_certification_data'.tr}...');

      // Get certification data using the helper method
      final certData = _getNestedListData('certifications');
      debugPrint('${'certification_data'.tr}: $certData');

      if (certData != null && certData.isNotEmpty) {
        debugPrint('${'processing'.tr} ${certData.length} ${'certification_items'.tr}');

        final certProvider =
        Provider.of<CertificationProvider>(context, listen: false);

        // Use post-frame callback to ensure safe state updates
        WidgetsBinding.instance.addPostFrameCallback((_) {
          try {
            // Clear existing items
            certProvider.clearCertificationItems();

            // Add new items
            for (var item in certData) {
              final certificationItem = CertificationItem(
                certificationName: item['certificationName']?.toString() ?? '',
                organizationName: item['organizationName']?.toString() ?? '',
                startDate: item['startDate']?.toString() ?? '',
                endDate: item['endDate']?.toString() ?? '',
                description: item['description']?.toString() ?? '',
                isCompleted: item['isCompleted'] as bool? ?? false,
              );
              certProvider.addCertificationItem(certificationItem);
            }

            debugPrint('${'successfully_loaded'.tr} ${certData.length} ${'certifications'.tr}');
          } catch (e) {
            debugPrint('${'error_processing_certification_items'.tr}: $e');
          }
        });
      } else {
        debugPrint('no_certification_data_found'.tr);
      }
    } catch (e) {
      debugPrint('${'error_in_load_certification_data'.tr}: $e');
    } finally {
      _isLoadingEditData = false;
    }
  }

  Future<void> _loadSkillsData(Map<String, dynamic> convertedData) async {
    if (_isLoadingEditData) return;

    try {
      await Future.delayed(const Duration(milliseconds: 50));
      if (!mounted) return;

      debugPrint('${'loading_skills_data'.tr}...');
      final skillsData = _getNestedListData('skills');
      debugPrint('${'skills_data'.tr}: $skillsData');

      if (skillsData != null && skillsData.isNotEmpty) {
        debugPrint('${'processing'.tr} ${skillsData.length} ${'skills'.tr}');

        final skillsProvider =
        Provider.of<SkillsProvider>(context, listen: false);

        WidgetsBinding.instance.addPostFrameCallback((_) {
          try {
            skillsProvider.clearSkillItems();

            for (var item in skillsData) {
              skillsProvider.addSkill(
                Skill(name: item['name']?.toString() ?? ''),
              );
            }

            debugPrint('${'successfully_loaded'.tr} ${skillsData.length} ${'skills'.tr}');
          } catch (e) {
            debugPrint('${'error_processing_skills'.tr}: $e');
          }
        });
      } else {
        debugPrint('no_skills_data_found'.tr);
      }
    } catch (e) {
      debugPrint('${'error_in_load_skills_data'.tr}: $e');
    }
  }

  Future<void> _loadLanguagesData(Map<String, dynamic> convertedData) async {
    if (_isLoadingEditData) return;

    try {
      // Add a small delay to ensure the widget tree is ready
      await Future.delayed(const Duration(milliseconds: 50));
      if (!mounted) return;

      debugPrint('${'loading_languages_data'.tr}...');
      final languageData = _getNestedListData('languages');
      debugPrint('${'languages_data'.tr}: $languageData');

      if (languageData != null && languageData.isNotEmpty) {
        debugPrint('${'processing'.tr} ${languageData.length} ${'language_items'.tr}');

        final languageProvider =
        Provider.of<LanguageProvider>(context, listen: false);

        // Use post-frame callback to ensure safe state updates
        WidgetsBinding.instance.addPostFrameCallback((_) {
          try {
            // Clear existing items
            languageProvider.clearLanguages();

            // Add new items
            for (var item in languageData) {
              final languageName = item['name']?.toString() ?? '';
              if (languageName.isNotEmpty) {
                languageProvider.addLanguage(Language(name: languageName));
              }
            }

            debugPrint('${'successfully_loaded'.tr} ${languageData.length} ${'languages'.tr}');
          } catch (e) {
            debugPrint('${'error_processing_language_items'.tr}: $e');
          }
        });
      } else {
        debugPrint('no_language_data_found'.tr);
      }
    } catch (e) {
      debugPrint('${'error_in_load_languages_data'.tr}: $e');
    } finally {
      _isLoadingEditData = false;
    }
  }

  Future<void> _loadWebsitesData(Map<String, dynamic> convertedData) async {
    await Future.delayed(const Duration(milliseconds: 50));
    if (!mounted) return;

    debugPrint('${'loading_websites_data'.tr}...');
    debugPrint('${'converted_data_keys'.tr}: ${convertedData.keys}');

    // Check for both possible keys
    final websitesData = convertedData['websites'] ?? convertedData['website'];
    debugPrint('${'websites_data'.tr}: $websitesData');

    if (websitesData != null) {
      debugPrint('${'processing_websites_data'.tr}...');

      List<Website> websites = [];

      if (websitesData is List) {
        // Handle list format
        for (var item in websitesData) {
          final websiteMap = _convertToStringMap(item);
          if (websiteMap != null) {
            websites.add(Website(
              name: websiteMap['name'] ?? 'website'.tr,
              url: websiteMap['url'] ?? '',
            ));
          }
        }
      } else if (websitesData is Map) {
        // Handle single website (legacy format)
        final websiteMap = _convertToStringMap(websitesData);
        if (websiteMap != null) {
          websites.add(Website(
            name: websiteMap['name'] ?? 'website'.tr,
            url: websiteMap['url'] ?? websiteMap['websiteUrl'] ?? '',
          ));
        }
      }

      debugPrint('${'loaded'.tr} ${websites.length} ${'websites'.tr}');
      if (websites.isNotEmpty) {
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        userProvider.updateWebsites(websites);
        debugPrint('websites_updated_in_provider'.tr);
      }
    } else {
      debugPrint('no_websites_data_found'.tr);
    }
  }

  // Also, make sure your _getNestedListData method has proper debugging:
  List<Map<String, dynamic>>? _getNestedListData(String key) {
    final convertedData = _convertToStringMap(widget.editData);
    debugPrint('${'get_nested_list_data_called_for_key'.tr}: $key');
    debugPrint('${'converted_data'.tr}: $convertedData');

    if (convertedData == null) {
      debugPrint('converted_data_is_null'.tr);
      return null;
    }

    final nestedData = convertedData[key];
    debugPrint('${'nested_data_for'.tr} $key: $nestedData');
    debugPrint('${'nested_data_type'.tr}: ${nestedData.runtimeType}');

    if (nestedData is List) {
      debugPrint('${'processing_list_with'.tr} ${nestedData.length} ${'items'.tr}');
      final result = nestedData.map<Map<String, dynamic>>((item) {
        debugPrint('${'processing_item'.tr}: $item (${item.runtimeType})');
        if (item is Map) {
          final converted = Map<String, dynamic>.from(item);
          debugPrint('${'converted_item'.tr}: $converted');
          return converted;
        }
        debugPrint('item_is_not_map_returning_empty_map'.tr);
        return <String, dynamic>{};
      }).toList();

      debugPrint('${'final_result_for'.tr} $key: $result');
      return result;
    }

    debugPrint('nested_data_is_not_list'.tr);
    return null;
  }

  Map<String, dynamic>? _convertToStringMap(dynamic data) {
    if (data == null) return null;
    if (data is Map<String, dynamic>) return data;
    if (data is Map) {
      try {
        return Map<String, dynamic>.from(
            data.map((key, value) => MapEntry(key.toString(), value)));
      } catch (e) {
        debugPrint('${'error_converting_map'.tr}: $e');
        return <String, dynamic>{};
      }
    }
    return null;
  }

  Map<String, dynamic>? _getNestedData(String key) {
    final convertedData = _convertToStringMap(widget.editData);
    if (convertedData == null) return null;

    final nestedData = convertedData[key];
    return _convertToStringMap(nestedData);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void goToNextPage() {
    if (currentStep < stepTitles.length) {
      // Save current page data before moving to next
      _saveCurrentPageData();

      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void goToPreviousPage() {
    if (currentStep > 1) {
      // Save current page data before moving to previous
      _saveCurrentPageData();

      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _saveCurrentPageData() {
    // Save data for the current page
    switch (currentStep) {
      case 1:
      // Personal Info - data is automatically saved via saveCurrentDataToProvider
        widget.personalInfoKey.currentState?.saveCurrentDataToProvider();
        break;
    // Add cases for other pages as needed
    }
  }

  void _navigateToTemplate(BuildContext context) {
    final templateProvider =
    Provider.of<TemplateProvider>(context, listen: false);
    final templateId = templateProvider.selectedTemplateId;
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

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => templateScreen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async {
          if (currentStep > 1) {
            goToPreviousPage();
            return false;
          }
          return true;
        },
        child: Scaffold(
          backgroundColor: Colors.white,
          appBar: CustomAppBar(
            title: stepTitles[currentStep - 1],
            onBackPressed: () {
              if (currentStep > 1) {
                goToPreviousPage();
              } else {
                Navigator.pop(context);
              }
            },
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 26, left: 26, top: 30),
                child: CVProgressIndicator(currentStep: currentStep),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (index) {
                    setState(() {
                      currentStep = index + 1;
                    });
                  },
                  children: [
                    PersonalInfoPage(
                      key: widget.personalInfoKey,
                      templateId: widget.templateId,
                      templateName: widget.templateName,
                      initialData: _getNestedData('personalInfo'),
                    ),
                    CareerObjectivesPage(key: widget.careerObjectivesKey),
                    EducationDetailPage(
                      key: widget.educationKey,
                      initialData: _getNestedListData('education'),
                    ),
                    WorkExperiencePage(
                      initialData: _getNestedListData('workExperience'),
                    ),
                    CertificationPage(
                      initialData: _getNestedListData('certifications'),
                    ),
                    SkillsPage(
                      initialData: _getNestedListData('skills'),
                    ),
                    LanguagesPage(
                      initialData: _getNestedListData('languages'),
                    ),
                    WebsitePage(
                      initialData: _getNestedListData('websites'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          bottomNavigationBar: Padding(
            padding: const EdgeInsets.only(
              bottom: 28.0,
              left: 28.0,
              right: 28.0,
              top: 10.0,
            ),
            child: CustomGradientButton(
              text: widget.isEditing
                  ? 'update'.tr
                  : (currentStep == stepTitles.length ? 'add'.tr : 'next'.tr),
              onPressed: () {
                // Validation for each step
                bool isValid = false;

                if (currentStep == 1) {
                  // Personal Info validation
                  isValid =
                      widget.personalInfoKey.currentState?.validate() ?? false;
                } else if (currentStep == 2) {
                  // Career Objectives validation
                  isValid =
                      widget.careerObjectivesKey.currentState?.validate() ??
                          false;
                } else if (currentStep == 3) {
                  // Education validation
                  final educationProvider =
                  Provider.of<EducationProvider>(context, listen: false);
                  isValid = educationProvider.educationItems.isNotEmpty;
                  if (!isValid) {
                    AppSnackBar.show(context,
                        message: 'please_add_at_least_one_education_item'.tr);
                  }
                } else if (currentStep == 4) {
                  // Work Experience validation
                  final workExpProvider = Provider.of<WorkExperienceProvider>(
                      context,
                      listen: false);
                  isValid = workExpProvider.workExperienceItems.isNotEmpty;
                  if (!isValid) {
                    AppSnackBar.show(context,
                        message: 'please_add_at_least_one_work_experience'.tr);
                  }
                } else if (currentStep == 5) {
                  // Certification validation
                  final certProvider = Provider.of<CertificationProvider>(
                      context,
                      listen: false);
                  isValid = certProvider.certificationItems.isNotEmpty;
                  if (!isValid) {
                    AppSnackBar.show(context,
                        message: 'please_add_at_least_one_certification'.tr);
                  }
                } else if (currentStep == 6) {
                  // Skills validation
                  final skillsProvider =
                  Provider.of<SkillsProvider>(context, listen: false);
                  isValid = skillsProvider.skillItems.isNotEmpty;
                  if (!isValid) {
                    AppSnackBar.show(context,
                        message: 'please_add_at_least_one_skill'.tr);
                  }
                } else if (currentStep == 7) {
                  // Languages validation
                  final languageProvider =
                  Provider.of<LanguageProvider>(context, listen: false);
                  isValid = languageProvider.languages.isNotEmpty;
                  if (!isValid) {
                    AppSnackBar.show(context,
                        message: 'please_add_at_least_one_language'.tr);
                  }
                } else if (currentStep == 8) {
                  // Websites validation
                  final userProvider =
                  Provider.of<UserProvider>(context, listen: false);
                  isValid = userProvider.websites.isNotEmpty;
                  if (!isValid) {
                    AppSnackBar.show(context,
                        message: 'please_add_at_least_one_website_link'.tr);
                  }
                } else {
                  // For other steps, allow navigation
                  isValid = true;
                }

                if (isValid) {
                  if (currentStep < stepTitles.length) {
                    goToNextPage();
                  } else {
                    _navigateToTemplate(context);
                  }
                }
              },
            ),
          ),
        ));
  }
}