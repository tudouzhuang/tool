import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../utils/app_colors.dart';

class CVProgressIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps = 8; // Updated to 8

  const CVProgressIndicator({
    super.key,
    required this.currentStep,
  });

  @override
  Widget build(BuildContext context) {
    // Determine which set of indicators to show based on current step
    int startIndicator = 1;
    int endIndicator = 4;

    if (currentStep >= 5 && currentStep <= 8) {
      startIndicator = 5;
      endIndicator = 8;
    }

    return Container(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ...List.generate(endIndicator - startIndicator + 1, (index) {
            int stepNumber = startIndicator + index;
            bool isCurrentStep = stepNumber == currentStep;
            bool isPreviousStep = stepNumber < currentStep;

            // Circle indicator
            Widget circleIndicator = Container(
              width: isCurrentStep || isPreviousStep ? 30 : 27,
              height: isCurrentStep || isPreviousStep ? 30 : 27,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isPreviousStep
                    ? AppColors.primary.withOpacity(0.7) // Completed step
                    : isCurrentStep
                    ? AppColors.primary // Current step
                    : AppColors.lineBarColor, // Future step
              ),
              child: Center(
                child: isPreviousStep
                    ? const Icon(
                  Icons.check,
                  color: AppColors.white,
                  size: 14,
                )
                    : Text(
                  '$stepNumber',
                  style: GoogleFonts.inter(
                    color: isCurrentStep ? AppColors.white : AppColors.black,
                    fontWeight: FontWeight.w400,
                    fontSize: isCurrentStep ? 16 : 14,
                  ),
                ),
              ),
            );

            // If it's the last item, just return the circle
            if (stepNumber == endIndicator) {
              return circleIndicator;
            }

            // Otherwise return a row with circle and line
            return Expanded(
              flex: 1,
              child: Row(
                children: [
                  circleIndicator,
                  Expanded(
                    flex: 4, // Give more space to the line
                    child: Container(
                      height: 8,
                      color: stepNumber < currentStep
                          ? AppColors.primary.withOpacity(0.7)
                          : AppColors.lineBarColor,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
