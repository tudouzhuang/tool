import 'package:flutter/material.dart';
import 'dart:io';


class DocumentPreview extends StatelessWidget {
  final File image;
  final VoidCallback? onClose; // Optional callback for when the close button is pressed

  const DocumentPreview({
    super.key,
    required this.image,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: InteractiveViewer(
        panEnabled: true,
        minScale: 0.5,
        maxScale: 3.0,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.8,
            maxHeight: MediaQuery.of(context).size.height * 0.6,
          ),
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                spreadRadius: 2,
              )
            ],
          ),
          child: Stack(
            children: [
              Image.file(
                image,
                fit: BoxFit.contain,
              ),

            ],
          ),
        ),
      ),
    );
  }
}