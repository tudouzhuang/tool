import 'dart:async';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:toolkit/screens/settings_screens/password_verification_screen.dart';
import 'package:toolkit/screens/settings_screens/phone_recovery_screen.dart';
import 'package:toolkit/screens/settings_screens/set_password_screen.dart';
import 'package:toolkit/utils/app_colors.dart';
import '../../controllers/language_controller.dart';
import '../../provider/profile_provider.dart';
import '../../services/auth_service.dart';
import '../../services/notification_service.dart';
import '../../services/privacy_policy.dart';
import '../../services/rate_us.dart';
import '../../services/share_service.dart';
import '../../services/support_feedback_service.dart';
import '../../utils/app_snackbar.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/settings_widgets/settings_appbar.dart';
import '../../widgets/settings_widgets/settings_tile.dart';
import '../../widgets/settings_widgets/settings_toggle_tile.dart';
import 'continue_with_google_screen.dart';
import 'locked_files_Screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with WidgetsBindingObserver {
  bool _notificationsEnabled = false;
  bool _isGeneralExpanded = false;
  bool _isConfidentialExpanded = false;
  bool _isPasswordSet = false;
  bool _isUserAuthenticated = false;
  final AuthService _authService = AuthService();
  StreamSubscription? _authSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initialize();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _authSubscription?.cancel();
    super.dispose();
  }

  // Add this method to handle app lifecycle changes
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // Refresh password status when app resumes
      _refreshPasswordStatus();
    }
  }

  // Add this method to validate user state immediately
  Future<void> _validateUserState() async {
    try {
      await _authService.validateAndSignOutIfNeeded();

      final user = _authService.currentUser;
      if (user != null) {
        final userData = await _authService.getUserDataWithValidation(user.uid);

        if (userData != null) {
          // User is valid, update states
          if (mounted) {
            setState(() {
              _isUserAuthenticated = true;
            });
            await _loadPasswordStatus();
          }
        } else {
          // User document doesn't exist, reset states
          if (mounted) {
            setState(() {
              _isUserAuthenticated = false;
              _isPasswordSet = false;
            });
          }
        }
      } else {
        // User is not authenticated, reset states
        if (mounted) {
          setState(() {
            _isUserAuthenticated = false;
            _isPasswordSet = false;
          });
        }
      }
    } catch (e) {
      print('Error validating user state: $e');
      if (mounted) {
        setState(() {
          _isUserAuthenticated = false;
          _isPasswordSet = false;
        });
      }
    }
  }

// Update the _initialize method in your SettingsScreen

  Future<void> _initialize() async {
    await _loadNotificationStatus();
    _initializeLanguageController();

    // Validate user before setting up auth listener
    await _authService.validateAndSignOutIfNeeded();

    _setupAuthListener();
    await _loadInitialData();
  }

// Also update the _loadInitialData method to handle user validation
  Future<void> _loadInitialData() async {
    try {
      // Validate user first
      await _authService.validateAndSignOutIfNeeded();

      final user = _authService.currentUser;
      if (user != null) {
        // Check if user document exists
        final userData = await _authService.getUserDataWithValidation(user.uid);

        if (userData != null) {
          setState(() {
            _isUserAuthenticated = true;
          });
          await _loadPasswordStatus();
          await _loadProfileData();
        } else {
          // User document doesn't exist, user was signed out
          setState(() {
            _isUserAuthenticated = false;
            _isPasswordSet = false;
          });
        }
      } else {
        setState(() {
          _isUserAuthenticated = false;
          _isPasswordSet = false;
        });
      }
    } catch (e) {
      print('Error loading initial data: $e');
      setState(() {
        _isUserAuthenticated = false;
        _isPasswordSet = false;
      });
    }
  }

  void _setupAuthListener() {
    _authSubscription = _authService.authStateChanges.listen((user) async {
      if (mounted) {
        setState(() {
          _isUserAuthenticated = user != null;
        });

        if (_isUserAuthenticated) {
          await _loadPasswordStatus();
          await _loadProfileData();
        } else {
          setState(() {
            _isPasswordSet = false;
          });
        }
      }
    });
  }

// Update the _navigateToLockedFiles method to validate user state first
  Future<void> _navigateToLockedFiles() async {
    // Validate user state before proceeding
    await _validateUserState();

    if (!_isUserAuthenticated) {
      _showAuthenticationRequiredDialog();
      return;
    }

    if (!_isPasswordSet) {
      final result = await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('password_not_set'.tr),
          content: Text('password_required_for_locked_files'.tr),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'cancel'.tr,
                style: const TextStyle(color: Colors.black),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context, true);
                _navigateToSetPasswordScreen();
              },
              child: Text(
                'set_password'.tr,
                style: const TextStyle(
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      );
      return;
    }

    // Navigate to verification screen
    final verified = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => VerifyPasswordScreen(
          onVerified: () {
            Navigator.pop(context, true);
          },
        ),
      ),
    );

    if (verified == true && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const LockedFilesScreen(),
        ),
      );
    }
  }

  Future<void> _loadPasswordStatus() async {
    try {
      if (!_isUserAuthenticated) {
        setState(() {
          _isPasswordSet = false;
        });
        return;
      }

      bool isSet = await _authService.isPasswordSet();
      if (mounted) {
        setState(() {
          _isPasswordSet = isSet;
        });
      }
    } catch (e) {
      print('Error loading password status: $e');
      if (mounted) {
        setState(() {
          _isPasswordSet = false;
        });
      }
    }
  }

  // Add this method to refresh password status
  Future<void> _refreshPasswordStatus() async {
    if (_isUserAuthenticated) {
      await _loadPasswordStatus();
    }
  }

  // Update the _navigateToSetPasswordScreen method to validate user state first
  Future<void> _navigateToSetPasswordScreen() async {
    // Validate user state before proceeding
    await _validateUserState();

    if (!_isUserAuthenticated) {
      _showAuthenticationRequiredDialog();
      return;
    }

    final isPasswordSet = await _authService.isPasswordSet();

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SetPasswordScreen(
          isChanging: isPasswordSet,
        ),
      ),
    );

    // Refresh password status after returning from set password screen
    if (result == true && mounted) {
      await _refreshPasswordStatus();
    }
  }

  // Update the _navigateToPasswordRecovery method to validate user state first
  Future<void> _navigateToPasswordRecovery() async {
    // Validate user state before proceeding
    await _validateUserState();

    if (!_isUserAuthenticated) {
      _showAuthenticationRequiredDialog();
      return;
    }

    final profileProvider =
        Provider.of<ProfileProvider>(context, listen: false);
    final userEmail = profileProvider.email;

    if (userEmail != null && userEmail.isNotEmpty) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const PhoneRecoveryScreen(),
        ),
      );

      // Refresh password status after returning from recovery
      if (result == true && mounted) {
        await _refreshPasswordStatus();
      }
    } else {
      AppSnackBar.show(context, message: 'no_email_found'.tr);
    }
  }

  void _initializeLanguageController() {
    try {
      Get.find<LanguageController>();
    } catch (e) {
      Get.put(LanguageController());
    }
  }

  Future<void> _loadProfileData() async {
    try {
      final user = _authService.currentUser;
      if (user != null) {
        final userData = await _authService.getUserData(user.uid);
        final profileProvider =
            Provider.of<ProfileProvider>(context, listen: false);

        if (userData != null) {
          profileProvider.loadProfileData(
            avatar: userData.avatarId ?? '6',
            username: userData.displayName,
            email: userData.email,
            gender: userData.gender,
            dateOfBirth: userData.dateOfBirth,
          );
        } else {
          profileProvider.loadProfileData(
            avatar: profileProvider.selectedAvatar ?? '6',
            username: user.displayName ?? 'not_set'.tr,
            email: user.email ?? 'not_set'.tr,
            gender: 'not_set'.tr,
            dateOfBirth: 'not_set'.tr,
          );
        }
      }
    } catch (e) {
      print('Error loading profile data in settings: $e');
      final profileProvider =
          Provider.of<ProfileProvider>(context, listen: false);
      if (profileProvider.selectedAvatar == null) {
        profileProvider.loadProfileData(
          avatar: '6',
          username: 'not_set'.tr,
          email: 'not_set'.tr,
          gender: 'not_set'.tr,
          dateOfBirth: 'not_set'.tr,
        );
      }
    }
  }

  void _showAuthenticationRequiredDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.lock_outline,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'sign_in_required'.tr,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            'please_sign_in_to_secure_documents'.tr,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Colors.black54,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'cancel'.tr,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ContinueWithGoogleScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              child: Text(
                'sign_in'.tr,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _loadNotificationStatus() async {
    try {
      bool enabled = await NotificationService.areNotificationsEnabled();
      if (mounted) {
        setState(() {
          _notificationsEnabled = enabled;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _notificationsEnabled = false;
        });
      }
    }
  }

  Future<void> _handleNotificationToggle(bool newValue) async {
    if (newValue) {
      try {
        await NotificationService.initialize(context);
        bool permissionGranted = await NotificationService.requestPermissions();

        if (permissionGranted) {
          await NotificationService.setNotificationEnabled(true);
          if (mounted) {
            setState(() {
              _notificationsEnabled = true;
            });
          }
          AppSnackBar.show(context, message: 'notification_enabled'.tr);
        } else {
          await NotificationService.setNotificationEnabled(false);
          if (mounted) {
            setState(() {
              _notificationsEnabled = false;
            });
          }
          AppSnackBar.show(context, message: 'notification_permission'.tr);
        }
      } catch (e) {
        await NotificationService.setNotificationEnabled(false);
        if (mounted) {
          setState(() {
            _notificationsEnabled = false;
          });
        }
        AppSnackBar.show(context, message: '${'notification_error'.tr}: $e');
      }
    } else {
      try {
        await NotificationService.setNotificationEnabled(false);
        if (mounted) {
          setState(() {
            _notificationsEnabled = false;
          });
        }
        AppSnackBar.show(context, message: 'notification_disabled'.tr);
      } catch (e) {
        AppSnackBar.show(context, message: 'notification_error_disabling'.tr);
      }
    }
  }

  // Add this method to handle support and feedback email
  Future<void> _handleSupportFeedback() async {
    try {
      await Utils.launchEmail();
    } catch (e) {
      if (mounted) {
        AppSnackBar.show(context,
            message: 'could_not_launch_email'.tr.isNotEmpty
                ? 'could_not_launch_email'.tr
                : 'Could not launch email app');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackgroundWidget(
        child: Column(
          children: [
            SizedBox(height: MediaQuery.of(context).padding.top + 0),
            SettingsAppBar(
              title: 'settings'.tr,
              onBackPressed: () => Navigator.pop(context),
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(top: 10, left: 26, right: 26),
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    children: [
                      _buildGeneralSection(),
                      const SizedBox(height: 4),
                      _buildConfidentialDocumentsSection(),
                      const SizedBox(height: 4),
                      SettingTile(
                        title: 'locked_files'.tr,
                        onTap: _navigateToLockedFiles,
                      ),
                      const SizedBox(height: 4),
                      SettingToggleTile(
                        title: 'notifications_and_alerts'.tr,
                        value: _notificationsEnabled,
                        onChanged: _handleNotificationToggle,
                      ),
                      SettingTile(
                        title: 'support_feedback'.tr,
                        onTap:
                            _handleSupportFeedback, // Updated to call email function
                      ),
                      const SizedBox(height: 4),
                      SettingTile(
                        title: 'privacy_policy'.tr,
                        onTap: () async {
                          try {
                            await PrivacyPolicyService.openPrivacyPolicy();
                          } catch (e) {
                            if (mounted) {
                              AppSnackBar.show(context,
                                  message: 'could_not_open_privacy_policy'
                                          .tr
                                          .isNotEmpty
                                      ? 'could_not_open_privacy_policy'.tr
                                      : 'Could not open privacy policy');
                            }
                          }
                        },
                      ),
                      const SizedBox(height: 4),
                      SettingTile(
                        title: 'rate_us'.tr,
                        onTap: () async {
                          try {
                            await UrlLauncherService.launchAppStore();
                          } catch (e) {
                            if (mounted) {
                              AppSnackBar.show(
                                context,
                                message: 'could_not_open_store'.tr.isNotEmpty
                                    ? 'could_not_open_store'.tr
                                    : 'Could not open app store',
                              );
                            }
                          }
                        },
                      ),
                      const SizedBox(height: 4),
                      SettingTile(
                        title: 'share'.tr,
                        onTap: () {
                          try {
                            ShareService.shareApp();
                          } catch (e) {
                            if (mounted) {
                              AppSnackBar.show(context,
                                  message: 'could_not_share_app'.tr.isNotEmpty
                                      ? 'could_not_share_app'.tr
                                      : 'Could not share app');
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGeneralSection() {
    final languageController = Get.find<LanguageController>();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 2,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _isGeneralExpanded = !_isGeneralExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'general'.tr,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  Transform.rotate(
                    angle: _isGeneralExpanded ? 1.5708 : 0,
                    child: SvgPicture.asset(
                      'assets/icons/next_page_icon.svg',
                      height: 12,
                      width: 12,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isGeneralExpanded)
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.bgBoxColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.withOpacity(0.1)),
                ),
                child: Obx(() => DropdownButton2<String>(
                      value: languageController.currentLanguage.value,
                      iconStyleData: IconStyleData(
                        icon: SvgPicture.asset(
                          'assets/icons/arrow_up_down_icon.svg',
                          height: 16,
                          width: 16,
                        ),
                      ),
                      dropdownStyleData: DropdownStyleData(
                        elevation: 16,
                        width: MediaQuery.of(context).size.width * 0.79,
                        useSafeArea: true,
                        offset: const Offset(-10, 0),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: Colors.white,
                        ),
                      ),
                      isExpanded: true,
                      underline: Container(),
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: AppColors.gradientEnd,
                      ),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          final selected = languageController.languageOptions
                              .firstWhere((lang) => lang['name'] == newValue);
                          languageController.changeLanguage(
                            selected['code']!,
                            selected['country']!,
                            selected['name']!,
                          );
                        }
                      },
                      items: languageController.languageOptions
                          .map<DropdownMenuItem<String>>((lang) {
                        return DropdownMenuItem<String>(
                          value: lang['name'],
                          child: Text(
                            lang['name']!,
                          ),
                        );
                      }).toList(),
                    )),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildConfidentialDocumentsSection() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 2,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _isConfidentialExpanded = !_isConfidentialExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'confidential_documents'.tr,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  Transform.rotate(
                    angle: _isConfidentialExpanded ? 1.5708 : 0,
                    child: SvgPicture.asset(
                      'assets/icons/next_page_icon.svg',
                      height: 12,
                      width: 12,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isConfidentialExpanded)
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
              child: Column(
                children: [
                  InkWell(
                    onTap: _navigateToSetPasswordScreen,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            spreadRadius: 1,
                            blurRadius: 2,
                            offset: const Offset(0, 0),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _isPasswordSet
                                ? 'change_password'.tr
                                : 'set_password'.tr,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.primary,
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_isPasswordSet && _isUserAuthenticated)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.2),
                              spreadRadius: 1,
                              blurRadius: 2,
                              offset: const Offset(0, 0),
                            ),
                          ],
                        ),
                        child: InkWell(
                          onTap: _navigateToPasswordRecovery,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'code_recovery_options'.tr,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 16),
                                decoration: BoxDecoration(
                                  color: AppColors.bgBoxColor,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                      color: Colors.grey.withOpacity(0.1)),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'forgot_password'.tr,
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w400,
                                        color: AppColors.gradientEnd,
                                      ),
                                    ),
                                    const Icon(
                                      Icons.arrow_forward_ios,
                                      size: 16,
                                      color: AppColors.gradientEnd,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
