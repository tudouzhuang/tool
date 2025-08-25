import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toolkit/screens/home_screen.dart';

import '../../utils/app_colors.dart';
import '../onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    navigateToNext();
  }

  Future<void> navigateToNext() async {
    final prefs = await SharedPreferences.getInstance();
    final bool isFirstTime = prefs.getBool('isFirstTime') ?? true;

    await Future.delayed(const Duration(seconds: 2));

    if (isFirstTime) {
      await prefs.setBool('isFirstTime', false);
      Get.off(() => const OnboardingScreen());
    } else {
      Get.off(() => const HomeScreen());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xff225d66),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: SvgPicture.asset(
                'assets/images/toolkit_iconsvg.svg',
                width: 100,
                height: 100,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'ToolKit',
              style: TextStyle(
                fontSize: 20,
                fontFamily: GoogleFonts.inter().fontFamily,
                color: AppColors.white,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Scan. Edit. Manage',
              style: TextStyle(
                fontSize: 20,
                color: AppColors.white,
                fontFamily: GoogleFonts.inter().fontFamily,
              ),
            )
          ],
        ),
      ),
    );
  }
}
