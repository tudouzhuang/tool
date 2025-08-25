import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/app_colors.dart'; // adjust path as needed

class CustomTextField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController? controller;
  final TextInputType keyboardType;
  final Function(String)? onChanged;
  final String? Function(String?)? validator;
  final bool isRequired;
  final FocusNode? focusNode;
  final FocusNode? nextFocus;
  final TextInputAction? textInputAction;
  final bool autofocus;

  const CustomTextField({
    super.key,
    required this.label,
    required this.hint,
    this.controller,
    this.onChanged,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.isRequired = false,
    this.focusNode,
    this.nextFocus,
    this.textInputAction,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: AppColors.black,
              ),
            ),
            if (isRequired)
              Padding(
                padding: const EdgeInsets.only(left: 4.0),
                child: Text(
                  '*',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Colors.red,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.30),
                blurRadius: 2,
                offset: const Offset(0, 0),
              ),
            ],
            color: AppColors.bgBoxColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Theme(
            data: Theme.of(context).copyWith(
              textSelectionTheme: TextSelectionThemeData(
                cursorColor: AppColors.primary,
                selectionColor: AppColors.primary.withOpacity(0.3),
                selectionHandleColor: AppColors.primary,
              ),
            ),
            child: TextFormField(
              autofocus: autofocus,
              focusNode: focusNode,
              textInputAction: textInputAction ??
                  (nextFocus != null
                      ? TextInputAction.next
                      : TextInputAction.done),
              onFieldSubmitted: (_) {
                if (nextFocus != null) {
                  FocusScope.of(context).requestFocus(nextFocus);
                } else {
                  FocusScope.of(context).unfocus();
                }
              },
              onChanged: onChanged,
              controller: controller,
              keyboardType: keyboardType,
              validator: validator,
              textCapitalization: TextCapitalization.sentences,
              cursorColor: AppColors.primary,
              decoration: InputDecoration(
                hintText: hint,
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
                errorStyle: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.red,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
