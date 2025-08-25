import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dotted_border/dotted_border.dart';

import '../../utils/app_colors.dart';
import 'file_selection_screen.dart';

class ConvertImgMainScreen extends StatefulWidget {
  const ConvertImgMainScreen({super.key});

  @override
  State<ConvertImgMainScreen> createState() => _ConvertImgMainScreenState();
}

class _ConvertImgMainScreenState extends State<ConvertImgMainScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 20, top: 20),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: Padding(
          padding: const EdgeInsets.only(top: 20),
          child: Text(
            'Convert Image',
            style: GoogleFonts.inter(
              color: AppColors.black,
              fontWeight: FontWeight.w600,
              fontSize: 20,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Center(
                child: SvgPicture.asset(
                  'assets/images/convert_image.svg',
                  height: 176,
                  width: 186,
                ),
              ),
              const SizedBox(height: 30),
              _buildFormatInfoCard(),
              const SizedBox(height: 24),
              _buildSelectFileCard(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormatInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 10,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Convert Image Format',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Easily convert images to various formats while maintaining quality, resolution and clarity.',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectFileCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 10,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select File',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          _buildDottedUploadArea(context),
        ],
      ),
    );
  }

  Widget _buildDottedUploadArea(BuildContext context) {
    return DottedBorder(
      color: AppColors.primary,
      strokeWidth: 1.5,
      dashPattern: const [5, 4],
      borderType: BorderType.RRect,
      radius: const Radius.circular(8),
      child: InkWell(
        onTap: () => _pickImages(context),
        child: Container(
          width: double.infinity,
          height: 128,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: const Color(0xFF00BCD4).withOpacity(0.05),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(
                'assets/icons/upload_file_icon.svg',
                height: 28,
                width: 36,
              ),
              const SizedBox(height: 4),
              Text(
                'Tap to choose image',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: Colors.grey,
                  fontSize: 10,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImages(BuildContext context) async {
    try {
      final List<XFile> images = await ImagePicker().pickMultiImage();
      if (images.isNotEmpty) {
        // Navigate after a brief delay
        Future.delayed(const Duration(milliseconds: 300), () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FileSelectionScreen(images: images),
            ),
          );
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking images: $e')),
      );
    }
  }
}