import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../screens/scanner_screens/document_edit_screen.dart';
import '../../utils/app_colors.dart';


class FilterSelector extends StatelessWidget {
  final List<String> filterOptions;
  final Function(String) onFilterSelected;
  final Map<String, File> filterPreviews;
  final bool previewsReady;

  const FilterSelector({
    super.key,
    required this.filterOptions,
    required this.onFilterSelected,
    required this.filterPreviews,
    required this.previewsReady,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<FilterProvider>(
      builder: (context, filterProvider, child) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: filterOptions.map((filter) {
              final isSelected = filter == filterProvider.selectedFilter;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: GestureDetector(
                  onTap: () => onFilterSelected(filter),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: ClipOval(
                          child: previewsReady && filterPreviews.containsKey(filter)
                              ? Image.file(
                            filterPreviews[filter]!,
                            fit: BoxFit.cover,
                          )
                              : Container(
                            color: Colors.grey.shade200,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        filter,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w400,
                          color: isSelected
                              ? AppColors.primary
                              : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}