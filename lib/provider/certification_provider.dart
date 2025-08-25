import 'package:flutter/material.dart';
import '../models/certification_model.dart';

class CertificationProvider with ChangeNotifier {
  final List<CertificationItem> _certificationItems = [];

  List<CertificationItem> get certificationItems => _certificationItems;

  void addCertificationItem(CertificationItem item) {
    _certificationItems.add(item);
    notifyListeners();
  }

  void updateCertificationItem(int index, CertificationItem item) {
    if (index >= 0 && index < _certificationItems.length) {
      _certificationItems[index] = item;
      notifyListeners();
    }
  }

  // Load all certification items at once
  void loadCertificationItems(List<CertificationItem> items) {
    _certificationItems.clear();
    _certificationItems.addAll(items);
    notifyListeners();
  }

  void removeCertificationItem(int index) {
    if (index >= 0 && index < _certificationItems.length) {
      _certificationItems.removeAt(index);
      notifyListeners();
    }
  }

  void clearCertificationItems() {
    _certificationItems.clear();
    notifyListeners();
  }
}