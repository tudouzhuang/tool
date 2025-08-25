import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';

class DocumentCropFrame extends StatelessWidget {
  final double width;
  final double height;
  final double left;
  final double top;
  final String documentType;
  final bool isFrontSide;
  final Color borderColor;
  final double frameBorderWidth = 1.0; // thin frame
  final double cornerBorderWidth = 3.0;
  final BorderRadius? borderRadius;
  final String? customHintText;

  const DocumentCropFrame({
    super.key,
    required this.width,
    required this.height,
    required this.left,
    required this.top,
    this.documentType = 'generic',
    this.isFrontSide = true,
    this.borderColor = AppColors.primary,
    this.borderRadius,
    this.customHintText,
  });

  @override
  Widget build(BuildContext context) {
    // Determine if we should show corner marks (show for all except business card)
    final showCornerMarks = documentType != '';

    return Positioned(
      left: left,
      top: top,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          border: Border.all(
            color: borderColor,
            width: frameBorderWidth,
          ),
          borderRadius: borderRadius ?? BorderRadius.circular(4),
        ),
        child: Stack(
          children: [
            // Add corner marks for better alignment
            if (showCornerMarks) ...[
              _buildCornerMark(true, true), // top-left
              _buildCornerMark(true, false), // top-right
              _buildCornerMark(false, true), // bottom-left
              _buildCornerMark(false, false), // bottom-right
            ],
          ],
        ),
      ),
    );
  }

  // Helper method to build corner marks
  Widget _buildCornerMark(bool isTop, bool isLeft) {
    return Positioned(
      top: isTop ? 0 : null,
      bottom: isTop ? null : 0,
      left: isLeft ? 0 : null,
      right: isLeft ? null : 0,
      child: Container(
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          border: Border(
            top: isTop
                ? BorderSide(color: borderColor, width: cornerBorderWidth)
                : BorderSide.none,
            bottom: !isTop
                ? BorderSide(color: borderColor, width: cornerBorderWidth)
                : BorderSide.none,
            left: isLeft
                ? BorderSide(color: borderColor, width: cornerBorderWidth)
                : BorderSide.none,
            right: !isLeft
                ? BorderSide(color: borderColor, width: cornerBorderWidth)
                : BorderSide.none,
          ),
        ),
      ),
    );
  }
}
