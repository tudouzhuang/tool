import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:toolkit/widgets/settings_widgets/locked_files_tab.dart';
import '../../utils/app_colors.dart';
import '../../widgets/custom_appbar.dart';

class LockedFilesScreen extends StatelessWidget {
  const LockedFilesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: CustomAppBar(
        title: 'locked_files'.tr,
        onBackPressed: () {
          Navigator.of(context).pop(false);
        },
      ),
      body: const LockedFilesView(searchQuery: ''),
    );
  }
}
