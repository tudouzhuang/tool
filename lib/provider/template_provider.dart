import 'package:flutter/material.dart';

class TemplateProvider extends ChangeNotifier {
  int _selectedTemplateId = 1;
  String _templateName = 'Classic Professional';

  int get selectedTemplateId => _selectedTemplateId;
  String get templateName => _templateName;
  void loadTemplate(int templateId, String templateName) {
    _selectedTemplateId = templateId;
    _templateName = templateName;
    notifyListeners();
  }
  void setTemplate(int templateId, String templateName) {
    _selectedTemplateId = templateId;
    _templateName = templateName;
    notifyListeners();
  }
}