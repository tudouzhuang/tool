import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AuthTitleWidget extends StatelessWidget {
  final String title;

  const AuthTitleWidget({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: Colors.black,
        height: 1.2,
      ),
    );
  }
}