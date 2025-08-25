// Create a new file: lib/provider/language_provider.dart

import 'package:flutter/foundation.dart';
import '../models/language_model.dart';

class LanguageProvider with ChangeNotifier {
  List<Language> _languages = [];
  final int _maxLanguages = 3; // Maximum number of languages allowed

  List<Language> get languages => _languages;

  void addLanguage(Language language) {
    if (_languages.length < _maxLanguages) {  // Maintain the 3-language limit
      _languages.add(language);
      notifyListeners();
    }
  }

  void removeLanguage(int index) {
    if (index >= 0 && index < _languages.length) {
      _languages.removeAt(index);
      notifyListeners();
    }
  }

  // Load all language items at once
  void loadLanguages(List<Language> languages) {
    _languages = List.from(languages.take(_maxLanguages));  // Ensure max 3 languages
    notifyListeners();
  }

  void clearLanguages() {
    _languages.clear();
    notifyListeners();
  }
}
