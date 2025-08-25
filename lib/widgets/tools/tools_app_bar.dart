import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ToolsAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onBackPressed;
  final List<Widget>? actions;

  const ToolsAppBar({
    super.key,
    required this.title,
    this.onBackPressed,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      scrolledUnderElevation: 0,
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.only(top: 20,left: 18),
        child: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: onBackPressed ?? () => Navigator.pop(context),
        ),
      ),
      title: Padding(
        padding: const EdgeInsets.only(top: 20),
        child: Text(
          title,
          style: GoogleFonts.inter(
            color: Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
      ),
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
