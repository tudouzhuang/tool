import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/app_colors.dart';
import '../../widgets/custom_appbar.dart';

class QrCodeDisplayScreen extends StatefulWidget {
  final String qrData;
  final String fileName;
  final String fileSize;
  final String qrId;

  const QrCodeDisplayScreen({
    super.key,
    required this.qrData,
    required this.fileName,
    required this.fileSize,
    required this.qrId,
  });

  @override
  State<QrCodeDisplayScreen> createState() => _QrCodeDisplayScreenState();
}

class _QrCodeDisplayScreenState extends State<QrCodeDisplayScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _regenerateQRCode() {
    // Navigate back to file transfer screen to generate a new QR code
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: 'File Transfer'.tr,
        onBackPressed: () {
          Navigator.of(context).pop(false);
        },
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // QR Code Container with text inside
                  Center(
                    child: Container(
                      width: 326,
                      height: 332,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // QR Code
                          SizedBox(
                            width: 190,
                            height: 190,
                            child: PrettyQrView.data(
                              data: widget.qrData,
                              decoration: const PrettyQrDecoration(
                                shape: PrettyQrSmoothSymbol(
                                  color: Color(0xFF75C8C8),
                                ),
                                image: PrettyQrDecorationImage(
                                  image:
                                      AssetImage('assets/images/app_icon.png'),
                                  position:
                                      PrettyQrDecorationImagePosition.embedded,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Text inside container
                          Text(
                            'Scan QR Code to transfer file'.tr,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),

                          // Generate code again text with link styling
                          GestureDetector(
                            onTap: _regenerateQRCode,
                            child: RichText(
                              textAlign: TextAlign.center,
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: "Can't Transfer? ",
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                      color: Colors.black54,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                  TextSpan(
                                    text: 'Generate',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.primary,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                  TextSpan(
                                    text: " Code again",
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 80,
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
