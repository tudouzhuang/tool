import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/app_colors.dart';

class AnimatedLoadingContainer extends StatefulWidget {
  final AnimationController animationController;
  final bool animationCompleted;

  const AnimatedLoadingContainer({
    super.key,
    required this.animationController,
    required this.animationCompleted,
  });

  @override
  State<AnimatedLoadingContainer> createState() =>
      _AnimatedLoadingContainerState();
}

class _AnimatedLoadingContainerState extends State<AnimatedLoadingContainer> {
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: widget.animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final percentage = (_progressAnimation.value * 100).toInt();
    return Center(
      child: Container(
        width: 265,
        height: 250,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.16),
              blurRadius: 4,
              offset: const Offset(0, 0),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 150,
              width: 150,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Background circle
                  const SizedBox(
                    height: 150,
                    width: 150,
                    child: CircularProgressIndicator(
                      value: 1.0, // Full circle for background
                      strokeWidth: 7,
                      backgroundColor: Colors.transparent,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFFD9D9D9), // Light gray background
                      ),
                    ),
                  ),
                  // Progress circle
                  SizedBox(
                    height: 150,
                    width: 150,
                    child: Transform.rotate(
                      angle: 6.2832, // Start from top (12 o'clock position)
                      child: CircularProgressIndicator(
                        value: _progressAnimation.value,
                        strokeWidth: 7,
                        backgroundColor: Colors.transparent,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.primary, // Teal green color matching image
                        ),
                        strokeCap: StrokeCap.round, // Rounded ends
                      ),
                    ),
                  ),
                  // Inner white circle (optional - for cleaner look)
                  Container(
                    height: 126, // Slightly smaller than outer circle
                    width: 126,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                  // Rounded container for percentage text
                  Container(
                    width: 130, // Set width
                    height: 130, // Set height to match width
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle, // Make it a circle
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    alignment: Alignment.center, // Center the text inside the circle
                    child: Text(
                      '$percentage%',
                      style: GoogleFonts.inter(
                        fontSize: 32,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  )

                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              widget.animationCompleted ? 'completed'.tr : 'please_wait'.tr,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: widget.animationCompleted
                    ? AppColors.primary
                    : AppColors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}