// import 'dart:typed_data';
//
// class SavedCV {
//   final String id;
//   final String fileName;
//   final String dateTime;
//   final String fileSize;
//   final Uint8List? thumbnailBytes;
//   final String filePath;
//   final int templateId; // Add this
//   final Map<String, dynamic> formData; // Add this to store all CV data
//
//   SavedCV({
//     required this.id,
//     required this.fileName,
//     required this.dateTime,
//     required this.fileSize,
//     this.thumbnailBytes,
//     required this.filePath,
//     required this.templateId, // Add this
//     required this.formData, // Add this
//   });
//
//   Map<String, dynamic> toMap() {
//     return {
//       'id': id,
//       'fileName': fileName,
//       'dateTime': dateTime,
//       'fileSize': fileSize,
//       'filePath': filePath,
//       'templateId': templateId,
//       'formData': formData,
//     };
//   }
//
//   factory SavedCV.fromMap(Map<String, dynamic> map, {Uint8List? thumbBytes}) {
//     return SavedCV(
//       id: map['id'],
//       fileName: map['fileName'],
//       dateTime: map['dateTime'],
//       fileSize: map['fileSize'],
//       filePath: map['filePath'],
//       thumbnailBytes: thumbBytes,
//       templateId: map['templateId'] ?? 1, // Default to template 1
//       formData: map['formData'] ?? {}, // Default to empty map
//     );
//   }
// }
import 'dart:typed_data';
import 'package:hive_ce/hive.dart';

@HiveType(typeId: 0)
class SavedCV extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String fileName;

  @HiveField(2)
  final String dateTime;

  @HiveField(3)
  final String fileSize;

  @HiveField(4)
  final Uint8List? thumbnailBytes;

  @HiveField(5)
  final String filePath;

  @HiveField(6)
  final int templateId;

  @HiveField(7)
  final Map<String, dynamic> formData;

  SavedCV({
    required this.id,
    required this.fileName,
    required this.dateTime,
    required this.fileSize,
    this.thumbnailBytes,
    required this.filePath,
    required this.templateId,
    required this.formData,
  });

  @override
  String toString() {
    return 'SavedCV{id: $id, fileName: $fileName, dateTime: $dateTime, fileSize: $fileSize, templateId: $templateId}';
  }

  SavedCV copyWith({
    String? id,
    String? fileName,
    String? dateTime,
    String? fileSize,
    Uint8List? thumbnailBytes,
    String? filePath,
    int? templateId,
    Map<String, dynamic>? formData,
  }) {
    return SavedCV(
      id: id ?? this.id,
      fileName: fileName ?? this.fileName,
      dateTime: dateTime ?? this.dateTime,
      fileSize: fileSize ?? this.fileSize,
      thumbnailBytes: thumbnailBytes ?? this.thumbnailBytes,
      filePath: filePath ?? this.filePath,
      templateId: templateId ?? this.templateId,
      formData: formData ?? this.formData,
    );
  }
}