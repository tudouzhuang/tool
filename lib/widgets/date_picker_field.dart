import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_colors.dart';

class DateField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final VoidCallback onTap;
  final String? errorText;
  final bool isEnabled;
  final FocusNode? focusNode;
  final FocusNode? nextFocus;
  final bool autofocus;

  const DateField({
    super.key,
    required this.label,
    required this.controller,
    required this.onTap,
    this.errorText,
    this.isEnabled = true,
    this.focusNode,
    this.nextFocus,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: AppColors.black,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: isEnabled ? () {
            FocusScope.of(context).unfocus();
            onTap();
          } : null,
          child: Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.30),
                  blurRadius: 2,
                  offset: const Offset(0, 0),
                ),
              ],
              color: isEnabled ? AppColors.bgBoxColor : AppColors.bgBoxColor.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: AbsorbPointer(
              child: TextFormField(
                controller: controller,
                enabled: false,
                focusNode: focusNode,
                autofocus: autofocus,
                textInputAction: nextFocus != null ? TextInputAction.next : TextInputAction.done,
                onFieldSubmitted: (_) {
                  if (nextFocus != null) {
                    FocusScope.of(context).requestFocus(nextFocus);
                  } else {
                    FocusScope.of(context).unfocus();
                  }
                },
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: isEnabled ? AppColors.black : AppColors.fieldHintColor,
                ),
                decoration: InputDecoration(
                  hintText: 'DD/MM/YY',
                  hintStyle: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w300,
                    color: AppColors.fieldHintColor,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),

                ),
              ),
            ),
          ),
        ),
        Container(
          height: 20,
          padding: const EdgeInsets.only(top: 4),
          child: errorText != null
              ? Text(
            errorText!,
            style: GoogleFonts.inter(
              color: Colors.red,
              fontSize: 8,
              fontWeight: FontWeight.w400,
            ),
          )
              : null,
        ),
      ],
    );
  }
}