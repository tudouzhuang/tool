import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/saved_cv.dart';
import '../models/saved_cv_adapter.dart';

class SavedCVProvider with ChangeNotifier {
  List<SavedCV> _savedCVs = [];
  Box<SavedCV>? _savedCVsBox;
  bool _isInitialized = false;
  bool _isInitializing = false;

  List<SavedCV> get savedCVs => _savedCVs;
  bool get isInitialized => _isInitialized;

  Future<void> initHive() async {
    if (_isInitialized || _isInitializing) return;

    _isInitializing = true;
    try {
      await Hive.initFlutter();

      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(SavedCVAdapter());
      }

      try {
        _savedCVsBox = await Hive.openBox<SavedCV>('saved_cvs');
        await loadSavedCVs();
      } catch (boxError) {
        debugPrint('Error opening box, clearing corrupted data: $boxError');
        try {
          await Hive.deleteBoxFromDisk('saved_cvs');
          _savedCVsBox = await Hive.openBox<SavedCV>('saved_cvs');
          _savedCVs = [];
        } catch (deleteError) {
          debugPrint('Error creating new box: $deleteError');
          _savedCVs = [];
        }
      }

      _isInitialized = true;
    } catch (e) {
      debugPrint('Error initializing Hive: $e');
      _savedCVs = [];
    } finally {
      _isInitializing = false;
      WidgetsBinding.instance.addPostFrameCallback((_) => notifyListeners());
    }
  }

  Future<void> loadSavedCVs() async {
    if (_savedCVsBox == null) {
      debugPrint('SavedCVs box is not initialized');
      return;
    }

    try {
      final values = _savedCVsBox!.values.toList();
      _savedCVs = values;
      debugPrint('Loaded ${_savedCVs.length} CVs successfully');
      WidgetsBinding.instance.addPostFrameCallback((_) => notifyListeners());
    } catch (e) {
      debugPrint('Error loading CVs: $e');
      try {
        await _savedCVsBox!.clear();
        _savedCVs = [];
        debugPrint('Cleared corrupted CV data');
        WidgetsBinding.instance.addPostFrameCallback((_) => notifyListeners());
      } catch (clearError) {
        debugPrint('Error clearing corrupted data: $clearError');
        _savedCVs = [];
        WidgetsBinding.instance.addPostFrameCallback((_) => notifyListeners());
      }
    }
  }

  Future<void> clearAllData() async {
    try {
      if (_savedCVsBox != null) {
        await _savedCVsBox!.clear();
        _savedCVs = [];
        WidgetsBinding.instance.addPostFrameCallback((_) => notifyListeners());
        debugPrint('All CV data cleared successfully');
      }
    } catch (e) {
      debugPrint('Error clearing all data: $e');
    }
  }

  Future<void> addSavedCV({
    required String fileName,
    required String filePath,
    required Uint8List? thumbnailBytes,
    required int templateId,
    required Map<String, dynamic> formData,
  }) async {
    if (_savedCVsBox == null) {
      debugPrint('Cannot add CV: SavedCVs box is not initialized');
      return;
    }

    try {
      if (thumbnailBytes != null && thumbnailBytes.isEmpty) {
        thumbnailBytes = null;
      }

      final file = File(filePath);
      if (!await file.exists()) {
        debugPrint('File does not exist: $filePath');
        return;
      }

      final savedCV = SavedCV(
        id: const Uuid().v4(),
        fileName: fileName,
        dateTime: _formatDateTime(DateTime.now()),
        fileSize: _formatFileSize(await file.length()),
        thumbnailBytes: thumbnailBytes,
        filePath: filePath,
        templateId: templateId,
        formData: formData,
      );

      await _savedCVsBox!.add(savedCV);
      await loadSavedCVs();
    } catch (e) {
      debugPrint('Error adding CV: $e');
      rethrow;
    }
  }

  String _formatDateTime(DateTime now) {
    final hour12 = now.hour > 12 ? now.hour - 12 : (now.hour == 0 ? 12 : now.hour);
    final amPm = now.hour >= 12 ? 'pm' : 'am';

    return '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year.toString().substring(2)} | '
        '${hour12.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}$amPm';
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> deleteSavedCV(String id) async {
    if (_savedCVsBox == null) {
      debugPrint('Cannot delete CV: SavedCVs box is not initialized');
      return;
    }

    try {
      final keys = _savedCVsBox!.keys.toList();
      dynamic keyToDelete;

      for (var key in keys) {
        final cv = _savedCVsBox!.get(key);
        if (cv?.id == id) {
          keyToDelete = key;
          break;
        }
      }

      if (keyToDelete != null) {
        final cvToDelete = _savedCVsBox!.get(keyToDelete);
        if (cvToDelete != null) {
          final file = File(cvToDelete.filePath);
          if (await file.exists()) {
            try {
              await file.delete();
            } catch (e) {
              debugPrint('Error deleting file: $e');
            }
          }

          await _savedCVsBox!.delete(keyToDelete);
          await loadSavedCVs();
        }
      }
    } catch (e) {
      debugPrint('Error deleting saved CV: $e');
    }
  }

  Future<void> close() async {
    if (_isInitialized && _savedCVsBox != null) {
      await _savedCVsBox!.close();
      _isInitialized = false;
      _savedCVsBox = null;
    }
  }
}