import 'dart:io';
import 'package:flutter/material.dart';

class FileProvider extends ChangeNotifier {
  List<File> _selectedFiles = [];

  List<File> get selectedFiles => List.unmodifiable(_selectedFiles);

  void addFiles(List<File> files) {
    _selectedFiles.addAll(files);
    notifyListeners();
  }

  void addFile(File file) {
    _selectedFiles.add(file);
    notifyListeners();
  }

  void removeFile(int index) {
    if (index >= 0 && index < _selectedFiles.length) {
      _selectedFiles.removeAt(index);
      notifyListeners();
    }
  }

  void clearAllFiles() {
    _selectedFiles.clear();
    notifyListeners();
  }

  void replaceFiles(List<File> files) {
    _selectedFiles = List.from(files);
    notifyListeners();
  }

  bool get hasFiles => _selectedFiles.isNotEmpty;

  int get fileCount => _selectedFiles.length;
}