import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';

class RecentsView extends StatelessWidget {
  const RecentsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 14),
        // Recent Documents list
        _buildRecentDocumentItem(
          context,
          documentName: 'Document',
          date: '23/02/25',
          time: '6:05pm',
          size: '3.4 MB',
        ),
      ],
    );
  }

  Widget _buildRecentDocumentItem(
    BuildContext context, {
    required String documentName,
    required String date,
    required String time,
    required String size,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.16),
            blurRadius: 4,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Document thumbnail
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                width: 50,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Center(
                  child: Image.asset(
                    'assets/images/doc.png',
                    fit: BoxFit.fill,
                  ),
                ),
              ),
            ),

            // Vertical Divider (full height)
            Container(
              width: 1,
              color: Colors.grey.shade300,
            ),

            const SizedBox(width: 12),

            // Document info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    documentName,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$date | $time | $size',
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.w400,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),

            // More options icon
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: SvgPicture.asset(
                'assets/icons/more_icon.svg',
                height: 16,
                width: 16,
              ),
            )
          ],
        ),
      ),
    );
  }
}
