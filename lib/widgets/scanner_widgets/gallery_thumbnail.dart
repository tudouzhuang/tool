import 'dart:io';
import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';

class ThumbnailGallery extends StatelessWidget {
  final List<File> images;
  final int selectedIndex;
  final ValueChanged<int> onImageSelected;
  final ValueChanged<int>? onImageDeleted; // NEW: Delete callback
  final ScrollController scrollController;
  final VoidCallback onScrollLeft;
  final VoidCallback onScrollRight;
  final bool canScrollLeft;
  final bool canScrollRight;

  const ThumbnailGallery({
    super.key,
    required this.images,
    required this.selectedIndex,
    required this.onImageSelected,
    this.onImageDeleted, // NEW: Optional delete callback
    required this.scrollController,
    required this.onScrollLeft,
    required this.onScrollRight,
    required this.canScrollLeft,
    required this.canScrollRight,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, -4),
          ),
        ],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(26),
          topRight: Radius.circular(26),
        ),
      ),
      child: Row(
        children: [
          // Left arrow
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: Icon(
              Icons.chevron_left,
              color: canScrollLeft ? AppColors.primary : Colors.grey.shade400,
              size: 30,
            ),
            onPressed: canScrollLeft ? onScrollLeft : null,
          ),

          // Scrollable thumbnail list
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              itemCount: images.length,
              itemBuilder: (context, index) {
                return ThumbnailItem(
                  image: images[index],
                  index: index,
                  isSelected: index == selectedIndex,
                  onTap: () => onImageSelected(index),
                  onDelete: onImageDeleted != null ? () => onImageDeleted!(index) : null, // NEW: Pass delete callback
                  showDeleteButton: images.length > 1, // NEW: Only show delete if more than 1 image
                );
              },
            ),
          ),

          // Right arrow
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: Icon(
              Icons.chevron_right,
              color: (images.length > 1 && canScrollRight) ? AppColors.primary : Colors.grey.shade400,
              size: 30,
            ),
            onPressed: (images.length > 1 && canScrollRight) ? onScrollRight : null,
          ),
        ],
      ),
    );
  }
}

class ThumbnailItem extends StatelessWidget {
  final File image;
  final int index;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback? onDelete; // NEW: Delete callback
  final bool showDeleteButton; // NEW: Whether to show delete button

  const ThumbnailItem({
    super.key,
    required this.image,
    required this.index,
    required this.isSelected,
    required this.onTap,
    this.onDelete, // NEW: Optional delete callback
    this.showDeleteButton = true, // NEW: Default to showing delete button
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 74,
        height: 100,
        margin: const EdgeInsets.only(right: 10, top: 10),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Image container
            Positioned(
              top: 0,
              child: Container(
                width: 60,
                height: 74,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isSelected ? AppColors.primary : Colors.transparent,
                    width: 2,
                  ),
                  image: DecorationImage(
                    image: FileImage(image),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            // Index badge
            Positioned(
              top: 58,
              left:-8,
              child: Container(
                width: 18,
                height: 18,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
            // NEW: Delete button
            if (showDeleteButton && onDelete != null)
              Positioned(
                top: -5,
                right: 5,
                child: GestureDetector(
                  onTap: onDelete,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1),
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}