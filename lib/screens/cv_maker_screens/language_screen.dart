import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart'; // Import GetX for .tr extension
import '../../models/language_model.dart';
import '../../provider/language_provider.dart';
import '../../widgets/tags_input_widget.dart';

class LanguagesPage extends StatefulWidget {
  final List<Map<String, dynamic>>? initialData;
  const LanguagesPage({
    this.initialData,
    super.key,
  });

  @override
  State<LanguagesPage> createState() => _LanguagesPageState();
}

class _LanguagesPageState extends State<LanguagesPage> {
  final TextEditingController _languageController = TextEditingController();
  final FocusNode _languageFocusNode = FocusNode();

  bool validate() {
    final provider = Provider.of<LanguageProvider>(context, listen: false);
    return provider.languages.isNotEmpty;
  }

  // Set maximum number of languages
  final int _maxLanguages = 3;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  void _loadInitialData() {
    if (widget.initialData != null && widget.initialData!.isNotEmpty) {
      final languageProvider = Provider.of<LanguageProvider>(context, listen: false);

      // Clear any existing data
      languageProvider.clearLanguages();

      // Load the initial data into the provider
      for (var item in widget.initialData!) {
        languageProvider.addLanguage(
          Language(
            name: item['name'] ?? '',
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _languageController.dispose();
    _languageFocusNode.dispose();
    super.dispose();
  }

  void _addLanguage(String name) {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    // Check if we've reached the maximum limit
    if (languageProvider.languages.length < _maxLanguages) {
      languageProvider.addLanguage(Language(name: name));
    }
  }

  void _removeLanguage(int index) {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    languageProvider.removeLanguage(index);
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final languages = languageProvider.languages;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 26.0),
              child: TagInputWidget<Language>(
                title: 'add_your_languages'.tr,
                inputLabel: 'language'.tr,
                hintText: 'enter_a_language'.tr,
                items: languages,
                getItemName: (language) => language.name,
                onAdd: _addLanguage,
                onRemove: _removeLanguage,
                emptyMessage: 'no_languages_added_yet'.tr,
                controller: _languageController,
                focusNode: _languageFocusNode,
                maxItems: _maxLanguages,
                minItemsRequired: 1,
              ),
            ),
          ),
        ),
      ],
    );
  }
}