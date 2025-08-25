import 'dart:io';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class FileEncryptionService {
  static const String _encryptedFolderName = 'encrypted_files';
  static const String _keyPrefix = 'toolkit_key_';

  // Generate a secure encryption key
  static String _generateEncryptionKey() {
    final key = Key.fromSecureRandom(32);
    return key.base64;
  }

  // Get or create encryption key for the app
  static Future<String> _getOrCreateKey() async {
    final appDir = await getApplicationDocumentsDirectory();
    final keyFile = File('${appDir.path}/encryption_key.txt');

    if (await keyFile.exists()) {
      return await keyFile.readAsString();
    } else {
      final newKey = _generateEncryptionKey();
      await keyFile.writeAsString(newKey);
      return newKey;
    }
  }

  // Get encrypted files directory
  static Future<Directory> _getEncryptedDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final encryptedDir = Directory('${appDir.path}/$_encryptedFolderName');

    if (!await encryptedDir.exists()) {
      await encryptedDir.create(recursive: true);
    }

    return encryptedDir;
  }

  // Encrypt and move file to encrypted directory
  static Future<String?> encryptAndMoveFile(String originalFilePath) async {
    try {
      final originalFile = File(originalFilePath);
      if (!await originalFile.exists()) {
        throw Exception('Original file does not exist');
      }

      // Read original file
      final originalBytes = await originalFile.readAsBytes();

      // Get encryption key
      final keyString = await _getOrCreateKey();
      final key = Key.fromBase64(keyString);
      final iv = IV.fromSecureRandom(16);
      final encrypter = Encrypter(AES(key));

      // Encrypt file content
      final encrypted = encrypter.encryptBytes(originalBytes, iv: iv);

      // Create encrypted file data (IV + encrypted content)
      final encryptedData = Uint8List.fromList([...iv.bytes, ...encrypted.bytes]);

      // Get encrypted directory
      final encryptedDir = await _getEncryptedDirectory();

      // Generate unique encrypted filename
      final originalFileName = path.basename(originalFilePath);
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final encryptedFileName = 'enc_${timestamp}_$originalFileName.encrypted';
      final encryptedFilePath = '${encryptedDir.path}/$encryptedFileName';

      // Write encrypted file
      final encryptedFile = File(encryptedFilePath);
      await encryptedFile.writeAsBytes(encryptedData);

      // Delete original file
      await originalFile.delete();

      return encryptedFilePath;
    } catch (e) {
      print('Error encrypting file: $e');
      return null;
    }
  }

  // Decrypt and restore file to its original location
  static Future<String?> decryptAndRestoreFile(String encryptedFilePath, String originalPath) async {
    try {
      final encryptedFile = File(encryptedFilePath);
      if (!await encryptedFile.exists()) {
        throw Exception('Encrypted file does not exist');
      }

      // Read encrypted file
      final encryptedData = await encryptedFile.readAsBytes();

      // Extract IV and encrypted content
      final iv = IV(encryptedData.sublist(0, 16));
      final encryptedContent = encryptedData.sublist(16);

      // Get encryption key
      final keyString = await _getOrCreateKey();
      final key = Key.fromBase64(keyString);
      final encrypter = Encrypter(AES(key));

      // Decrypt content
      final encrypted = Encrypted(encryptedContent);
      final decryptedBytes = encrypter.decryptBytes(encrypted, iv: iv);

      // Ensure original directory exists
      final originalDir = Directory(path.dirname(originalPath));
      if (!await originalDir.exists()) {
        await originalDir.create(recursive: true);
      }

      // Write decrypted file to original location
      final restoredFile = File(originalPath);
      await restoredFile.writeAsBytes(decryptedBytes);

      // Delete encrypted file
      await encryptedFile.delete();

      return originalPath;
    } catch (e) {
      print('Error decrypting file: $e');
      return null;
    }
  }

  // Check if file is encrypted (helper method)
  static bool isEncryptedFile(String filePath) {
    return filePath.contains(_encryptedFolderName) && filePath.endsWith('.encrypted');
  }

  // Get all encrypted files
  static Future<List<File>> getEncryptedFiles() async {
    try {
      final encryptedDir = await _getEncryptedDirectory();
      if (!await encryptedDir.exists()) {
        return [];
      }

      final files = await encryptedDir.list().where((entity) =>
      entity is File && entity.path.endsWith('.encrypted')
      ).cast<File>().toList();

      return files;
    } catch (e) {
      print('Error getting encrypted files: $e');
      return [];
    }
  }

  // Clean up orphaned encrypted files (optional maintenance method)
  static Future<void> cleanUpOrphanedEncryptedFiles() async {
    try {
      final encryptedFiles = await getEncryptedFiles();
      // Add your logic here to clean up files that are no longer referenced in Hive
    } catch (e) {
      print('Error cleaning up encrypted files: $e');
    }
  }
}