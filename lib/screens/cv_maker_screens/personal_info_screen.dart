import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import '../../provider/user_provider.dart';
import '../../widgets/cv_widgets/personal_info_form.dart';
import '../../widgets/cv_widgets/personal_info_img_picker.dart';

class PersonalInfoPage extends StatefulWidget {
  final int templateId;
  final String templateName;
  final Map<String, dynamic>? initialData;

  const PersonalInfoPage({
    super.key,
    required this.templateId,
    required this.templateName,
    this.initialData,
  });

  @override
  PersonalInfoPageState createState() => PersonalInfoPageState();
}

class PersonalInfoPageState extends State<PersonalInfoPage> {
  File? _imageFile;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _designationController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  String? _nameError;
  String? _designationError;
  String? _emailError;
  String? _phoneError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadUserData());
  }

  void _loadUserData() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userData = userProvider.userData;

    // Check for initial data first (edit mode)
    if (widget.initialData != null) {
      _nameController.text = widget.initialData!['fullName'] ?? '';
      _designationController.text = widget.initialData!['designation'] ?? '';
      _emailController.text = widget.initialData!['email'] ?? '';
      _phoneController.text = widget.initialData!['phoneNumber'] ?? '';

      if (widget.initialData!['profileImagePath'] != null) {
        final file = File(widget.initialData!['profileImagePath']);
        if (file.existsSync()) {
          setState(() => _imageFile = file);
        }
      }
    }
    // Fall back to user provider data (create mode)
    else if (userData.fullName?.isNotEmpty ?? false) {
      _nameController.text = userData.fullName!;
    }
    if (userData.fullName?.isNotEmpty ?? false) {
      _nameController.text = userData.fullName!;
    }
    if (userData.designation?.isNotEmpty ?? false) {
      _designationController.text = userData.designation!;
    }
    if (userData.email?.isNotEmpty ?? false) {
      _emailController.text = userData.email!;
    }
    if (userData.phoneNumber?.isNotEmpty ?? false) {
      _phoneController.text = userData.phoneNumber!;
    }

    if (userData.profileImagePath != null) {
      final file = File(userData.profileImagePath!);
      if (file.existsSync()) {
        setState(() => _imageFile = file);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _designationController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // Add this method to save current field values to UserProvider
  void saveCurrentDataToProvider() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    userProvider.updateUserData(
      fullName: _nameController.text.trim(),
      designation: _designationController.text.trim(),
      email: _emailController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      profileImagePath: _imageFile?.path,
    );
  }

  bool validate() {
    bool isValid = true;

    // Clear previous errors
    setState(() {
      _nameError = null;
      _designationError = null;
      _emailError = null;
      _phoneError = null;
    });

    if (_nameController.text.isEmpty) {
      setState(() => _nameError = 'please_enter_name'.tr);
      isValid = false;
    }

    if (_designationController.text.isEmpty) {
      setState(() => _designationError = 'please_enter_designation'.tr);
      isValid = false;
    } else if (!_isValidDesignation(_designationController.text)) {
      setState(() => _designationError = 'please_enter_valid_designation'.tr);
      isValid = false;
    }

    if (_emailController.text.isEmpty) {
      setState(() => _emailError = 'please_enter_email'.tr);
      isValid = false;
    } else if (!_isValidEmail(_emailController.text)) {
      setState(() => _emailError = 'please_enter_valid_email'.tr);
      isValid = false;
    }

    if (_phoneController.text.isEmpty) {
      setState(() => _phoneError = 'please_enter_phone'.tr);
      isValid = false;
    } else if (!_isValidPhone(_phoneController.text)) {
      setState(() => _phoneError = 'please_enter_valid_phone'.tr);
      isValid = false;
    }

    // If validation passes, save all current data to provider
    if (isValid) {
      saveCurrentDataToProvider();
    }

    return isValid;
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+');
    return emailRegex.hasMatch(email);
  }

  bool _isValidPhone(String phone) {
    final phoneRegex = RegExp(r'^[0-9]{10,15}$');
    return phoneRegex.hasMatch(phone);
  }

  bool _isValidDesignation(String designation) {
    final designationRegex = RegExp(r'^[a-zA-Z0-9\s\-]{2,}$');
    return designationRegex.hasMatch(designation);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        saveCurrentDataToProvider();
        return true;
      },
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 26.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              PersonalInfoImagePicker(
                imageFile: _imageFile,
                onImagePicked: (file) {
                  setState(() => _imageFile = file);
                  Provider.of<UserProvider>(context, listen: false)
                      .updateUserData(profileImagePath: file.path);
                },
              ),
              if (_imageFile == null) const SizedBox(height: 20),
              if (_imageFile == null || _imageFile != null)
                const SizedBox(height: 20),
              PersonalInfoForm(
                nameController: _nameController,
                designationController: _designationController,
                emailController: _emailController,
                phoneController: _phoneController,
                nameError: _nameError,
                designationError: _designationError,
                emailError: _emailError,
                phoneError: _phoneError,
                onNameErrorChanged: (error) => setState(() => _nameError = error),
                onDesignationErrorChanged: (error) =>
                    setState(() => _designationError = error),
                onEmailErrorChanged: (error) =>
                    setState(() => _emailError = error),
                onPhoneErrorChanged: (error) =>
                    setState(() => _phoneError = error),
              ),
            ],
          ),
        ),
      ),
    );
  }
}