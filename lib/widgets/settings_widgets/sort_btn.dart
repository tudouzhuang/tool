import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart'; // Add this import for .tr extension

class SortButton extends StatelessWidget {
  final String currentSort;
  final Function(String) onSortSelected;

  const SortButton({
    super.key,
    required this.currentSort,
    required this.onSortSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.16),
            blurRadius: 4,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      child: SizedBox(
        height: 26,
        width: 82,
        child: PopupMenuButton<String>(
          onSelected: (value) {
            onSortSelected(value);
          },
          itemBuilder: (BuildContext context) {
            return [
              _buildMenuItem(
                  value: 'Name',
                  text: 'name'.tr,
                  isSelected: currentSort == 'Name'),
              PopupMenuItem<String>(
                enabled: false,
                height: 10,
                padding: EdgeInsets.zero,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Divider(
                      height: 1,
                      thickness: 1,
                      color: Colors.grey[300],
                    ),
                  ),
                ),
              ),
              _buildMenuItem(
                  value: 'Date',
                  text: 'date'.tr,
                  isSelected: currentSort == 'Date'),
            ];
          },
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          color: Colors.white,
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'sort'.tr,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(width: 4),
                SvgPicture.asset(
                  'assets/icons/otp_num_dropdown_icon.svg',
                  height: 6,
                  width: 6,
                  color: Colors.grey[600],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  PopupMenuItem<String> _buildMenuItem({
    required String value,
    required String text,
    required bool isSelected,
  }) {
    return PopupMenuItem<String>(
      value: value,
      child: SizedBox(
        width: double.infinity,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w300,
                color: const Color(0xFF8E8E93),
              ),
            ),
            if (isSelected)
              const Positioned(
                right: 0,
                child: Icon(
                  Icons.check,
                  size: 16,
                  color: Color(0xFF8E8E93),
                ),
              ),
          ],
        ),
      ),
    );
  }
}