import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart'; // Add this import for .tr extension
import '../../models/skills_model.dart';
import '../../provider/skills_provider.dart';
import '../../widgets/tags_input_widget.dart';

class SkillsPage extends StatefulWidget {
  final List<Map<String, dynamic>>? initialData;
  const SkillsPage({
    this.initialData,
    super.key,
  });

  @override
  State<SkillsPage> createState() => _SkillsPageState();
}

class _SkillsPageState extends State<SkillsPage> {
  final TextEditingController _skillController = TextEditingController();
  final FocusNode _skillFocusNode = FocusNode();

  bool validate() {
    final provider = Provider.of<SkillsProvider>(context, listen: false);
    return provider.skillItems.isNotEmpty;
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
      final skillsProvider = Provider.of<SkillsProvider>(context, listen: false);

      // Clear any existing data
      skillsProvider.clearSkillItems();

      // Load the initial data into the provider
      for (var item in widget.initialData!) {
        skillsProvider.addSkill(
          Skill(
            name: item['name']?.toString() ?? '',
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _skillController.dispose();
    _skillFocusNode.dispose();
    super.dispose();
  }

  void _addSkill(String name) {
    final skillsProvider = Provider.of<SkillsProvider>(context, listen: false);
    if (skillsProvider.skillItems.length < 6) {
      skillsProvider.addSkill(Skill(name: name));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('max_skills_reached'.tr),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _removeSkill(int index) {
    final skillsProvider = Provider.of<SkillsProvider>(context, listen: false);
    skillsProvider.removeSkill(index);
  }

  @override
  Widget build(BuildContext context) {
    final skillsProvider = Provider.of<SkillsProvider>(context);
    final skills = skillsProvider.skillItems;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 26.0),
              child: TagInputWidget<Skill>(
                title: 'add_your_skills'.tr,
                inputLabel: 'skill'.tr,
                hintText: 'enter_skill_hint'.tr,
                items: skills,
                getItemName: (skill) => skill.name,
                onAdd: _addSkill,
                onRemove: _removeSkill,
                emptyMessage: 'no_skills_added'.tr,
                controller: _skillController,
                focusNode: _skillFocusNode,
                minItemsRequired: 1, // Add this parameter
              ),
            ),
          ),
        ),
      ],
    );
  }
}