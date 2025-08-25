import 'package:flutter/material.dart';
import 'grid_painter.dart';

class SingleScan extends StatelessWidget {
  final bool isGridVisible;
  final double bottomPadding;

  const SingleScan({
    super.key,
    required this.isGridVisible,
    required this.bottomPadding,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (isGridVisible)
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            bottom: bottomPadding,
            child: CustomPaint(
              painter: GridPainter(),
            ),
          ),
      ],
    );
  }
}