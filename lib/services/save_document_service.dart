import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:hive_ce/hive.dart';
import 'package:hive_ce_flutter/adapters.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import '../models/file_model.dart';
import '../models/file_model_adapter.dart';
import '../utils/app_snackbar.dart';
import 'file_encryption_service.dart';

class SaveDocumentService {
  static const String _filesBoxName = 'filesBox';
  static const String toolkitFolderName = 'Toolkit';

  /// Initialize Hive box for files
  static Future<Box<FileModel>> initFilesBox() async {
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(FileModelAdapter());
    }
    return await Hive.openBox<FileModel>(_filesBoxName);
  }

  /// Toggle file lock status (encrypt/decrypt)
  static Future<bool> toggleFileLock(FileModel fileModel, int index) async {
    try {
      final filesBox = await initFilesBox();

      if (fileModel.isLocked && !fileModel.isEncrypted) {
        // Lock file: encrypt it
        final encryptedPath =
        await FileEncryptionService.encryptAndMoveFile(fileModel.path);

        if (encryptedPath != null) {
          // Update file model to reflect encryption
          final updatedFile = FileModel(
            name: fileModel.name,
            path: encryptedPath,
            date: fileModel.date,
            size: fileModel.size,
            isFavorite: fileModel.isFavorite,
            isLocked: true,
            originalPath: fileModel.path,
            isEncrypted: true,
          );

          await filesBox.putAt(index, updatedFile);
          return true;
        }
      } else if (!fileModel.isLocked && fileModel.isEncrypted) {
        // Unlock file: decrypt it back to Toolkit folder

        // Get the Toolkit folder path
        final toolkitDir = await _createToolkitFolder();
        if (toolkitDir == null) {
          print('error_toolkit_folder_access'.tr);
          return false;
        }

        // Create the new path in Toolkit folder with the original filename
        final originalFileName = fileModel.name;
        final newToolkitPath = '${toolkitDir.path}/$originalFileName';

        // Check if file with same name already exists in Toolkit folder
        final existingFile = File(newToolkitPath);
        String finalPath = newToolkitPath;

        if (await existingFile.exists()) {
          // Generate unique filename with timestamp
          final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
          final nameWithoutExt =
          path.basenameWithoutExtension(originalFileName);
          final extension = path.extension(originalFileName);
          final uniqueFileName = '${nameWithoutExt}_$timestamp$extension';
          finalPath = '${toolkitDir.path}/$uniqueFileName';
        }

        // Decrypt file to the Toolkit folder location
        final decryptedPath = await FileEncryptionService.decryptAndRestoreFile(
            fileModel.path, finalPath);

        if (decryptedPath != null) {
          // Update file model to reflect decryption
          final updatedFile = FileModel(
            name: path.basename(decryptedPath),
            path: decryptedPath,
            date: fileModel.date,
            size: fileModel.size,
            isFavorite: fileModel.isFavorite,
            isLocked: false,
            originalPath: null,
            isEncrypted: false,
          );

          await filesBox.putAt(index, updatedFile);
          return true;
        }
      }

      return false;
    } catch (e) {
      print('error_toggle_file_lock'.tr);
      return false;
    }
  }

  /// Get files filtered by lock status
  static Future<List<FileModel>> getFilesByLockStatus(
      {required bool showLocked}) async {
    try {
      final filesBox = await initFilesBox();
      return filesBox.values
          .where((file) => file.isLocked == showLocked)
          .toList();
    } catch (e) {
      print('error_get_files_by_lock_status'.tr);
      return [];
    }
  }

  /// Get all non-locked files (these will appear in regular file tabs)
  static Future<List<FileModel>> getVisibleFiles() async {
    return await getFilesByLockStatus(showLocked: false);
  }

  /// Get all locked files (these will only appear in locked files view)
  static Future<List<FileModel>> getLockedFiles() async {
    return await getFilesByLockStatus(showLocked: true);
  }

  /// Delete file (handles both encrypted and regular files)
  static Future<bool> deleteFile(FileModel fileModel) async {
    try {
      final file = File(fileModel.path);

      if (await file.exists()) {
        await file.delete();
      }

      // If it was an encrypted file, also clean up the original path if it exists
      if (fileModel.isEncrypted && fileModel.originalPath != null) {
        final originalFile = File(fileModel.originalPath!);
        if (await originalFile.exists()) {
          await originalFile.delete();
        }
      }

      return true;
    } catch (e) {
      print('error_delete_file'.tr);
      return false;
    }
  }

  /// Rename file (handles both encrypted and regular files)
  static Future<String?> renameFile(FileModel fileModel, String newName) async {
    try {
      final file = File(fileModel.path);
      final directory = path.dirname(fileModel.path);
      final extension = path.extension(fileModel.path);
      final newFileName = '$newName$extension';
      final newPath = path.join(directory, newFileName);

      if (await file.exists()) {
        await file.rename(newPath);
        return newPath;
      }

      return null;
    } catch (e) {
      print('error_rename_file'.tr);
      return null;
    }
  }

  static Future<bool> checkAndRequestStoragePermission(
      BuildContext context) async {
    if (Platform.isAndroid) {
      if (await _isAndroidVersionAbove29()) {
        return true;
      }

      final status = await Permission.storage.status;
      if (!status.isGranted) {
        final result = await Permission.storage.request();
        return result.isGranted;
      }
      return status.isGranted;
    } else if (Platform.isIOS) {
      return true;
    }

    return false;
  }

  /// Helper method to check Android version
  static Future<bool> _isAndroidVersionAbove29() async {
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      return androidInfo.version.sdkInt >= 29;
    }
    return false;
  }

  /// Shows a helper dialog for permission issues
  static Future<void> showPermissionHelperDialog(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('permission_issue_title'.tr),
          content: Text('permission_issue_content'.tr),
          actions: <Widget>[
            TextButton(
              child: Text('cancel'.tr),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('open_settings'.tr),
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
              },
            ),
          ],
        );
      },
    );
  }

  /// Creates Toolkit folder if it doesn't exist
  static Future<Directory?> _createToolkitFolder() async {
    try {
      Directory? baseDir;

      if (Platform.isAndroid) {
        baseDir = Directory('/storage/emulated/0/Download');
        if (!await baseDir.exists()) {
          baseDir = await getApplicationDocumentsDirectory();
        }
      } else if (Platform.isIOS) {
        baseDir = await getApplicationDocumentsDirectory();
      } else {
        return null;
      }

      final toolkitDir = Directory('${baseDir.path}/$toolkitFolderName');
      if (!await toolkitDir.exists()) {
        await toolkitDir.create(recursive: true);
      }

      return toolkitDir;
    } catch (e) {
      debugPrint('error_create_toolkit_folder'.tr);
      return null;
    }
  }

  /// Fallback method to save files using system dialog
  static Future<String?> _saveFileWithDialog(
      BuildContext context, File documentFile,
      {bool skipTimestamp = false}) async {
    try {
      String baseFileName = path.basename(documentFile.path);
      if (!baseFileName.toLowerCase().endsWith('.docx')) {
        baseFileName = 'document_default_name'.tr;
      }

      String uniqueFileName;
      if (skipTimestamp) {
        uniqueFileName = baseFileName;
      } else {
        final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
        uniqueFileName =
        '${path.basenameWithoutExtension(baseFileName)}_$timestamp${path.extension(baseFileName)}';
      }

      final params = SaveFileDialogParams(
        sourceFilePath: documentFile.path,
        fileName: uniqueFileName,
      );

      final savedFilePath = await FlutterFileDialog.saveFile(params: params);

      if (savedFilePath != null) {
        AppSnackBar.show(context, message: 'document_saved_successfully'.tr);
        return savedFilePath;
      } else {
        AppSnackBar.show(context, message: 'document_saving_canceled'.tr);
        return null;
      }
    } catch (e) {
      debugPrint('error_save_file_dialog'.tr);
      AppSnackBar.show(context,
          message: 'failed_to_save_document'.tr);
      return null;
    }
  }

  /// Check if file already exists in the toolkit folder
  static Future<bool> _fileExistsInToolkitFolder(String fileName) async {
    try {
      final toolkitDir = await _createToolkitFolder();
      if (toolkitDir != null) {
        final filePath = '${toolkitDir.path}/$fileName';
        return await File(filePath).exists();
      }
      return false;
    } catch (e) {
      debugPrint('error_check_file_existence'.tr);
      return false;
    }
  }

  /// Main method to save a document file to Toolkit folder
  static Future<bool?> saveDocument(
      BuildContext context,
      File documentFile, {
        bool skipTimestamp = false,
      }) async {
    try {
      bool canAccessStorage = await checkAndRequestStoragePermission(context);

      if (canAccessStorage) {
        final toolkitDir = await _createToolkitFolder();
        String? savedFilePath;

        if (toolkitDir != null) {
          String baseFileName = path.basename(documentFile.path);
          if (!baseFileName.toLowerCase().endsWith('.docx')) {
            baseFileName = 'document_default_name'.tr;
          }

          String uniqueFileName;
          if (skipTimestamp) {
            uniqueFileName = baseFileName;

            if (await _fileExistsInToolkitFolder(uniqueFileName)) {
              AppSnackBar.show(context,
                  message: 'file_name_already_exists'.tr);
              return false;
            }
          } else {
            final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
            uniqueFileName =
            '${path.basenameWithoutExtension(baseFileName)}_$timestamp${path.extension(baseFileName)}';
          }

          final destinationPath = '${toolkitDir.path}/$uniqueFileName';
          await documentFile.copy(destinationPath);
          savedFilePath = destinationPath;

          AppSnackBar.show(context,
              message: 'document_saved_to_location'.tr);
        } else {
          savedFilePath = await _saveFileWithDialog(context, documentFile,
              skipTimestamp: skipTimestamp);
          if (savedFilePath == null) {
            return false;
          }
        }

        final filesBox = await initFilesBox();
        final fileSize = (await documentFile.length()) / (1024 * 1024);

        await filesBox.add(FileModel(
          name: path.basename(savedFilePath),
          path: savedFilePath,
          date: DateTime.now(),
          size: '${fileSize.toStringAsFixed(1)} ${'mb'.tr}',
          isFavorite: false,
          isLocked: false,
          isEncrypted: false,
        ));

        return true;
      } else {
        showPermissionHelperDialog(context);
        return null;
      }
    } on PlatformException {
      AppSnackBar.show(context,
          message: 'failed_to_save_document'.tr);
      return null;
    } catch (e) {
      AppSnackBar.show(context, message: 'failed_to_save_document'.tr);
      return null;
    }
  }
}