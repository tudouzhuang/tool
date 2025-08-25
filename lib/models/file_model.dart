import 'package:hive_ce/hive.dart';

@HiveType(typeId: 1)
class FileModel {
  @HiveField(0)
  final String name;

  @HiveField(1)
  final String path;

  @HiveField(2)
  final DateTime date;

  @HiveField(3)
  final String size;

  @HiveField(4)
  bool isFavorite;

  @HiveField(5)
  bool isLocked;

  @HiveField(6)
  final String? originalPath; // Store original path when encrypted

  @HiveField(7)
  bool isEncrypted; // Track if file is encrypted

  FileModel({
    required this.name,
    required this.path,
    required this.date,
    required this.size,
    this.isFavorite = false,
    this.isLocked = false,
    this.originalPath,
    this.isEncrypted = false,
  });

  // Helper method to get the display path (original path if encrypted, otherwise current path)
  String get displayPath => isEncrypted && originalPath != null ? originalPath! : path;

  // Helper method to check if file actually exists in storage
  bool get existsInStorage => !isEncrypted;
}