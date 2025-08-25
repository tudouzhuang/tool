import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';
import '../../provider/user_provider.dart';
import '../../widgets/custom_text_field.dart';

class PersonalInfoForm extends StatefulWidget {
  final TextEditingController nameController;
  final TextEditingController designationController;
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final String? nameError;
  final String? designationError;
  final String? emailError;
  final String? phoneError;
  final Function(String?) onNameErrorChanged;
  final Function(String?) onDesignationErrorChanged;
  final Function(String?) onEmailErrorChanged;
  final Function(String?) onPhoneErrorChanged;

  const PersonalInfoForm({
    super.key,
    required this.nameController,
    required this.designationController,
    required this.emailController,
    required this.phoneController,
    required this.nameError,
    required this.designationError,
    required this.emailError,
    required this.phoneError,
    required this.onNameErrorChanged,
    required this.onDesignationErrorChanged,
    required this.onEmailErrorChanged,
    required this.onPhoneErrorChanged,
  });

  @override
  _PersonalInfoFormState createState() => _PersonalInfoFormState();
}

class _PersonalInfoFormState extends State<PersonalInfoForm> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.16),
            blurRadius: 3,
            offset: const Offset(0, 0),
          )
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildNameField(),
            const SizedBox(height: 16),
            _buildDesignationField(),
            const SizedBox(height: 16),
            _buildEmailField(),
            const SizedBox(height: 16),
            _buildPhoneField(),
          ],
        ),
      ),
    );
  }

  Widget _buildNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomTextField(
          label: 'full_name'.tr,
          hint: 'your_name'.tr,
          controller: widget.nameController,
          onChanged: (value) {
            Provider.of<UserProvider>(context, listen: false)
                .updateUserData(fullName: value);
            if (widget.nameError != null && value.isNotEmpty) {
              widget.onNameErrorChanged(null);
            }
          },
        ),
        if (widget.nameError != null)
          Padding(
            padding: const EdgeInsets.only(top: 4.0, left: 8.0),
            child: Text(
              widget.nameError!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.red,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDesignationField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomTextField(
          label: 'designation'.tr,
          hint: 'your_designation'.tr,
          controller: widget.designationController,
          onChanged: (value) {
            Provider.of<UserProvider>(context, listen: false)
                .updateUserData(designation: value);
            if (widget.designationError != null &&
                value.isNotEmpty &&
                _isValidDesignation(value)) {
              widget.onDesignationErrorChanged(null);
            }
          },
        ),
        if (widget.designationError != null)
          Padding(
            padding: const EdgeInsets.only(top: 4.0, left: 8.0),
            child: Text(
              widget.designationError!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.red,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEmailField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomTextField(
          label: 'email'.tr,
          hint: 'your_email'.tr,
          keyboardType: TextInputType.emailAddress,
          controller: widget.emailController,

          onChanged: (value) {
            Provider.of<UserProvider>(context, listen: false)
                .updateUserData(email: value);
            if (widget.emailError != null &&
                value.isNotEmpty &&
                _isValidEmail(value)) {
              widget.onEmailErrorChanged(null);
            }
          },
        ),
        if (widget.emailError != null)
          Padding(
            padding: const EdgeInsets.only(top: 4.0, left: 8.0),
            child: Text(
              widget.emailError!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.red,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPhoneField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomTextField(
          label: 'phone_number'.tr,
          hint: 'your_phone_number'.tr,
          keyboardType: TextInputType.phone,
          controller: widget.phoneController,
          onChanged: (value) {
            Provider.of<UserProvider>(context, listen: false)
                .updateUserData(phoneNumber: value);
            if (widget.phoneError != null &&
                value.isNotEmpty &&
                _isValidPhone(value)) {
              widget.onPhoneErrorChanged(null);
            }
          },
        ),
        if (widget.phoneError != null)
          Padding(
            padding: const EdgeInsets.only(top: 4.0, left: 8.0),
            child: Text(
              widget.phoneError!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.red,
              ),
            ),
          ),
      ],
    );
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+',
    );
    return emailRegex.hasMatch(email);
  }

  bool _isValidPhone(String phone) {
    final phoneRegex = RegExp(r'^[0-9]{10,15}$');
    return phoneRegex.hasMatch(phone);
  }

  bool _isValidDesignation(String designation) {
    // Validation rule: Designation should be at least 2 characters
    // and should not contain special characters except spaces and hyphens
    final designationRegex = RegExp(r'^[a-zA-Z0-9\s\-]{2,}$');
    return designationRegex.hasMatch(designation);
  }
}