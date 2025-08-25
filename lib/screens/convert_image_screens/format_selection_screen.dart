import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:toolkit/widgets/custom_appbar.dart';
import 'dart:io';
import '../../utils/app_colors.dart';
import '../../utils/app_snackbar.dart';
import '../../widgets/buttons/gradient_btn.dart';
import 'save_screen.dart';

class SelectFormatScreen extends StatefulWidget {
  final List<File> selectedImages;

  const SelectFormatScreen({super.key, required this.selectedImages});

  @override
  State<SelectFormatScreen> createState() => _SelectFormatScreenState();
}

class _SelectFormatScreenState extends State<SelectFormatScreen> {
  String? selectedFormat;

  String get fileName => widget.selectedImages.first.path.split('/').last;

  String get fileSize {
    double totalSizeBytes = widget.selectedImages
        .fold(0.0, (sum, file) => sum + file.lengthSync());
    return (totalSizeBytes / (1024 * 1024)).toStringAsFixed(2);
  }

  String get formattedDate {
    final modifiedDate = widget.selectedImages.first.lastModifiedSync();
    return '${modifiedDate.day}/${modifiedDate.month}/${modifiedDate.year.toString().substring(2)}';
  }

  String get formattedTime {
    final modifiedDate = widget.selectedImages.first.lastModifiedSync();
    return '${modifiedDate.hour}:${modifiedDate.minute.toString().padLeft(2, '0')}${modifiedDate.hour < 12 ? 'am' : 'pm'}';
  }

  Future<void> _convertImages() async {
    if (selectedFormat == null) {
      AppSnackBar.show(context, message: 'select_format_first'.tr);
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SaveScreen(
          selectedImages: widget.selectedImages,
          selectedFormat: selectedFormat!,
        ),
      ),
    );

    if (result == true) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(title: 'convert_images'.tr),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Text(
              '${'selected_files'.tr} (${widget.selectedImages.length})',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 10),

            if (widget.selectedImages.length == 1)
              _buildSingleFileContainer()
            else
              _buildMultipleFilesContainer(),

            const SizedBox(height: 30),
            Text(
              'select_format'.tr,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                _buildFormatOption('word'.tr, 'assets/icons/word_icon.svg'),
                const SizedBox(
                  width: 16,
                ),
                _buildFormatOption(
                  'pdf'.tr,
                  'assets/icons/convert_pdf.svg',
                ),
              ],
            ),
            const Spacer(),
            CustomGradientButton(
              text: 'convert'.tr,
              onPressed: _convertImages,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSingleFileContainer() {
    final image = widget.selectedImages.first;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                width: 50,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  image: DecorationImage(
                    image: FileImage(image),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            Container(width: 1, color: Colors.grey.shade300),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      fileName,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$formattedDate | $formattedTime | $fileSize MB',
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.w400,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Icon(
                Icons.more_vert,
                size: 16,
                color: Colors.grey[600],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildMultipleFilesContainer() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ...widget.selectedImages.take(3).map((image) =>
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        image: DecorationImage(
                          image: FileImage(image),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                ),
                if (widget.selectedImages.length > 3)
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: Colors.grey.shade200,
                    ),
                    child: Center(
                      child: Text(
                        '+${widget.selectedImages.length - 3}',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '${widget.selectedImages.length} images selected',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'total_size $fileSize mb'.tr,
              style: GoogleFonts.inter(
                fontSize: 9,
                fontWeight: FontWeight.w400,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormatOption(String label, String iconPath) {
    final isSelected = selectedFormat == label;
    return GestureDetector(
      onTap: () => setState(() => selectedFormat = label),
      child: Column(
        children: [
          Container(
            width: 78,
            height: 78,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.white,
              border: isSelected
                  ? Border.all(color: AppColors.primary, width: 2)
                  : null,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.16),
                  blurRadius: 2,
                ),
              ],
            ),
            child: Center(
              child: SvgPicture.asset(
                iconPath,
                width: 30,
                height: 34,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: isSelected ? AppColors.primary : Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}