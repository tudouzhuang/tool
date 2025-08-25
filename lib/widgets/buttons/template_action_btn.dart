import 'package:flutter/material.dart';
import 'change_template_btn.dart';
import 'export_cv_btn.dart';

class TemplateActionButtons extends StatelessWidget {
  final VoidCallback onChangeTemplate;
  final VoidCallback onExport;

  const TemplateActionButtons({
    super.key,
    required this.onChangeTemplate,
    required this.onExport,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ChangeTemplateButton(onPressed: onChangeTemplate),
          const SizedBox(width: 16),
          ExportButton(onExport: onExport),
        ],
      ),
    );
  }
}