import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../utils/app_colors.dart';

/// A reusable Save button widget used across the app
class SaveButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String text;
  final double width;
  final double height;

  const SaveButton({
    super.key,
    required this.onPressed,
    this.text = 'save',
    this.width = 88,
    this.height = 36,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: Container(
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
        child: SizedBox(
          width: width,
          height: height,
          child: ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.bgBoxColor,
              foregroundColor: AppColors.black,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              text.tr,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ActionButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String text;
  final double width;
  final double height;

  const ActionButton({
    super.key,
    required this.onPressed,
    required this.text,
    this.width = 88,
    this.height = 36,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
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
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(
          text.tr,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.black,
          ),
        ),
      ),
    );
  }
}

/// A reusable Edit/Delete action row widget used across the app
class EditDeleteActionRow extends StatelessWidget {
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final double buttonWidth;
  final double buttonHeight;

  const EditDeleteActionRow({
    super.key,
    required this.onEdit,
    required this.onDelete,
    this.buttonWidth = 88,
    this.buttonHeight = 36,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        ActionButton(
          onPressed: onEdit,
          text: 'edit',
          width: buttonWidth,
          height: buttonHeight,
        ),
        ActionButton(
          onPressed: onDelete,
          text: 'delete',
          width: buttonWidth,
          height: buttonHeight,
        ),
      ],
    );
  }
}

class SavedDetailContainer extends StatelessWidget {
  final String title;
  final String content;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool showTitle;

  const SavedDetailContainer({
    super.key,
    required this.title,
    required this.content,
    required this.onEdit,
    required this.onDelete,
    this.showTitle = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.30),
            blurRadius: 2,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Title (optional)
          if (showTitle)
            Text(
              title.tr,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          if (showTitle) const SizedBox(height: 8),

          // Content with minimum height
          Container(
            constraints: const BoxConstraints(minHeight: 60),
            child: Text(
              content.tr,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ),

          // Divider with consistent spacing
          const SizedBox(height: 10),
          const Divider(
            height: 1,
            thickness: 1,
            color: Color(0xFFE0E0E0),
          ),
          const SizedBox(height: 10),

          // Edit/Delete buttons row
          EditDeleteActionRow(
            onEdit: onEdit,
            onDelete: onDelete,
          ),
        ],
      ),
    );
  }
}