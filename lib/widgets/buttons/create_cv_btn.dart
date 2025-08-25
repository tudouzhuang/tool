import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../screens/cv_maker_screens/create_cv_screen.dart';
import '../../utils/app_colors.dart';

class CreateCVButton extends StatelessWidget {
  final VoidCallback onTap;

  const CreateCVButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CreateCvScreen()),
        );
      },
      child: Container(
        height: 58,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 100),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              'assets/icons/pencil_cv.svg',
              height: 20,
              width: 20,
            ),
            Expanded(
              child: Text(
                'create_your_cv'.tr,
                textAlign: TextAlign.center,
                style: GoogleFonts.notoSans(
                  color: AppColors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}