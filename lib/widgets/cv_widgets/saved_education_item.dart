import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/education_item_model.dart';
import '../../utils/app_colors.dart';
import '../../widgets/buttons/save_edit_delete_btns.dart';
import '../../widgets/cv_widgets/custom_divider.dart';

class SavedEducationItemWidget extends StatelessWidget {
  final EducationItem item;
  final int index;
  final Function(int) onEdit;
  final Function(int) onDelete;

  const SavedEducationItemWidget({
    super.key,
    required this.item,
    required this.index,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
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
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildEducationInfo(),
            const SizedBox(height: 10),
            const CustomDivider(),
            const SizedBox(height: 8),
            EditDeleteActionRow(
              onEdit: () => onEdit(index),
              onDelete: () => onDelete(index),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEducationInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.degree,
          style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.black),
        ),
        const SizedBox(height: 4),
        Text(
          item.isCompleted
              ? "${item.startDate} - Present"
              : "${item.startDate} - ${item.endDate}",
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: AppColors.saveDateColor,
          ),
        ),
      ],
    );
  }
}