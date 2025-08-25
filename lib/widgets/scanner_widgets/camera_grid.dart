
import 'package:flutter/material.dart';

import 'grid_painter.dart';

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

    return Positioned(
      left: 0,
      right: 0,
      top: 0,
      bottom: bottomPadding,
      // This ensures the grid stops above the bottom container
      child: CustomPaint(
        painter: GridPainter(),
      ),
    );
  }
}