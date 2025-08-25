import 'package:flutter/foundation.dart';
import '../models/skills_model.dart';

class SkillsProvider with ChangeNotifier {
  List<Skill> _skillItems = [];

  List<Skill> get skillItems => _skillItems;

  void addSkill(Skill skill) {
    if (_skillItems.length < 6) {  // Maintain the 6-skill limit
      _skillItems.add(skill);
      notifyListeners();
    }
  }

  void removeSkill(int index) {
    if (index >= 0 && index < _skillItems.length) {
      _skillItems.removeAt(index);
      notifyListeners();
    }
  }

  // Load all skill items at once
  void loadSkills(List<Skill> skills) {
    _skillItems = List.from(skills.take(6));  // Ensure max 6 skills
    notifyListeners();
  }

  void clearSkillItems() {
    _skillItems.clear();
    notifyListeners();
  }
}