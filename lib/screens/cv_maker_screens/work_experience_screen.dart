import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart'; // Add this import for .tr extension
import '../../models/work_experience_model.dart';
import '../../provider/work_experience_provider.dart';
import '../../utils/app_colors.dart';
import '../../widgets/buttons/add_another_button.dart';
import '../../widgets/buttons/save_edit_delete_btns.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/cv_widgets/custom_divider.dart';
import '../../widgets/date_picker_field.dart';

class WorkExperiencePage extends StatefulWidget {
  final List<Map<String, dynamic>>? initialData;

  const WorkExperiencePage({
    this.initialData,
    super.key,
  });

  @override
  State<WorkExperiencePage> createState() => _WorkExperiencePageState();
}

class _WorkExperiencePageState extends State<WorkExperiencePage> {
  final TextEditingController _positionController = TextEditingController();
  final TextEditingController _companyController = TextEditingController();
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();
  final TextEditingController _projectController = TextEditingController();
  final TextEditingController _projectUrlController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  // Add FocusNodes for better focus management
  final FocusNode _positionFocusNode = FocusNode();
  final FocusNode _companyFocusNode = FocusNode();
  final FocusNode _startDateFocusNode = FocusNode();
  final FocusNode _endDateFocusNode = FocusNode();
  final FocusNode _projectFocusNode = FocusNode();
  final FocusNode _projectUrlFocusNode = FocusNode();
  final FocusNode _descriptionFocusNode = FocusNode();

  bool validate() {
    final provider =
        Provider.of<WorkExperienceProvider>(context, listen: false);
    return provider.workExperienceItems.isNotEmpty;
  }

  bool isCurrent = false;
  bool showForm = false;
  List<String> projectsList = [];
  List<String> projectUrlsList = [];
  DateTime? startDate;
  DateTime? endDate;
  String? dateError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  void _loadInitialData() {
    if (widget.initialData != null && widget.initialData!.isNotEmpty) {
      final workExpProvider =
          Provider.of<WorkExperienceProvider>(context, listen: false);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Clear any existing data
        workExpProvider.clearWorkExperienceItems();

        // Load the initial data into the provider
        for (var item in widget.initialData!) {
          workExpProvider.addWorkExperience(
            WorkExperienceItem(
              position: item['position'] ?? '',
              company: item['company'] ?? '',
              startDate: item['startDate'] ?? '',
              endDate: item['endDate'] ?? '',
              projects: List<String>.from(item['projects'] ?? []),
              projectUrls: List<String>.from(item['projectUrls'] ?? []),
              description: item['description'] ?? '',
              isCurrent: item['isCurrent'] ?? false,
            ),
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _positionController.dispose();
    _companyController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    _projectController.dispose();
    _projectUrlController.dispose();
    _descriptionController.dispose();

    // Dispose focus nodes
    _positionFocusNode.dispose();
    _companyFocusNode.dispose();
    _startDateFocusNode.dispose();
    _endDateFocusNode.dispose();
    _projectFocusNode.dispose();
    _projectUrlFocusNode.dispose();
    _descriptionFocusNode.dispose();

    super.dispose();
  }

  void _selectDate(BuildContext context, TextEditingController controller,
      bool isStartDate) async {
    // Unfocus any currently focused field before opening date picker
    FocusScope.of(context).unfocus();

    // Add a small delay to ensure focus is properly removed
    await Future.delayed(const Duration(milliseconds: 100));

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? DateTime.now() : (startDate ?? DateTime.now()),
      firstDate: DateTime(1950),
      lastDate: DateTime(2100),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary, // Purple header
              onPrimary: Colors.white, // Header text color
              onSurface: Colors.black, // Body text color
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary, // Button text color
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      if (isStartDate) {
        startDate = picked;
        // If end date exists and is before new start date, clear it
        if (endDate != null && endDate!.isBefore(picked)) {
          endDate = null;
          _endDateController.clear();
          setState(() {
            dateError = null;
          });
        }
      } else {
        endDate = picked;
        // Validate that end date is after start date
        if (startDate != null && picked.isBefore(startDate!)) {
          setState(() {
            dateError = 'end_date_error'.tr;
          });
          return;
        } else {
          setState(() {
            dateError = null;
          });
        }
      }

      // Format date as DD/MM/YY to match the UI design
      setState(() {
        controller.text =
            "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year.toString().substring(2)}";
      });

      // After setting the date, ensure no field gets focus
      WidgetsBinding.instance.addPostFrameCallback((_) {
        FocusScope.of(context).unfocus();
      });
    }
  }

  void _addProject() {
    if (_projectController.text.isEmpty) return;

    setState(() {
      projectsList.add(_projectController.text);
      projectUrlsList
          .add(_projectUrlController.text); // Make sure this is being added
      _projectController.clear();
      _projectUrlController.clear();
    });

    // Clear focus after adding project
    _projectFocusNode.unfocus();
    _projectUrlFocusNode.unfocus();
  }

  void _removeProject(int index) {
    setState(() {
      projectsList.removeAt(index);
      projectUrlsList.removeAt(index);
    });
  }

  void _saveWorkExperience(BuildContext context) {
    if (_positionController.text.isEmpty || _companyController.text.isEmpty) {
      return;
    }

    // Additional validation for dates
    if (!isCurrent &&
        (_startDateController.text.isEmpty ||
            _endDateController.text.isEmpty)) {
      return;
    }

    // Validate end date is after start date if both exist
    if (!isCurrent &&
        startDate != null &&
        endDate != null &&
        endDate!.isBefore(startDate!)) {
      setState(() {
        dateError = 'end_date_error'.tr;
      });
      return;
    }

    final provider =
        Provider.of<WorkExperienceProvider>(context, listen: false);

    provider.addWorkExperience(
      WorkExperienceItem(
        position: _positionController.text,
        company: _companyController.text,
        startDate: _startDateController.text,
        endDate: isCurrent ? 'present'.tr : _endDateController.text,
        projects: projectsList,
        projectUrls: projectUrlsList,
        description: _descriptionController.text,
        isCurrent: isCurrent,
      ),
    );

    setState(() {
      showForm = false;
      _positionController.clear();
      _companyController.clear();
      _startDateController.clear();
      _endDateController.clear();
      _projectController.clear();
      _projectUrlController.clear();
      _descriptionController.clear();
      projectsList = [];
      projectUrlsList = [];
      isCurrent = false;
      startDate = null;
      endDate = null;
      dateError = null;
    });

    // Clear all focus after saving
    FocusScope.of(context).unfocus();
  }

  void _editWorkExperience(BuildContext context, int index) {
    final provider =
        Provider.of<WorkExperienceProvider>(context, listen: false);
    final item = provider.workExperienceItems[index];

    // Parse the dates when editing
    final startDateParts = item.startDate.split('/');
    if (startDateParts.length == 3) {
      startDate = DateTime(
        int.parse('20${startDateParts[2]}'), // Assuming 20XX format for years
        int.parse(startDateParts[1]),
        int.parse(startDateParts[0]),
      );
    }

    if (!item.isCurrent && item.endDate != 'Present') {
      final endDateParts = item.endDate.split('/');
      if (endDateParts.length == 3) {
        endDate = DateTime(
          int.parse('20${endDateParts[2]}'), // Assuming 20XX format for years
          int.parse(endDateParts[1]),
          int.parse(endDateParts[0]),
        );
      }
    }

    setState(() {
      _positionController.text = item.position;
      _companyController.text = item.company;
      _startDateController.text = item.startDate;
      _endDateController.text = item.isCurrent ? '' : item.endDate;
      projectsList = List.from(item.projects);
      projectUrlsList = List.from(item.projectUrls ?? []);
      _descriptionController.text = item.description;
      isCurrent = item.isCurrent;
      showForm = true;
      dateError = null;
    });

    provider.deleteWorkExperience(index);
  }

  void _deleteWorkExperience(BuildContext context, int index) {
    final provider =
        Provider.of<WorkExperienceProvider>(context, listen: false);
    provider.deleteWorkExperience(index);
  }

  void _toggleForm() {
    setState(() {
      showForm = !showForm;

      if (showForm) {
        _positionController.clear();
        _companyController.clear();
        _startDateController.clear();
        _endDateController.clear();
        _projectController.clear();
        _projectUrlController.clear();
        _descriptionController.clear();
        projectsList = [];
        projectUrlsList = [];
        isCurrent = false;
        startDate = null;
        endDate = null;
        dateError = null;
      }
    });

    // Clear focus when toggling form
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WorkExperienceProvider>(
      builder: (context, provider, child) {
        final workExperienceItems = provider.workExperienceItems;
        final hasExperience = workExperienceItems.isNotEmpty;

        return Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding:
                      const EdgeInsets.only(left: 26, right: 26, bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),

                      // Form is shown only when showForm is true
                      if (showForm) _buildWorkExperienceForm(context),

                      // Display saved work experience items only when form is not shown
                      if (hasExperience && !showForm) ...[
                        for (int i = 0; i < workExperienceItems.length; i++)
                          _buildSavedWorkExperience(
                              context, workExperienceItems[i], i),
                        const SizedBox(height: 16),
                      ],

                      // Add another work experience button (only shown when form is not visible)
                      if (hasExperience && !showForm)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          child: AddAnotherButton(
                            text: 'add_another_experience'.tr,
                            onPressed: _toggleForm,
                          ),
                        ),

                      // Show form by default if no work experience items yet and form is not already shown
                      if (!hasExperience && !showForm)
                        _buildWorkExperienceForm(context),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSavedWorkExperience(
      BuildContext context, WorkExperienceItem item, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
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
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Position
            Text(
              item.position,
              style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.black),
            ),
            const SizedBox(height: 4),

            // Date information
            Text(
              item.isCurrent
                  ? "${item.startDate} - ${'present'.tr}"
                  : "${item.startDate} - ${item.endDate}",
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: AppColors.saveDateColor,
              ),
            ),

            const SizedBox(height: 10),
            const CustomDivider(),

            const SizedBox(height: 8),

            // Projects list with URLs if available
            if (item.projects.isNotEmpty) ...[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'projects'.tr,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  for (int i = 0; i < item.projects.length; i++)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "• ",
                              style: GoogleFonts.urbanist(
                                fontSize: 14,
                                color: const Color(0xFFB5B5B8),
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.projects[i],
                                    style: GoogleFonts.urbanist(
                                      fontSize: 12,
                                      color: const Color(0xFFB5B5B8),
                                    ),
                                  ),
                                  if (i < item.projectUrls.length &&
                                      item.projectUrls[i].isNotEmpty)
                                    Text(
                                      item.projectUrls[i],
                                      style: GoogleFonts.urbanist(
                                        fontSize: 12,
                                        color: Colors.blue,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                      ],
                    ),
                  const SizedBox(height: 8),
                ],
              ),
            ],

            // Edit/Delete buttons
            EditDeleteActionRow(
              onEdit: () => _editWorkExperience(context, index),
              onDelete: () => _deleteWorkExperience(context, index),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkExperienceForm(BuildContext context) {
    return Container(
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
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Position
            CustomTextField(
              label: 'position'.tr,
              hint: 'enter_position'.tr,
              controller: _positionController,
              focusNode: _positionFocusNode,
            ),
            const SizedBox(height: 16),

            // Company
            CustomTextField(
              label: 'company_name'.tr,
              hint: 'enter_company'.tr,
              controller: _companyController,
              focusNode: _companyFocusNode,
            ),
            const SizedBox(height: 16),

            // Dates row
            Row(
              children: [
                // Start date
                Expanded(
                  child: DateField(
                    label: 'start_date'.tr,
                    controller: _startDateController,
                    focusNode: _startDateFocusNode,
                    onTap: () =>
                        _selectDate(context, _startDateController, true),
                  ),
                ),
                const SizedBox(width: 20),
                // End date - only show if not current job
                if (!isCurrent)
                  Expanded(
                    child: DateField(
                      label: 'end_date'.tr,
                      controller: _endDateController,
                      focusNode: _endDateFocusNode,
                      onTap: () =>
                          _selectDate(context, _endDateController, false),
                      errorText: dateError,
                    ),
                  ),
                if (isCurrent) const Expanded(child: SizedBox()),
              ],
            ),
            const SizedBox(height: 16),

            // Current job checkbox
            Row(
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    value: isCurrent,
                    activeColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    side: const BorderSide(
                      color: AppColors.fieldHintColor,
                    ),
                    onChanged: (value) {
                      setState(() {
                        isCurrent = value ?? false;
                        if (isCurrent) {
                          // Clear end date when marking as current
                          _endDateController.clear();
                          endDate = null;
                          dateError = null;
                          // Clear focus from end date field
                          _endDateFocusNode.unfocus();
                        }
                      });
                    },
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  'current'.tr,
                  style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: AppColors.fieldHintColor),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'projects'.tr,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: AppColors.black,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Input field for adding a new project
                Column(
                  children: [
                    // Project name field
                    Container(
                      width: double.infinity,
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
                          controller: _projectController,
                          focusNode: _projectFocusNode,
                          cursorColor: AppColors.primary,
                          decoration: InputDecoration(
                            hintText: 'project_name_hint'.tr,
                            hintStyle: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w300,
                              color: AppColors.fieldHintColor,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Project URL field with add button
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Container(
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
                                  selectionColor:
                                      AppColors.primary.withOpacity(0.3),
                                ),
                              ),
                              child: TextFormField(
                                controller: _projectUrlController,
                                focusNode: _projectUrlFocusNode,
                                cursorColor: AppColors.primary,
                                decoration: InputDecoration(
                                  hintText: 'project_url_hint'.tr,
                                  hintStyle: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w300,
                                    color: AppColors.fieldHintColor,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: _addProject,
                          child: Container(
                            height: 45,
                            width: 45,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  AppColors.gradientStart,
                                  AppColors.gradientEnd,
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.add,
                              color: AppColors.white,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Display added projects
                    if (projectsList.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7F7F7),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: projectsList.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12.0,
                                vertical: 8.0,
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    "• ",
                                    style: GoogleFonts.urbanist(
                                      fontSize: 14,
                                      color: const Color(0xFFB5B5B8),
                                    ),
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          projectsList[index],
                                          style: GoogleFonts.urbanist(
                                            fontSize: 12,
                                            color: const Color(0xFFB5B5B8),
                                          ),
                                        ),
                                        if (projectUrlsList[index].isNotEmpty)
                                          Text(
                                            projectUrlsList[index],
                                            style: GoogleFonts.urbanist(
                                              fontSize: 12,
                                              color: Colors.blue,
                                              decoration:
                                                  TextDecoration.underline,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => _removeProject(index),
                                    child: const Icon(
                                      Icons.close,
                                      size: 16,
                                      color: Color(0xFFC74A4A),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Description
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'description'.tr,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: AppColors.black,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'optional'.tr,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w300,
                        color: AppColors.fieldHintColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  height: 148,
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
                      controller: _descriptionController,
                      focusNode: _descriptionFocusNode,
                      cursorColor: AppColors.primary,
                      maxLines: 5,
                      maxLength: 150,
                      decoration: InputDecoration(
                        hintText: 'description_hint'.tr,
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
            ),
            const SizedBox(height: 20),
            const CustomDivider(),

            const SizedBox(height: 20),

            SaveButton(
              onPressed: () => _saveWorkExperience(context),
            ),
          ],
        ),
      ),
    );
  }
}
