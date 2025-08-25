import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart'; // Add this import for localization
import '../../provider/profile_provider.dart';
import '../../services/auth_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_snackbar.dart';
import '../../widgets/buttons/logout_button.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool isEditing = false;
  final AuthService _authService = AuthService();

  final List<Map<String, String>> avatars = [
    {"id": "1", "path": "assets/images/avatar/avatar_1.svg"},
    {"id": "2", "path": "assets/images/avatar/avatar_2.svg"},
    {"id": "3", "path": "assets/images/avatar/avatar_3.svg"},
    {"id": "4", "path": "assets/images/avatar/avatar_4.svg"},
    {"id": "5", "path": "assets/images/avatar/avatar_5.svg"},
    {"id": "6", "path": "assets/images/avatar/avatar_6.svg"},
  ];

  @override
  void initState() {
    super.initState();
    // Load fresh profile data when screen opens
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    try {
      final user = _authService.currentUser;
      if (user != null) {
        final userData = await _authService.getUserData(user.uid);
        final profileProvider = Provider.of<ProfileProvider>(context, listen: false);

        if (userData != null) {
          profileProvider.loadProfileData(
            avatar: userData.avatarId ?? '6',
            username: userData.displayName,
            email: userData.email,
            gender: userData.gender,
            dateOfBirth: userData.dateOfBirth,
          );
        }
      }
    } catch (e) {
      print('Error loading profile data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileProvider>(
      builder: (context, profileProvider, child) {
        return Scaffold(
          backgroundColor: AppColors.appBar,
          body: Column(
            children: [
              SizedBox(height: MediaQuery.of(context).padding.top + 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Text(
                        "profile".tr,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        isEditing ? Icons.check : Icons.edit,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        setState(() {
                          if (isEditing) {
                            _saveProfileChanges(profileProvider);
                          }
                          isEditing = !isEditing;
                        });
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: Stack(
                    children: [
                      SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            _buildProfilePictureSection(profileProvider),
                            const SizedBox(height: 30),
                            _buildProfileField(
                              label: "username".tr,
                              value: profileProvider.username ?? "not_set".tr,
                              isEditable: isEditing,
                              onEdit: () => _showEditDialog(
                                "username".tr,
                                profileProvider.username ?? "",
                                    (value) {
                                  if (value.isNotEmpty) {
                                    profileProvider.updateUsername(value);
                                  }
                                },
                              ),
                            ),
                            const SizedBox(height: 20),
                            _buildProfileField(
                              label: "email".tr,
                              value: profileProvider.email ?? "not_set".tr,
                              isEditable: isEditing,
                              onEdit: () => _showEditDialog(
                                "email".tr,
                                profileProvider.email ?? "",
                                    (value) {
                                  if (value.isNotEmpty) {
                                    profileProvider.updateEmail(value);
                                  }
                                },
                              ),
                            ),
                            const SizedBox(height: 20),
                            _buildProfileField(
                              label: "gender".tr,
                              value: profileProvider.gender ?? "not_set".tr,
                              isEditable: isEditing,
                              onEdit: () => _showGenderDialog(profileProvider),
                            ),
                            const SizedBox(height: 20),
                            _buildProfileField(
                              label: "date_of_birth".tr,
                              value: profileProvider.dateOfBirth ?? "not_set".tr,
                              isEditable: isEditing,
                              onEdit: () =>
                                  _showDatePickerDialog(profileProvider),
                            ),
                            const SizedBox(height: 80),
                          ],
                        ),
                      ),
                      Positioned(
                        left: 24,
                        right: 24,
                        bottom: 34,
                        child: LogoutButton(
                          onPressed: () {
                            _showLogoutDialog();
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfilePictureSection(ProfileProvider profileProvider) {
    final currentAvatar = avatars.firstWhere(
          (avatar) => avatar["id"] == profileProvider.selectedAvatar,
      orElse: () => avatars.first,
    );

    return Column(
      children: [
        Stack(
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.3),
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ClipOval(
                child: Container(
                  color: Colors.grey[50],
                  child: SvgPicture.asset(
                    currentAvatar["path"]!,
                    width: 120,
                    height: 120,
                  ),
                ),
              ),
            ),
            if (isEditing)
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () => _showAvatarSelectionDialog(profileProvider),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildProfileField({
    required String label,
    required String value,
    required bool isEditable,
    required VoidCallback onEdit,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (isEditable)
            GestureDetector(
              onTap: onEdit,
              child: const Icon(
                Icons.edit,
                size: 20,
                color: AppColors.primary,
              ),
            ),
        ],
      ),
    );
  }

  void _showAvatarSelectionDialog(ProfileProvider profileProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          "choose_avatar".tr,
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: GridView.builder(
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: avatars.length,
            itemBuilder: (context, index) {
              final avatar = avatars[index];
              final isSelected = profileProvider.selectedAvatar == avatar["id"];

              return GestureDetector(
                onTap: () async {
                  // First update the provider state immediately for UI responsiveness
                  profileProvider.updateAvatar(avatar["id"]!);

                  // Then save to Firestore in background
                  final user = _authService.currentUser;
                  if (user != null) {
                    try {
                      await _authService.updateUserProfile(
                        uid: user.uid,
                        avatarId: avatar["id"]!,
                      );

                      if (mounted) {
                        Navigator.pop(context);
                        AppSnackBar.show(context,
                            message: 'avatar_updated_successfully'.tr);
                      }
                    } catch (e) {
                      if (mounted) {
                        Navigator.pop(context);
                        AppSnackBar.show(context,
                            message: '${"failed_to_update_avatar".tr}: $e');
                      }
                    }
                  } else {
                    Navigator.pop(context);
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? AppColors.primary : Colors.grey[300]!,
                      width: isSelected ? 3 : 2,
                    ),
                  ),
                  child: ClipOval(
                    child: Container(
                      color: Colors.grey[50],
                      child: SvgPicture.asset(
                        avatar["path"]!,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "cancel".tr,
              style: GoogleFonts.inter(color: Colors.grey[600]),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(
      String field, String currentValue, Function(String) onSave) {
    final TextEditingController controller =
    TextEditingController(text: currentValue);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          "${"edit".tr} $field",
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: field,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "cancel".tr,
              style: GoogleFonts.inter(color: Colors.grey[600]),
            ),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                onSave(controller.text);
              }
              Navigator.pop(context);
            },
            child: Text(
              "save".tr,
              style: GoogleFonts.inter(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showGenderDialog(ProfileProvider profileProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          "select_gender".tr,
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text("male".tr, style: GoogleFonts.inter()),
              leading: Radio<String>(
                value: "Male",
                groupValue: profileProvider.gender,
                onChanged: (value) {
                  profileProvider.updateGender(value!);
                  Navigator.pop(context);
                },
                activeColor: AppColors.primary,
              ),
            ),
            ListTile(
              title: Text("female".tr, style: GoogleFonts.inter()),
              leading: Radio<String>(
                value: "Female",
                groupValue: profileProvider.gender,
                onChanged: (value) {
                  profileProvider.updateGender(value!);
                  Navigator.pop(context);
                },
                activeColor: AppColors.primary,
              ),
            ),
            ListTile(
              title: Text("other".tr, style: GoogleFonts.inter()),
              leading: Radio<String>(
                value: "Other",
                groupValue: profileProvider.gender,
                onChanged: (value) {
                  profileProvider.updateGender(value!);
                  Navigator.pop(context);
                },
                activeColor: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDatePickerDialog(ProfileProvider profileProvider) async {
    DateTime initialDate = DateTime.now();
    if (profileProvider.dateOfBirth != null &&
        profileProvider.dateOfBirth != "Not set") {
      try {
        initialDate = DateTime.parse(profileProvider.dateOfBirth!);
      } catch (e) {
        initialDate = DateTime.now();
      }
    }

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary, // Header background color
              onPrimary: Colors.white, // Header text color
              onSurface: Colors.black, // Body text color
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary, // Button text color
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      final formattedDate = "${pickedDate.toLocal()}".split(' ')[0];
      profileProvider.updateDateOfBirth(formattedDate);
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          "logout".tr,
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        content: Text(
          "are_you_sure_logout".tr,
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "cancel".tr,
              style: GoogleFonts.inter(color: Colors.grey[600]),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog first

              try {
                // Clear profile provider data before logout
                final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
                profileProvider.loadProfileData(
                  avatar: '6',
                  username: 'not_set'.tr,
                  email: 'not_set'.tr,
                  gender: 'not_set'.tr,
                  dateOfBirth: 'not_set'.tr,
                );

                // Sign out from auth service
                await _authService.signOut();

                // Navigate to login screen and clear navigation stack
                if (mounted) {
                  Navigator.pop(context);
                }
              } catch (e) {
                // Handle logout error
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${"error_during_logout".tr}: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: Text(
              "logout".tr,
              style: GoogleFonts.inter(
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveProfileChanges(ProfileProvider profileProvider) async {
    try {
      final user = _authService.currentUser;
      if (user != null) {
        await _authService.updateUserProfile(
          uid: user.uid,
          displayName: profileProvider.username,
          gender: profileProvider.gender,
          dateOfBirth: profileProvider.dateOfBirth,
          avatarId: profileProvider.selectedAvatar,
        );
      }

      AppSnackBar.show(context, message: 'profile_updated_successfully'.tr);
    } catch (e) {
      AppSnackBar.show(context, message: '${"failed_to_update_profile".tr}: $e');
    }
  }
}