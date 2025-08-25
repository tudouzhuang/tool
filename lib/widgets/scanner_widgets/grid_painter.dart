import 'package:flutter/material.dart';
import '../../../utils/app_colors.dart';

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = AppColors.primary.withOpacity(0.5)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Draw horizontal lines
    double horizontalSpacing = size.height / 3;
    canvas.drawLine(
      Offset(0, horizontalSpacing),
      Offset(size.width, horizontalSpacing),
      paint,
    );
    canvas.drawLine(
      Offset(0, horizontalSpacing * 2),
      Offset(size.width, horizontalSpacing * 2),
      paint,
    );

    // Draw vertical lines
    double verticalSpacing = size.width / 3;
    canvas.drawLine(
      Offset(verticalSpacing, 0),
      Offset(verticalSpacing, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(verticalSpacing * 2, 0),
      Offset(verticalSpacing * 2, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

class CameraGrid extends StatelessWidget {
  final bool isVisible;
  final double bottomPadding;

  const CameraGrid({
    super.key,
    required this.isVisible,
    required this.bottomPadding,
  });

  @override
  Widget build(BuildContext context) {
    if (!isVisible) return const SizedBox.shrink();

    return Positioned.fill(
      bottom: bottomPadding,
      child: CustomPaint(
        painter: GridPainter(),
      ),
    );
  }
}