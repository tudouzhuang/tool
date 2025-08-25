import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:get/get.dart'; // Add this import for .tr extension
import '../../utils/app_colors.dart';

class PersonalInfoImagePicker extends StatelessWidget {
  final File? imageFile;
  final Function(File) onImagePicked;

  const PersonalInfoImagePicker({
    super.key,
    required this.imageFile,
    required this.onImagePicked,
  });

  Future<void> _pickImage(BuildContext context) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      onImagePicked(File(pickedFile.path));
    }
  }

  @override
  Widget build(BuildContext context) {
    return imageFile == null
        ? _buildUploadPhoto(context)
        : _buildProfileImageWithEdit(context);
  }

  Widget _buildUploadPhoto(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
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
        padding: const EdgeInsets.all(10.0),
        child: Center(
          child: GestureDetector(
            onTap: () => _pickImage(context),
            child: Row(
              children: [
                Container(
                  width: 96,
                  height: 78,
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.16),
                        blurRadius: 2,
                        offset: const Offset(0, 0),
                      )
                    ],
                    color: AppColors.bgBoxColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child:
                  const Icon(Icons.add, color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 26),
                Text(
                  'click_here_to_upload_photo'.tr, // Localized text
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileImageWithEdit(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: () => _pickImage(context),
        child: Stack(
          children: [
            Container(
              width: 98,
              height: 98,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                image: DecorationImage(
                  image: FileImage(imageFile!),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Positioned(
              bottom: 6,
              right: 8,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Center(
                  child: SvgPicture.asset(
                    'assets/icons/edit_profile_icon.svg',
                    width: 10,
                    height: 10,
                    color: AppColors.white,
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