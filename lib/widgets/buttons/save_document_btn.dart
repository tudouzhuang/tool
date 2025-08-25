import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/save_document_service.dart';
import 'gradient_btn.dart';

// save_document_btn.dart (updated)
class SaveDocumentButton extends StatelessWidget {
  final File documentFile;
  final String buttonText;
  final double? width;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onSaveCompleted;
  final bool skipTimestamp; // Add this parameter

  const SaveDocumentButton({
    super.key,
    required this.documentFile,
    this.buttonText = 'save',
    this.width,
    this.padding,
    this.onSaveCompleted,
    this.skipTimestamp = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ??
          const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
      child: SizedBox(
        width: width ?? double.infinity,
        child: CustomGradientButton(
          onPressed: () => _handleSave(context),
          text: buttonText.tr,
        ),
      ),
    );
  }

  Future<void> _handleSave(BuildContext context) async {
    final result = await SaveDocumentService.saveDocument(
      context,
      documentFile,
      skipTimestamp: skipTimestamp, // Pass the parameter
    );

    if (result != null && onSaveCompleted != null) {
      onSaveCompleted!();
      Navigator.of(context).pop(true);
    }
  }
}
