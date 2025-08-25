import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import '../../models/education_item_model.dart';
import '../../provider/education_provider.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_snackbar.dart';
import '../../widgets/buttons/add_another_button.dart';
import '../../widgets/cv_widgets/education_form_widget.dart';
import '../../widgets/cv_widgets/saved_education_item.dart';

class EducationDetailPage extends StatefulWidget {
  final List<Map<String, dynamic>>? initialData;

  const EducationDetailPage({super.key, this.initialData});

  @override
  State<EducationDetailPage> createState() => EducationDetailPageState();
}

class EducationDetailPageState extends State<EducationDetailPage> {
  final TextEditingController _degreeController = TextEditingController();
  final TextEditingController _instituteController = TextEditingController();
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  bool isCompleted = false;
  bool showForm = false;
  int? editingIndex;
  DateTime? startDate;
  DateTime? endDate;
  String? dateError;
  final FocusNode _degreeFocus = FocusNode();
  final FocusNode _instituteFocus = FocusNode();
  final FocusNode _startDateFocus = FocusNode();
  final FocusNode _endDateFocus = FocusNode();
  final FocusNode _descriptionFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  void _loadInitialData() {
    if (widget.initialData != null && widget.initialData!.isNotEmpty) {
      final educationProvider = Provider.of<EducationProvider>(context, listen: false);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        educationProvider.clearEducationItems();

        for (var item in widget.initialData!) {
          educationProvider.addEducationItem(EducationItem(
            degree: item['degree'] ?? '',
            institute: item['institute'] ?? '',
            startDate: item['startDate'] ?? '',
            endDate: item['endDate'] ?? '',
            description: item['description'] ?? '',
            isCompleted: item['isCompleted'] ?? false,
          ));
        }
      });
    }
  }

  @override
  void dispose() {
    _degreeController.dispose();
    _instituteController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    _descriptionController.dispose();
    _degreeFocus.dispose();
    _instituteFocus.dispose();
    _startDateFocus.dispose();
    _endDateFocus.dispose();
    _descriptionFocus.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, TextEditingController controller,
      FocusNode focusNode, bool isStartDate) async {
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
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
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
        if (endDate != null && endDate!.isBefore(picked)) {
          endDate = null;
          _endDateController.clear();
          setState(() {
            dateError = null;
          });
        }
      } else {
        endDate = picked;
        if (startDate != null && picked.isBefore(startDate!)) {
          setState(() {
            dateError = 'end_date_after_start_date'.tr;
          });
          return;
        } else {
          setState(() {
            dateError = null;
          });
        }
      }

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
  void _saveEducation() {
    if (!isCompleted &&
        startDate != null &&
        endDate != null &&
        endDate!.isBefore(startDate!)) {
      setState(() {
        dateError = 'end_date_after_start_date'.tr;
      });
      return;
    }

    if (_degreeController.text.trim().isEmpty) {
      AppSnackBar.show(context, message: 'enter_degree_title'.tr);
      return;
    }

    if (_instituteController.text.trim().isEmpty) {
      AppSnackBar.show(context, message: 'enter_institute_name'.tr);
      return;
    }

    if (_startDateController.text.trim().isEmpty) {
      AppSnackBar.show(context, message: 'select_start_date'.tr);
      return;
    }

    if (!isCompleted && _endDateController.text.trim().isEmpty) {
      AppSnackBar.show(context, message: 'select_end_date'.tr);
      return;
    }

    final educationProvider =
    Provider.of<EducationProvider>(context, listen: false);
    final newEducation = EducationItem(
      degree: _degreeController.text.trim(),
      institute: _instituteController.text.trim(),
      startDate: _startDateController.text.trim(),
      endDate: isCompleted ? '' : _endDateController.text.trim(),
      description: _descriptionController.text.trim(),
      isCompleted: isCompleted,
    );

    if (editingIndex != null) {
      educationProvider.updateEducationItem(editingIndex!, newEducation);
      AppSnackBar.show(context, message: 'education_updated_successfully'.tr);
    } else {
      educationProvider.addEducationItem(newEducation);
      AppSnackBar.show(context, message: 'education_added_successfully'.tr);
    }

    _clearForm();
  }

  void _editEducation(int index) {
    final educationProvider =
    Provider.of<EducationProvider>(context, listen: false);
    final item = educationProvider.educationItems[index];

    final startDateParts = item.startDate.split('/');
    if (startDateParts.length == 3) {
      startDate = DateTime(
        int.parse('20${startDateParts[2]}'),
        int.parse(startDateParts[1]),
        int.parse(startDateParts[0]),
      );
    }

    if (item.endDate.isNotEmpty) {
      final endDateParts = item.endDate.split('/');
      if (endDateParts.length == 3) {
        endDate = DateTime(
          int.parse('20${endDateParts[2]}'),
          int.parse(endDateParts[1]),
          int.parse(endDateParts[0]),
        );
      }
    }

    setState(() {
      _degreeController.text = item.degree;
      _instituteController.text = item.institute;
      _startDateController.text = item.startDate;
      _endDateController.text = item.endDate;
      _descriptionController.text = item.description;
      isCompleted = item.isCompleted;
      showForm = true;
      editingIndex = index;
      dateError = null;
    });
  }

  void _deleteEducation(int index) {
    final educationProvider =
    Provider.of<EducationProvider>(context, listen: false);
    educationProvider.deleteEducationItem(index);
    AppSnackBar.show(context, message: 'education_deleted_successfully'.tr);
  }

  void _toggleForm() {
    setState(() {
      showForm = true;
      editingIndex = null;
      _clearFormFields();
    });
  }

  void _clearForm() {
    setState(() {
      _clearFormFields();
      isCompleted = false;
      editingIndex = null;
      showForm = false;
    });
  }

  void _clearFormFields() {
    _degreeController.clear();
    _instituteController.clear();
    _startDateController.clear();
    _endDateController.clear();
    _descriptionController.clear();
    isCompleted = false;
    startDate = null;
    endDate = null;
    dateError = null;
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final educationProvider = Provider.of<EducationProvider>(context);
    final educationItems = educationProvider.educationItems;
    final hasEducation = educationItems.isNotEmpty;
    final canAddMoreEducation = educationItems.length < 2;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 26.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  if (showForm || !hasEducation)
                    EducationFormWidget(
                      degreeController: _degreeController,
                      instituteController: _instituteController,
                      startDateController: _startDateController,
                      endDateController: _endDateController,
                      descriptionController: _descriptionController,
                      isCompleted: isCompleted,
                      dateError: dateError,
                      degreeFocus: _degreeFocus,
                      instituteFocus: _instituteFocus,
                      startDateFocus: _startDateFocus,
                      endDateFocus: _endDateFocus,
                      descriptionFocus: _descriptionFocus,
                      onCompletedChanged: (value) {
                        setState(() {
                          isCompleted = value;
                          if (isCompleted) {
                            _endDateController.clear();
                            endDate = null;
                            dateError = null;
                          }
                        });
                      },
                      onDateSelected: (context, controller, isStartDate) {
                        final focusNode = isStartDate ? _startDateFocus : _endDateFocus;
                        _selectDate(context, controller, focusNode, isStartDate);
                      },
                      onSavePressed: _saveEducation,
                    ),
                  if (!showForm && hasEducation) ...[
                    for (int i = 0; i < educationItems.length; i++)
                      SavedEducationItemWidget(
                        item: educationItems[i],
                        index: i,
                        onEdit: _editEducation,
                        onDelete: _deleteEducation,
                      ),
                    const SizedBox(height: 16),
                    if (canAddMoreEducation)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: AddAnotherButton(
                          text: 'add_another_education'.tr,
                          onPressed: _toggleForm,
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}