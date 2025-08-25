import 'package:flutter/material.dart';
import '../models/work_experience_model.dart';

class WorkExperienceProvider with ChangeNotifier {
  final List<WorkExperienceItem> _workExperienceItems = [];

  List<WorkExperienceItem> get workExperienceItems => _workExperienceItems;

  void addWorkExperience(WorkExperienceItem item) {
    _workExperienceItems.add(item);
    notifyListeners();
  }

  void updateWorkExperience(int index, WorkExperienceItem item) {
    if (index >= 0 && index < _workExperienceItems.length) {
      _workExperienceItems[index] = item;
      notifyListeners();
    }
  }

  // Load all work experience items at once
  void loadWorkExperienceItems(List<WorkExperienceItem> items) {
    _workExperienceItems.clear();
    _workExperienceItems.addAll(items);
    notifyListeners();
  }

  void deleteWorkExperience(int index) {
    if (index >= 0 && index < _workExperienceItems.length) {
      _workExperienceItems.removeAt(index);
      notifyListeners();
    }
  }

  void clearWorkExperienceItems() {
    _workExperienceItems.clear();
    notifyListeners();
  }
}