import 'package:hive_ce/hive.dart';

import 'file_model.dart';

class FileModelAdapter extends TypeAdapter<FileModel> {
  @override
  final int typeId = 1; // Use a unique typeId (different from other adapters)

  @override
  FileModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };

    return FileModel(
      name: fields[0] as String,
      path: fields[1] as String,
      date: fields[2] as DateTime,
      size: fields[3] as String,
      isFavorite: fields[4] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, FileModel obj) {
    writer
      ..writeByte(5) // Number of fields
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.path)
      ..writeByte(2)
      ..write(obj.date)
      ..writeByte(3)
      ..write(obj.size)
      ..writeByte(4)
      ..write(obj.isFavorite);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FileModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
