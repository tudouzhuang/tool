import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:toolkit/provider/template_provider.dart';
import 'package:toolkit/utils/app_colors.dart';

class TemplateSelectionDialog extends StatelessWidget {
  final List<int> availableTemplates;

  const TemplateSelectionDialog({
    super.key,
    this.availableTemplates = const [1, 2, 3, 4],
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Select Template', style: GoogleFonts.inter()),
      content: SizedBox(
        width: double.maxFinite,
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.7,
          ),
          itemCount: availableTemplates.length,
          itemBuilder: (context, index) {
            final templateId = availableTemplates[index];
            return _TemplateThumbnail(
              templateId: templateId,
              onSelected: () {
                final templateProvider =
                Provider.of<TemplateProvider>(context, listen: false);
                templateProvider.setTemplate(templateId, 'Template $templateId');
                Navigator.pop(context, templateId);
              },
            );
          },
        ),
      ),
    );
  }
}

class _TemplateThumbnail extends StatelessWidget {
  final int templateId;
  final VoidCallback onSelected;

  const _TemplateThumbnail({
    required this.templateId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onSelected,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Provider.of<TemplateProvider>(context).selectedTemplateId == templateId
                ? AppColors.primary
                : Colors.grey[300]!,
            width: Provider.of<TemplateProvider>(context).selectedTemplateId == templateId ? 2 : 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            children: [
              SvgPicture.asset(
                'assets/images/templates/Template_$templateId.svg',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[200],
                    child: const Center(
                      child: Icon(Icons.broken_image, color: Colors.grey),
                    ),
                  );
                },
              ),
              if (Provider.of<TemplateProvider>(context).selectedTemplateId == templateId)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 12,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}