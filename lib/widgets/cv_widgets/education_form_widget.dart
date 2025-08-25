import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/app_colors.dart';
import '../../widgets/buttons/save_edit_delete_btns.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/cv_widgets/custom_divider.dart';

import '../date_picker_field.dart';

class EducationFormWidget extends StatefulWidget {
  final TextEditingController degreeController;
  final TextEditingController instituteController;
  final TextEditingController startDateController;
  final TextEditingController endDateController;
  final TextEditingController descriptionController;
  final bool isCompleted;
  final String? dateError;
  final FocusNode degreeFocus;
  final FocusNode instituteFocus;
  final FocusNode startDateFocus;
  final FocusNode endDateFocus;
  final FocusNode descriptionFocus;
  final Function(bool) onCompletedChanged;
  final Function(BuildContext, TextEditingController, bool) onDateSelected;
  final VoidCallback onSavePressed;

  const EducationFormWidget({
    super.key,
    required this.degreeController,
    required this.instituteController,
    required this.startDateController,
    required this.endDateController,
    required this.descriptionController,
    required this.isCompleted,
    required this.dateError,
    required this.degreeFocus,
    required this.instituteFocus,
    required this.startDateFocus,
    required this.endDateFocus,
    required this.descriptionFocus,
    required this.onCompletedChanged,
    required this.onDateSelected,
    required this.onSavePressed,
  });

  @override
  State<EducationFormWidget> createState() => _EducationFormWidgetState();
}

class _EducationFormWidgetState extends State<EducationFormWidget> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.30),
            blurRadius: 2,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Degree and Courses
            CustomTextField(
              label: 'degree_and_courses'.tr,
              hint: 'enter_your_education'.tr,
              controller: widget.degreeController,
              focusNode: widget.degreeFocus,
              nextFocus: widget.instituteFocus,
            ),
            const SizedBox(height: 16),

            // Institute
            CustomTextField(
              label: 'institute'.tr,
              hint: 'enter_your_institute'.tr,
              controller: widget.instituteController,
              focusNode: widget.instituteFocus,
              nextFocus: widget.startDateFocus,
            ),
            const SizedBox(height: 16),

            // Dates row
            Row(
              children: [
                // Start date
                Expanded(
                  child: DateField(
                    label: 'start_date'.tr,
                    controller: widget.startDateController,
                    focusNode: widget.startDateFocus,
                    onTap: () => widget.onDateSelected(
                        context, widget.startDateController, true),
                  ),
                ),
                const SizedBox(width: 20),
                // End date - only show if not completed
                if (!widget.isCompleted)
                  Expanded(
                    child: DateField(
                      label: 'end_date'.tr,
                      controller: widget.endDateController,
                      focusNode: widget.endDateFocus,
                      onTap: () => widget.onDateSelected(
                          context, widget.endDateController, false),
                      errorText: widget.dateError,
                    ),
                  ),
                if (widget.isCompleted) const Expanded(child: SizedBox()),
              ],
            ),

            // Completed checkbox
            Row(
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    value: widget.isCompleted,
                    activeColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    side: const BorderSide(
                      color: AppColors.fieldHintColor,
                    ),
                    onChanged: (value) {
                      widget.onCompletedChanged(value ?? false);
                    },
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  'continued'.tr,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: AppColors.fieldHintColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Description
            _buildDescriptionField(),
            const SizedBox(height: 20),
            const CustomDivider(),
            const SizedBox(height: 20),
            SaveButton(
              onPressed: widget.onSavePressed,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDescriptionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'description'.tr,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: AppColors.black,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'optional'.tr,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: AppColors.fieldHintColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 100,
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
          child: TextFormField(
            controller: widget.descriptionController,
            focusNode: widget.descriptionFocus,
            maxLines: 5,
            maxLength: 100,
            cursorColor: AppColors.primary,
            decoration: InputDecoration(
              hintText: 'cgpa_grade_hint'.tr,
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
              counterText: '',
            ),
          ),
        ),
      ],
    );
  }
}
