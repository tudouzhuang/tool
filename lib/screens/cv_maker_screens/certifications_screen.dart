import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';
import '../../models/certification_model.dart';
import '../../provider/certification_provider.dart';
import '../../utils/app_colors.dart';
import '../../widgets/buttons/add_another_button.dart';
import '../../widgets/buttons/save_edit_delete_btns.dart';

class CertificationPage extends StatefulWidget {
  final List<Map<String, dynamic>>? initialData;

  const CertificationPage({
    super.key,
    this.initialData,
  });

  @override
  State<CertificationPage> createState() => _CertificationPageState();
}

class _CertificationPageState extends State<CertificationPage> {
  final TextEditingController _certificationNameController =
      TextEditingController();
  final TextEditingController _organizationNameController =
      TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  // Add focus nodes for better focus management
  final FocusNode _certificationNameFocus = FocusNode();
  final FocusNode _organizationNameFocus = FocusNode();
  final FocusNode _descriptionFocus = FocusNode();

  bool hasCertification = false;
  bool showForm = false;
  int? editingIndex;

  bool validate() {
    final provider = Provider.of<CertificationProvider>(context, listen: false);
    return provider.certificationItems.isNotEmpty;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  void _loadInitialData() {
    if (widget.initialData != null && widget.initialData!.isNotEmpty) {
      final certProvider =
          Provider.of<CertificationProvider>(context, listen: false);

      // Clear any existing data
      certProvider.clearCertificationItems();

      // Load the initial data into the provider
      for (var item in widget.initialData!) {
        certProvider.addCertificationItem(
          CertificationItem(
            certificationName: item['certificationName'] ?? '',
            organizationName: item['organizationName'] ?? '',
            startDate: item['startDate'] ?? '',
            endDate: item['endDate'] ?? '',
            description: item['description'] ?? '',
            isCompleted: item['isCompleted'] ?? false,
          ),
        );
      }

      // Update the local state after loading data
      if (mounted) {
        setState(() {
          hasCertification = certProvider.certificationItems.isNotEmpty;
        });
      }
    }
  }

  @override
  void dispose() {
    _certificationNameController.dispose();
    _organizationNameController.dispose();
    _dateController.dispose();
    _descriptionController.dispose();
    _certificationNameFocus.dispose();
    _organizationNameFocus.dispose();
    _descriptionFocus.dispose();
    super.dispose();
  }

  void _selectDate(
      BuildContext context, TextEditingController controller) async {
    // Clear focus from all fields before opening date picker
    _certificationNameFocus.unfocus();
    _organizationNameFocus.unfocus();
    _descriptionFocus.unfocus();

    // Also clear focus from the primary focus
    FocusScope.of(context).unfocus();

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime(2100),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppColors.primary,
                  onPrimary: Colors.white,
                  surface: Colors.white,
                  onSurface: Colors.black,
                ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        // Format date as DD/MM/YYYY to include the day
        controller.text =
            "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
      });

      // Ensure no field gets focus after date selection
      WidgetsBinding.instance.addPostFrameCallback((_) {
        FocusScope.of(context).unfocus();
      });
    }
  }

  void _saveCertification() {
    final certificationProvider =
        Provider.of<CertificationProvider>(context, listen: false);

    final newItem = CertificationItem(
      certificationName: _certificationNameController.text,
      organizationName: _organizationNameController.text,
      startDate: _dateController.text,
      endDate: "",
      // Empty string as we're removing end date
      isCompleted: false,
      description: _descriptionController.text,
    );

    if (editingIndex != null) {
      certificationProvider.updateCertificationItem(editingIndex!, newItem);
      editingIndex = null;
    } else {
      certificationProvider.addCertificationItem(newItem);
    }

    setState(() {
      hasCertification = true;
      showForm = false;

      // Clear form fields
      _certificationNameController.clear();
      _organizationNameController.clear();
      _dateController.clear();
      _descriptionController.clear();
    });
  }

  void _editCertification(int index) {
    final certificationProvider =
        Provider.of<CertificationProvider>(context, listen: false);
    final item = certificationProvider.certificationItems[index];

    setState(() {
      _certificationNameController.text = item.certificationName;
      _organizationNameController.text = item.organizationName;
      _dateController.text = item.startDate;
      _descriptionController.text = item.description;
      showForm = true;
      editingIndex = index;
    });
  }

  void _deleteCertification(int index) {
    final certificationProvider =
        Provider.of<CertificationProvider>(context, listen: false);
    certificationProvider.removeCertificationItem(index);

    setState(() {
      if (certificationProvider.certificationItems.isEmpty) {
        hasCertification = false;
      }
    });
  }

  void _toggleForm() {
    setState(() {
      showForm = !showForm;
      editingIndex = null;

      // Clear form fields when showing the form
      if (showForm) {
        _certificationNameController.clear();
        _organizationNameController.clear();
        _dateController.clear();
        _descriptionController.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final certificationProvider = Provider.of<CertificationProvider>(context);
    final certificationItems = certificationProvider.certificationItems;

    // Update hasCertification based on provider
    hasCertification = certificationItems.isNotEmpty;

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

                  // Form is shown only when showForm is true
                  if (showForm) _buildCertificationForm(),

                  // Display saved certification items only when form is not shown
                  if (hasCertification && !showForm) ...[
                    for (int i = 0; i < certificationItems.length; i++)
                      _buildSavedCertification(certificationItems[i], i),
                    const SizedBox(height: 16),
                  ],

                  // Add another certification button (only shown when form is not visible)
                  if (hasCertification && !showForm)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: AddAnotherButton(
                        text: 'add_another_certificate'.tr,
                        onPressed: _toggleForm,
                      ),
                    ),

                  // Show form by default if no certification items yet and form is not already shown
                  if (!hasCertification && !showForm) _buildCertificationForm(),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSavedCertification(CertificationItem item, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      decoration: BoxDecoration(
        color: Colors.white,
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.certificationName,
                  style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.black),
                ),
                const SizedBox(
                  height: 4,
                ),
                Text(
                  item.startDate,
                  style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: AppColors.saveDateColor),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(
              height: 9,
              thickness: 1,
              color: AppColors.dividerColor,
            ),
            const SizedBox(height: 8),
            EditDeleteActionRow(
              onEdit: () => _editCertification(index),
              onDelete: () => _deleteCertification(index),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCertificationForm() {
    return Theme(
      data: Theme.of(context).copyWith(
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: AppColors.primary,
          selectionColor: AppColors.primary.withOpacity(0.3),
          selectionHandleColor: AppColors.primary,
        ),
      ),
      child: Container(
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
              // Certification Name
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'certification_name'.tr,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: AppColors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
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
                    child: TextFormField(
                      controller: _certificationNameController,
                      focusNode: _certificationNameFocus,
                      cursorColor: AppColors.primary,
                      decoration: InputDecoration(
                        hintText: 'enter_certification_name'.tr,
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
                ],
              ),
              const SizedBox(height: 16),

              // Organization Name
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'organization_name'.tr,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: AppColors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
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
                    child: TextFormField(
                      controller: _organizationNameController,
                      focusNode: _organizationNameFocus,
                      cursorColor: AppColors.primary,
                      decoration: InputDecoration(
                        hintText: 'enter_organization_name'.tr,
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
                ],
              ),
              const SizedBox(height: 16),

              // Date field
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'date'.tr,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: AppColors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => _selectDate(context, _dateController),
                    child: Container(
                      width: 148,
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
                      child: TextFormField(
                        controller: _dateController,
                        enabled: false,
                        decoration: InputDecoration(
                          hintText: 'date_placeholder'.tr,
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
                    height: 186,
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
                    child: TextFormField(
                      controller: _descriptionController,
                      focusNode: _descriptionFocus,
                      cursorColor: AppColors.primary,
                      maxLines: 7,
                      maxLength: 150,
                      decoration: InputDecoration(
                        hintText: 'certification_description_hint'.tr,
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
                ],
              ),
              const SizedBox(height: 20),
              const Divider(
                height: 1,
                thickness: 1,
                color: AppColors.dividerColor,
              ),
              const SizedBox(height: 20),

              SaveButton(
                onPressed: _saveCertification,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
