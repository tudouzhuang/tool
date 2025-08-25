import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:toolkit/screens/settings_screens/profile_screen.dart';
import 'package:toolkit/screens/settings_screens/phone_number_screen.dart';
import '../../provider/profile_provider.dart';
import '../../screens/settings_screens/continue_with_google_screen.dart';
import '../../services/auth_service.dart';

class SettingsAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onBackPressed;
  final VoidCallback? onProfilePressed;

  const SettingsAppBar({
    super.key,
    required this.title,
    this.onBackPressed,
    this.onProfilePressed,
  });

  // Avatar list matching your profile screen
  final List<Map<String, String>> avatars = const [
    {"id": "1", "path": "assets/images/avatar/avatar_1.svg"},
    {"id": "2", "path": "assets/images/avatar/avatar_2.svg"},
    {"id": "3", "path": "assets/images/avatar/avatar_3.svg"},
    {"id": "4", "path": "assets/images/avatar/avatar_4.svg"},
    {"id": "5", "path": "assets/images/avatar/avatar_5.svg"},
    {"id": "6", "path": "assets/images/avatar/avatar_6.svg"},
  ];

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: onBackPressed ?? () => Navigator.pop(context),
      ),
      title: Text(
        title,
        style: GoogleFonts.inter(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      actions: [
        Consumer<ProfileProvider>(
          builder: (context, profileProvider, child) {
            // Get the current avatar or default to avatar 6
            final currentAvatarId = profileProvider.selectedAvatar ?? '6';
            final currentAvatar = avatars.firstWhere(
                  (avatar) => avatar["id"] == currentAvatarId,
              orElse: () => avatars.last, // This will be avatar 6
            );

            return GestureDetector(
              onTap: onProfilePressed ?? () => _handleProfileTap(context),
              child: Container(
                margin: const EdgeInsets.only(right: 16,left: 16),
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Container(
                    color: Colors.white,
                    child: SvgPicture.asset(
                      currentAvatar["path"]!,
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF5E56E7),
              Color(0xFF5E56E7),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
      ),
    );
  }

  void _handleProfileTap(BuildContext context) async {
    try {
      final AuthService authService = AuthService();
      final profileProvider = Provider.of<ProfileProvider>(context, listen: false);

      // First validate if current user is still valid
      await authService.validateAndSignOutIfNeeded();

      // Now check the auth state after validation
      final user = authService.currentUser;

      if (user != null) {
        // User is still logged in after validation, try to load data
        try {
          final userData = await authService.getUserDataWithValidation(user.uid);

          if (userData != null) {
            // User data exists, load it and check phone number
            final hasPhoneNumber = await authService.hasPhoneNumber();

            profileProvider.loadProfileData(
              avatar: userData.avatarId ?? '6',
              username: userData.displayName,
              email: userData.email,
              gender: userData.gender,
              dateOfBirth: userData.dateOfBirth,
              phoneNumber: userData.phoneNumber,
            );

            // Navigate based on phone number status
            if (hasPhoneNumber) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProfileScreen(),
                ),
              );
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PhoneNumberScreen(),
                ),
              );
            }
          } else {
            // User data doesn't exist (user was deleted), navigate to sign-in
            _navigateToSignIn(context, profileProvider);
          }
        } catch (e) {
          print('Error loading user data: $e');
          // Error occurred, navigate to sign-in screen
          _navigateToSignIn(context, profileProvider);
        }
      } else {
        // User is not logged in (was signed out during validation), navigate to sign-in
        _navigateToSignIn(context, profileProvider);
      }
    } catch (e) {
      print('Error in profile tap: $e');
      // Navigate to sign-in screen on any error
      final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
      _navigateToSignIn(context, profileProvider);
    }
  }

  void _navigateToSignIn(BuildContext context, ProfileProvider profileProvider) {
    // Clear any existing profile data
    profileProvider.loadProfileData(
      avatar: '6',
      username: 'Not set',
      email: 'Not set',
      gender: 'Not set',
      dateOfBirth: 'Not set',
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ContinueWithGoogleScreen(),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}