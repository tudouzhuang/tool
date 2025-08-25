import 'dart:typed_data';
import 'package:hive_ce/hive.dart';
import '../models/saved_cv.dart';

class SavedCVAdapter extends TypeAdapter<SavedCV> {
  @override
  final int typeId = 0;

  @override
  SavedCV read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };

    // Convert Map<dynamic, dynamic> to Map<String, dynamic>
    Map<String, dynamic> formData = {};
    if (fields[7] != null) {
      final rawFormData = fields[7] as Map<dynamic, dynamic>;
      formData = rawFormData.map((key, value) => MapEntry(key.toString(), value));
    }

    return SavedCV(
      id: fields[0] as String,
      fileName: fields[1] as String,
      dateTime: fields[2] as String,
      fileSize: fields[3] as String,
      thumbnailBytes: fields[4] as Uint8List?,
      filePath: fields[5] as String,
      templateId: fields[6] as int,
      formData: formData,
    );
  }

  @override
  void write(BinaryWriter writer, SavedCV obj) {
    writer
      ..writeByte(8) // number of fields
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.fileName)
      ..writeByte(2)
      ..write(obj.dateTime)
      ..writeByte(3)
      ..write(obj.fileSize)
      ..writeByte(4)
      ..write(obj.thumbnailBytes)
      ..writeByte(5)
      ..write(obj.filePath)
      ..writeByte(6)
      ..write(obj.templateId)
      ..writeByte(7)
      ..write(obj.formData);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is SavedCVAdapter &&
              runtimeType == other.runtimeType &&
              typeId == other.typeId;
}