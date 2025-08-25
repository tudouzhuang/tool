// widgets/common/auth_input_field.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/app_colors.dart';

class AuthInputField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final String hintText;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final bool isPhoneField;
  final String? countryCode;
  final Function(String?)? onCountryCodeChanged;
  final List<Map<String, String>>? countryCodes;

  const AuthInputField({
    super.key,
    required this.controller,
    required this.labelText,
    required this.hintText,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.isPhoneField = false,
    this.countryCode,
    this.onCountryCodeChanged,
    this.countryCodes,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Text(
          labelText,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),

        const SizedBox(height: 4),

        // Input field
        if (!isPhoneField)
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            decoration: _buildInputDecoration(hintText),
            style: GoogleFonts.inter(
              fontSize: 16,
              color: Colors.black,
            ),
            validator: validator,
          )
        else
          Row(
            children: [
              // Country code dropdown
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: AppColors.primary,
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: countryCode,
                    items: countryCodes?.map((countryData) {
                      return DropdownMenuItem<String>(
                        value: countryData['code'],
                        child: Text(
                          countryData['code']!,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            color: Colors.black,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: onCountryCodeChanged,
                    icon: const Icon(Icons.arrow_drop_down),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Phone number input
              Expanded(
                child: TextFormField(
                  controller: controller,
                  keyboardType: keyboardType,
                  decoration: _buildInputDecoration(hintText),
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: Colors.black,
                  ),
                  validator: validator,
                ),
              ),
            ],
          ),
      ],
    );
  }

  InputDecoration _buildInputDecoration(String hintText) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: GoogleFonts.inter(
        color: Colors.grey[400],
        fontSize: 16,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(
          color: AppColors.primary,
          width: 1,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(
          color: AppColors.primary,
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(
          color: AppColors.primary,
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(
          color: Colors.red,
          width: 1,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(
          color: Colors.red,
          width: 2,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
    );
  }
}