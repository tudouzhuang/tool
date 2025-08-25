import 'dart:io';

class CompressionResult {
  final File file;
  final bool wasCompressed;
  final String message;
  final int originalSize;
  final int compressedSize;

  CompressionResult({
    required this.file,
    required this.wasCompressed,
    required this.message,
    required this.originalSize,
    required this.compressedSize,
  });
}