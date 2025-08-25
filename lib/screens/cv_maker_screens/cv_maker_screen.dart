import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../provider/template_provider.dart';
import '../../widgets/tools/info_card.dart';
import '../../widgets/tools/tools_app_bar.dart';
import 'main_cv_screen.dart';

class CvMakerScreen extends StatefulWidget {
  const CvMakerScreen({super.key});

  @override
  State<CvMakerScreen> createState() => _CvMakerScreenState();
}

class _CvMakerScreenState extends State<CvMakerScreen> {
  // Define template names for better reference
  final List<String> templateNames = [
    'classic_professional'.tr,
    'modern_minimal'.tr,
    'creative_design'.tr,
    'executive_style'.tr
  ];

  // In CvMakerScreen.dart
  void _navigateToPersonalInfo(int templateId) {
    // Update the provider with selected template
    Provider.of<TemplateProvider>(context, listen: false)
        .setTemplate(templateId, templateNames[templateId - 1]);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => MainCVScreen(
          templateId: templateId,
          templateName: templateNames[templateId - 1],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: ToolsAppBar(
        title: 'cv_maker'.tr,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Main illustration
              Center(
                child: SvgPicture.asset(
                  'assets/images/cv_maker_img.svg',
                  height: 200,
                ),
              ),
              const SizedBox(height: 10),

              // Make your CV title
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: InfoCard(
                  title: 'make_your_cv'.tr,
                  description:
                      'cv_description'.tr,
                ),
              ),
              const SizedBox(height: 8),

              // Select Template text
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.10),
                        blurRadius: 12,
                        offset: const Offset(0, 0),
                      )
                    ],
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'select_template'.tr,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 16),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.7,
                        ),
                        itemCount: 4,
                        itemBuilder: (context, index) {
                          final templateId = index + 1;
                          return GestureDetector(
                            onTap: () => _navigateToPersonalInfo(templateId),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: SvgPicture.asset(
                                      'assets/images/templates/Template_$templateId.svg',
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return Container(
                                          color: Colors.grey[200],
                                          child: const Center(
                                            child: Icon(Icons.broken_image,
                                                color: Colors.grey),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
