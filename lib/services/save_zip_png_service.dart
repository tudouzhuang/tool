import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:toolkit/services/save_document_service.dart';
import 'package:get/get.dart'; // GetX import for localization

import '../models/file_model.dart';
import '../utils/app_snackbar.dart';

class SaveFileService {
  static const String toolkitFolderName = 'Toolkit';

  /// Checks if storage permission is available or needed
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
      if (await Permission.photos.status.isGranted) {
        return true;
      }
      final result = await Permission.photos.request();
      return result.isGranted;
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
          title: Text('permission_issue'.tr),
          content: Text('permission_issue_message'.tr),
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
      debugPrint('Error creating Toolkit folder: $e');
      return null;
    }
  }

  /// Generate unique filename if file already exists in destination
  static Future<String> _generateUniqueFileName(
      String directoryPath, String fileName) async {
    String baseFileName = path.basenameWithoutExtension(fileName);
    String extension = path.extension(fileName);
    String finalFileName = fileName;
    int counter = 1;

    while (await File(path.join(directoryPath, finalFileName)).exists()) {
      finalFileName = '${baseFileName}_$counter$extension';
      counter++;
    }

    return finalFileName;
  }

  /// Save PNG file to Toolkit folder
  static Future<void> savePngFile(BuildContext context, File imageFile) async {
    try {
      bool hasPermission = await checkAndRequestStoragePermission(context);

      if (hasPermission) {
        final toolkitDir = await _createToolkitFolder();

        if (toolkitDir == null) {
          await _saveFileWithDialog(context, imageFile, 'png');
          return;
        }

        String fileName = path.basename(imageFile.path);
        String uniqueFileName =
        await _generateUniqueFileName(toolkitDir.path, fileName);
        final destinationPath = '${toolkitDir.path}/$uniqueFileName';

        await imageFile.copy(destinationPath);

        // Save to Hive
        await _saveFileToHive(File(destinationPath), 'png');

        AppSnackBar.show(context, message: 'image_saved_to'.trParams({'path': toolkitDir.path}));
      } else {
        await showPermissionHelperDialog(context);
      }
    } on PlatformException catch (e) {
      debugPrint('Platform Exception in saving PNG file: ${e.message}');
      AppSnackBar.show(context, message: 'failed_to_save_image'.trParams({'error': e.message ?? 'unknown_error'.tr}));
    } catch (e) {
      debugPrint('Error saving PNG file: $e');
      AppSnackBar.show(context,
          message: 'failed_to_save_image'.trParams({'error': e.toString()}));
    }
  }

  /// Save ZIP file to Toolkit folder
  static Future<void> saveZipFile(BuildContext context, File zipFile) async {
    try {
      bool hasPermission = await checkAndRequestStoragePermission(context);

      if (hasPermission) {
        final toolkitDir = await _createToolkitFolder();

        if (toolkitDir == null) {
          await _saveFileWithDialog(context, zipFile, 'zip');
          return;
        }

        String fileName = path.basename(zipFile.path);
        String uniqueFileName =
        await _generateUniqueFileName(toolkitDir.path, fileName);
        final destinationPath = '${toolkitDir.path}/$uniqueFileName';

        await zipFile.copy(destinationPath);

        // Save to Hive
        await _saveFileToHive(File(destinationPath), 'zip');

        AppSnackBar.show(context,
            message: 'zip_file_saved_to'.trParams({'path': toolkitDir.path}));
      } else {
        await showPermissionHelperDialog(context);
      }
    } on PlatformException catch (e) {
      debugPrint('Platform Exception in saving ZIP file: ${e.message}');
      AppSnackBar.show(context,
          message: 'failed_to_save_zip'.trParams({'error': e.message ?? 'unknown_error'.tr}));
    } catch (e) {
      debugPrint('Error saving ZIP file: $e');
      AppSnackBar.show(context,
          message: 'failed_to_save_zip'.trParams({'error': e.toString()}));
    }
  }

  static Future<void> _saveFileToHive(File file, String fileType) async {
    try {
      final filesBox = await SaveDocumentService.initFilesBox();
      final fileModel = FileModel(
        name: path.basename(file.path),
        path: file.path,
        date: DateTime.now(),
        size: '${(file.lengthSync() / (1024 * 1024)).toStringAsFixed(2)} MB',
        isFavorite: false,
        isLocked: false,
        isEncrypted: false,
      );
      await filesBox.add(fileModel);
    } catch (e) {
      debugPrint('Error saving file to Hive: $e');
    }
  }

  /// Main method to save any file based on its type to Toolkit folder
  static Future<void> saveFile(
      BuildContext context, File file, String fileType) async {
    try {
      switch (fileType.toLowerCase()) {
        case 'png':
        case 'jpg':
        case 'jpeg':
          await savePngFile(context, file);
          break;
        case 'zip':
          await saveZipFile(context, file);
          break;
        case 'pdf':
          await _savePdfFile(context, file);
          break;
        case 'docx':
          await _saveDocumentFile(context, file);
          break;
        case 'xlsx':
        case 'pptx':
        default:
          await _saveGenericFile(context, file);
      }
    } catch (e) {
      debugPrint('Error in saveFile: $e');
      AppSnackBar.show(context,
          message: 'failed_to_save_file'.trParams({'error': e.toString()}));
    }
  }

  /// Save DOCX document file to Toolkit folder
  static Future<void> _saveDocumentFile(
      BuildContext context, File docFile) async {
    try {
      bool hasPermission = await checkAndRequestStoragePermission(context);

      if (hasPermission) {
        final toolkitDir = await _createToolkitFolder();

        if (toolkitDir == null) {
          await _saveFileWithDialog(context, docFile, 'docx');
          return;
        }

        String fileName = path.basename(docFile.path);
        String uniqueFileName =
        await _generateUniqueFileName(toolkitDir.path, fileName);
        final destinationPath = '${toolkitDir.path}/$uniqueFileName';

        await docFile.copy(destinationPath);

        // Save to Hive
        await _saveFileToHive(File(destinationPath), 'docx');

        AppSnackBar.show(context,
            message: 'document_saved_to'.trParams({'path': toolkitDir.path}));
      } else {
        await showPermissionHelperDialog(context);
      }
    } on PlatformException catch (e) {
      debugPrint('Platform Exception in saving document file: ${e.message}');
      AppSnackBar.show(context,
          message: 'failed_to_save_document'.trParams({'error': e.message ?? 'unknown_error'.tr}));
    } catch (e) {
      debugPrint('Error saving document file: $e');
      AppSnackBar.show(context,
          message: 'failed_to_save_document'.trParams({'error': e.toString()}));
    }
  }

  /// Save PDF file to Toolkit folder
  static Future<void> _savePdfFile(BuildContext context, File pdfFile) async {
    try {
      bool hasPermission = await checkAndRequestStoragePermission(context);

      if (hasPermission) {
        final toolkitDir = await _createToolkitFolder();

        if (toolkitDir == null) {
          await _saveFileWithDialog(context, pdfFile, 'pdf');
          return;
        }

        String fileName = path.basename(pdfFile.path);
        String uniqueFileName =
        await _generateUniqueFileName(toolkitDir.path, fileName);
        final destinationPath = '${toolkitDir.path}/$uniqueFileName';

        await pdfFile.copy(destinationPath);

        // Save to Hive
        await _saveFileToHive(File(destinationPath), 'pdf');

        AppSnackBar.show(context, message: 'pdf_saved_to'.trParams({'path': toolkitDir.path}));
      } else {
        await showPermissionHelperDialog(context);
      }
    } on PlatformException catch (e) {
      debugPrint('Platform Exception in saving PDF file: ${e.message}');
      AppSnackBar.show(context, message: 'failed_to_save_pdf'.trParams({'error': e.message ?? 'unknown_error'.tr}));
    } catch (e) {
      debugPrint('Error saving PDF file: $e');
      AppSnackBar.show(context, message: 'failed_to_save_pdf'.trParams({'error': e.toString()}));
    }
  }

  /// Generic file saving method for other file types to Toolkit folder
  static Future<void> _saveGenericFile(BuildContext context, File file) async {
    try {
      bool hasPermission = await checkAndRequestStoragePermission(context);

      if (hasPermission) {
        final toolkitDir = await _createToolkitFolder();

        if (toolkitDir == null) {
          await _saveFileWithDialog(
              context, file, path.extension(file.path).replaceAll('.', ''));
          return;
        }

        String fileName = path.basename(file.path);
        String uniqueFileName =
        await _generateUniqueFileName(toolkitDir.path, fileName);
        final destinationPath = '${toolkitDir.path}/$uniqueFileName';

        await file.copy(destinationPath);

        // Save to Hive
        await _saveFileToHive(File(destinationPath), path.extension(file.path).replaceAll('.', ''));

        AppSnackBar.show(context, message: 'file_saved_to'.trParams({'path': toolkitDir.path}));
      } else {
        await showPermissionHelperDialog(context);
      }
    } catch (e) {
      debugPrint('Error saving generic file: $e');
      AppSnackBar.show(context,
          message: 'failed_to_save_file'.trParams({'error': e.toString()}));
    }
  }

  /// Fallback method to save files using system dialog if Toolkit folder creation fails
  static Future<void> _saveFileWithDialog(
      BuildContext context, File file, String fileType) async {
    try {
      String fileName = path.basename(file.path);

      final params = SaveFileDialogParams(
        sourceFilePath: file.path,
        fileName: fileName,
      );

      final savedFilePath = await FlutterFileDialog.saveFile(params: params);

      if (savedFilePath != null) {
        // Save to Hive
        await _saveFileToHive(File(savedFilePath), fileType);

        AppSnackBar.show(context, message: 'file_saved_successfully'.tr);
      } else {
        AppSnackBar.show(context, message: 'file_saving_canceled'.tr);
      }
    } catch (e) {
      debugPrint('Error in _saveFileWithDialog: $e');
      AppSnackBar.show(context,
          message: 'failed_to_save_file'.trParams({'error': e.toString()}));
    }
  }
}