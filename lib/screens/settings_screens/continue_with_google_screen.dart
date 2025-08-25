import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../provider/profile_provider.dart';
import '../../services/auth_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_snackbar.dart';
import 'profile_screen.dart';
import 'phone_number_screen.dart';

class ContinueWithGoogleScreen extends StatefulWidget {
  const ContinueWithGoogleScreen({super.key});

  @override
  State<ContinueWithGoogleScreen> createState() =>
      _ContinueWithGoogleScreenState();
}

class _ContinueWithGoogleScreenState extends State<ContinueWithGoogleScreen> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Check if user is already logged in when screen opens
    _checkExistingLogin();
  }

  Future<void> _checkExistingLogin() async {
    try {
      final user = _authService.currentUser;
      if (user != null) {
        // User is already logged in, load data and check navigation
        await _loadUserDataAndNavigate(user.uid);
      }
    } catch (e) {
      print('Error checking existing login: $e');
      // Continue with normal flow if error occurs
    }
  }

  Future<void> _loadUserDataAndNavigate(String uid) async {
    try {
      final profileProvider =
          Provider.of<ProfileProvider>(context, listen: false);
      final userData = await _authService.getUserData(uid);

      if (userData != null) {
        // Load profile data
        profileProvider.loadProfileData(
          email: userData.email,
          username: userData.displayName,
          gender: userData.gender,
          dateOfBirth: userData.dateOfBirth,
          avatar: userData.avatarId,
          phoneNumber: userData.phoneNumber,
        );

        // Check if user has phone number to determine navigation
        final hasPhoneNumber =
            userData.phoneNumber != null && userData.phoneNumber!.isNotEmpty;

        if (mounted) {
          if (hasPhoneNumber) {
            // User has phone number, go directly to profile
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const ProfileScreen(),
              ),
            );
          } else {
            // User doesn't have phone number, go to phone number screen
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const PhoneNumberScreen(),
              ),
            );
          }
        }
      } else {
        // Handle case where user data doesn't exist
        final user = _authService.currentUser;
        if (user != null && mounted) {
          profileProvider.loadProfileData(
            email: user.email,
            username: user.displayName,
            gender: 'Not set',
            dateOfBirth: 'Not set',
            avatar: '6',
          );

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const PhoneNumberScreen(),
            ),
          );
        }
      }
    } catch (e) {
      print('Error loading user data and navigating: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary.withOpacity(0.3),
              AppColors.primary,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Back arrow button at the top left
              Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 10, top: 10, right: 10),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
              const Spacer(flex: 1), // Adjusted spacer
              Text(
                'smart_tools_tagline'.tr,
                style: GoogleFonts.inter(
                  fontSize: 48,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                  height: 1.2,
                ),
              ),
              const Spacer(flex: 3),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  width: double.infinity,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: _isLoading ? null : _handleGoogleSignIn,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_isLoading)
                            const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.primary,
                                ),
                              ),
                            )
                          else
                            SvgPicture.asset(
                              'assets/icons/google_icon.svg',
                              width: 24,
                              height: 24,
                            ),
                          const SizedBox(width: 12),
                          Text(
                            _isLoading
                                ? 'signing_in'.tr
                                : 'continue_with_google'.tr,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              color: const Color(0xFF1F2937),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const Spacer(flex: 2),
              TextButton(
                onPressed: _isLoading
                    ? null
                    : () {
                        Navigator.pop(context);
                      },
                child: Text(
                  'skip_for_now'.tr,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(_isLoading ? 0.4 : 0.8),
                    decoration: TextDecoration.underline,
                    decorationColor:
                        Colors.white.withOpacity(_isLoading ? 0.4 : 0.8),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userCredential = await _authService.signInWithGoogle();

      if (userCredential != null && userCredential.user != null) {
        final googleUser = userCredential.user!;

        print('Google user signed in: ${googleUser.email}');

        // Check if email already exists with phone number BEFORE any operations
        bool emailHasPhoneNumber = false;
        if (googleUser.email != null) {
          emailHasPhoneNumber =
              await _authService.emailExistsWithPhoneNumber(googleUser.email!);
          print('Email exists with phone number: $emailHasPhoneNumber');
        }

        // Merge Google user with existing Firestore data if exists
        final mergedUserData =
            await _authService.mergeGoogleUserWithExistingData(googleUser);
        print('Merged user data phone: ${mergedUserData?.phoneNumber}');

        final profileProvider =
            Provider.of<ProfileProvider>(context, listen: false);

        if (mergedUserData != null) {
          // Load merged profile data
          profileProvider.loadProfileData(
            email: mergedUserData.email,
            username: mergedUserData.displayName,
            gender: mergedUserData.gender,
            dateOfBirth: mergedUserData.dateOfBirth,
            avatar: mergedUserData.avatarId,
            phoneNumber: mergedUserData.phoneNumber,
          );

          print('Profile loaded with phone: ${mergedUserData.phoneNumber}');
        } else {
          // Fallback to basic Google user data
          profileProvider.loadProfileData(
            email: googleUser.email,
            username: googleUser.displayName,
            gender: 'Not set',
            dateOfBirth: 'Not set',
            avatar: '6',
          );
        }

        if (mounted) {
          // Navigate based on whether the merged user has a phone number
          final hasPhoneNumber = mergedUserData?.phoneNumber != null &&
              mergedUserData!.phoneNumber!.isNotEmpty;

          print('Has phone number for navigation: $hasPhoneNumber');

          if (hasPhoneNumber) {
            // User has phone number, go directly to profile
            print('Navigating to ProfileScreen');
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const ProfileScreen(),
              ),
            );
          } else {
            // User doesn't have phone number, go to phone number screen
            print('Navigating to PhoneNumberScreen');
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const PhoneNumberScreen(),
              ),
            );
          }
        }
      }
    } catch (e) {
      print('Error in Google sign in: $e');
      if (mounted) {
        AppSnackBar.show(context, message: 'google_signin_failed'.tr);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
