import 'dart:io';
import 'package:flutter/material.dart';

class FilterProvider extends ChangeNotifier {
  String _selectedFilter = 'Original';
  final Map<String, File> _filterCache = {};

  String get selectedFilter => _selectedFilter;
  Map<String, File> get filterCache => _filterCache;

  void setFilter(String filterName) {
    _selectedFilter = filterName;
    notifyListeners();
  }

  void addToCache(String filterName, File imageFile) {
    _filterCache[filterName] = imageFile;
  }

  void clearCache() {
    _filterCache.clear();
  }
}