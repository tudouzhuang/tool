import 'dart:io';

class DocumentItem {
  final String name;
  final DateTime date;
  final double sizeInMB;
  final File file;
  final List<bool> selectedPages;

  DocumentItem({
    required this.name,
    required this.date,
    required this.sizeInMB,
    required this.file,
    List<bool>? selectedPages,
  }) : selectedPages = selectedPages ?? [];
}