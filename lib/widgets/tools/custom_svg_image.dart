import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CustomSvgImage extends StatelessWidget {
  final String imagePath;
  final double? height;
  final double? width;

  const CustomSvgImage({
    super.key,
    required this.imagePath,
    this.height,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SvgPicture.asset(
        imagePath,
        height: height,
        width: width,
      ),
    );
  }
}
