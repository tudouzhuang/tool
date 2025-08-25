import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_snackbar.dart';
import '../../widgets/buttons/save_edit_delete_btns.dart';
import '../../provider/user_provider.dart';
import '../../widgets/cv_widgets/custom_divider.dart';

class CareerObjectivesPage extends StatefulWidget {
  const CareerObjectivesPage({
    super.key,
  });

  @override
  State<CareerObjectivesPage> createState() => CareerObjectivesPageState();
}

class CareerObjectivesPageState extends State<CareerObjectivesPage> {
  final TextEditingController _objectiveController = TextEditingController();

  bool hasObjective = false;
  String savedObjective = '';

  @override
  void initState() {
    super.initState();
    // Check if objective already exists in provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      if (userProvider.userData.careerObjective != null &&
          userProvider.userData.careerObjective!.isNotEmpty) {
        setState(() {
          savedObjective = userProvider.userData.careerObjective!;
          hasObjective = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _objectiveController.dispose();
    super.dispose();
  }

  // Add validation method
  bool validate() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    // Check if user has saved objective
    if (hasObjective && savedObjective.isNotEmpty) {
      return true;
    }

    // Check if there's objective in provider (in case it was loaded from edit data)
    if (userProvider.userData.careerObjective != null &&
        userProvider.userData.careerObjective!.isNotEmpty) {
      return true;
    }

    AppSnackBar.show(context,
        message: 'please_add_career_objective_before_proceeding'.tr);

    return false;
  }

  void _saveObjective() {
    if (_objectiveController.text.trim().isEmpty) {
      // Show validation message for empty field
      AppSnackBar.show(context, message: 'please_enter_career_objective'.tr);
      return;
    }

    // Get user provider
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    setState(() {
      savedObjective = _objectiveController.text.trim();
      hasObjective = true;

      // Update provider with new objective
      userProvider.updateCareerObjective(savedObjective);

      // Clear form field
      _objectiveController.clear();
    });
  }

  void _editObjective() {
    setState(() {
      _objectiveController.text = savedObjective;
      hasObjective = false;
    });
  }

  void _deleteObjective() {
    // Get user provider
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    setState(() {
      // Clear saved career objective
      savedObjective = '';
      hasObjective = false;

      // Update provider with empty objective
      userProvider.updateCareerObjective('');
    });

    // Show delete confirmation message
    AppSnackBar.show(context, message: 'career_objective_deleted'.tr);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 26.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),

                    // Show objective form or saved objective detail
                    hasObjective
                        ? _buildSavedObjective()
                        : _buildObjectiveForm(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSavedObjective() {
    // Using the new SavedDetailContainer widget
    return SavedDetailContainer(
      title: 'objective'.tr,
      content: savedObjective,
      onEdit: _editObjective,
      onDelete: _deleteObjective,
    );
  }

  Widget _buildObjectiveForm() {
    return Container(
      height: 332,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.30),
            blurRadius: 2,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.only(left: 18, right: 18, top: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Objective field with expanded height
            _buildObjectiveField(),
            const SizedBox(height: 32),
            const CustomDivider(),

            const SizedBox(height: 20),

            // Using the new SaveButton widget
            SaveButton(onPressed: _saveObjective),
          ],
        ),
      ),
    );
  }

  // Custom objective field with larger height
  // Custom objective field with larger height
  Widget _buildObjectiveField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'career_objective_profile_summary'.tr,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: AppColors.black,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          height: 180,
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.30),
                blurRadius: 2,
                offset: const Offset(0, 0),
              ),
            ],
            color: AppColors.bgBoxColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Theme(
            data: Theme.of(context).copyWith(
              textSelectionTheme: TextSelectionThemeData(
                cursorColor: AppColors.primary,
                selectionHandleColor: AppColors.primary,
                selectionColor: AppColors.primary.withOpacity(0.3),
              ),
            ),
            child: TextFormField(
              controller: _objectiveController,
              maxLines: 8,
              maxLength: 200,
              cursorColor: AppColors.primary,
              decoration: InputDecoration(
                hintText: 'type_career_objectives_hint'.tr,
                hintStyle: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w300,
                  color: AppColors.fieldHintColor,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                counterText: '',
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}