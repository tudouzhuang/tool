import 'package:flutter/foundation.dart';
import '../models/education_item_model.dart';

class EducationProvider with ChangeNotifier {
  final List<EducationItem> _educationItems = [];

  List<EducationItem> get educationItems => _educationItems;

  void addEducationItem(EducationItem item) {
    _educationItems.add(item);
    notifyListeners();
  }

  void updateEducationItem(int index, EducationItem item) {
    if (index >= 0 && index < _educationItems.length) {
      _educationItems[index] = item;
      notifyListeners();
    }
  }

  // Load all education items at once
  void loadEducationItems(List<EducationItem> items) {
    _educationItems.clear();
    _educationItems.addAll(items);
    notifyListeners();
  }

  void deleteEducationItem(int index) {
    if (index >= 0 && index < _educationItems.length) {
      _educationItems.removeAt(index);
      notifyListeners();
    }
  }

  void clearEducationItems() {
    _educationItems.clear();
    notifyListeners();
  }
}