import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:pdf/pdf.dart';
import 'package:archive/archive.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:image/image.dart' as img;
import 'package:pdfx/pdfx.dart' as pdfx;
import 'package:get/get.dart'; // Add this import for .tr extension

import 'compression_result_class.dart';

class FileCompressor {

  static Future<CompressionResult> compressFileWithStatus(File file, {int quality = 85}) async {
    final extension = path.extension(file.path).toLowerCase();

    try {
      switch (extension) {
        case '.jpg':
        case '.jpeg':
        case '.png':
          final result = await _compressImageWithStatus(file, quality: quality);
          return result;
        case '.pdf':
          final result = await compressPdfWithStatus(file, quality: quality);
          return result;
        case '.doc':
        case '.docx':
          final result = await _compressWordDocumentWithStatus(file);
          return result;
        case '.ppt':
        case '.pptx':
          final result = await _compressPptxWithStatus(file);
          return result;
        default:
          return CompressionResult(
              file: file,
              wasCompressed: false,
              message: 'file_type_not_supported'.tr,
              originalSize: 0,
              compressedSize: 0
          );
      }
    } catch (e) {
      return CompressionResult(
          file: file,
          wasCompressed: false,
          message: 'compression_error_occurred'.tr,
          compressedSize: 0,
          originalSize: 0
      );
    }
  }

  static Future<List<CompressionResult>> compressBatchWithStatus(List<File> files, {int quality = 85}) async {
    List<CompressionResult> results = [];

    for (var file in files) {
      try {
        CompressionResult result = await compressFileWithStatus(file, quality: quality);
        results.add(result);
      } catch (e) {
        results.add(CompressionResult(
            file: file,
            wasCompressed: false,
            message: 'processing_failed'.tr,
            compressedSize: 0,
            originalSize: 0
        ));
      }
    }

    return results;
  }

  static Future<List<File>> compressBatch(List<File> files, {int quality = 85}) async {
    List<File> compressedFiles = [];

    for (var file in files) {
      try {
        File? compressedFile = await compressFile(file, quality: quality);
        if (compressedFile != null) {
          compressedFiles.add(compressedFile);
        } else {
          compressedFiles.add(file);
        }
      } catch (e) {
        compressedFiles.add(file);
      }
    }

    return compressedFiles;
  }

  static Future<File?> compressFile(File file, {int quality = 85}) async {
    final result = await compressFileWithStatus(file, quality: quality);
    return result.file;
  }

  static Future<CompressionResult> _compressImageWithStatus(File file, {int quality = 85}) async {
    if (!file.existsSync()) {
      return CompressionResult(
        file: file,
        wasCompressed: false,
        message: 'file_not_found'.tr,
        originalSize: 0,
        compressedSize: 0,
      );
    }

    final dir = await getTemporaryDirectory();
    final filename = path.basenameWithoutExtension(file.path);
    final extension = path.extension(file.path).toLowerCase();
    final targetPath = path.join(dir.path, 'compressed_${filename}_$quality$extension');

    try {
      final format = extension == '.png'
          ? CompressFormat.png
          : CompressFormat.jpeg;

      var result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: quality,
        format: format,
        minWidth: 1080,
        minHeight: 1080,
        rotate: 0,
      );

      if (result == null) {
        return CompressionResult(
          file: file,
          wasCompressed: false,
          message: 'compression_failed'.tr,
          originalSize: 0,
          compressedSize: 0,
        );
      }

      final resultFile = File(result.path);
      if (!resultFile.existsSync() || resultFile.lengthSync() <= 0) {
        return CompressionResult(
            file: file,
            wasCompressed: false,
            message: 'compression_failed'.tr,
            originalSize: 0,
            compressedSize: 0
        );
      }
      final originalSize = file.lengthSync();
      final compressedSize = resultFile.lengthSync();
      final reduction = ((originalSize - compressedSize) / originalSize * 100);

      if (compressedSize >= originalSize) {
        await resultFile.delete();
        return CompressionResult(
            file: file,
            wasCompressed: false,
            message: 'file_already_compressed_optimized'.tr,
            compressedSize: originalSize,
            originalSize: originalSize
        );
      }

      if (reduction > 5) {
        return CompressionResult(
            file: resultFile,
            wasCompressed: true,
            message: 'compression_successful'.tr,
            compressedSize: compressedSize,
            originalSize: originalSize
        );
      } else {
        await resultFile.delete();
        return CompressionResult(
            file: file,
            wasCompressed: false,
            message: 'file_already_compressed'.tr,
            compressedSize: compressedSize,
            originalSize: originalSize
        );
      }
    } catch (e) {
      return CompressionResult(
          file: file,
          wasCompressed: false,
          message: 'compression_error_occurred'.tr,
          compressedSize: 0,
          originalSize: 0
      );
    }
  }

  static Future<CompressionResult> compressPdfWithStatus(File file, {int quality = 85}) async {
    if (!file.existsSync()) {
      return CompressionResult(
          file: file,
          wasCompressed: false,
          message: 'file_not_found'.tr,
          compressedSize: 0,
          originalSize: 0
      );
    }

    final dir = await getTemporaryDirectory();
    final filename = path.basenameWithoutExtension(file.path);
    final targetPath = path.join(dir.path, 'compressed_${filename}_$quality.pdf');

    pdfx.PdfDocument? pdfDocument;

    try {
      pdfDocument = await pdfx.PdfDocument.openFile(file.path);

      final pdf = pw.Document(compress: true);

      final originalSize = file.lengthSync();

      double scale;
      int imageQuality;

      if (originalSize < 50 * 1024) {
        scale = 0.6;
        imageQuality = (quality * 0.5).round();
      } else if (originalSize < 200 * 1024) {
        scale = 0.7;
        imageQuality = (quality * 0.6).round();
      } else if (originalSize < 1024 * 1024) {
        scale = 0.8;
        imageQuality = (quality * 0.7).round();
      } else {
        scale = quality / 100.0;
        imageQuality = quality;
      }

      imageQuality = imageQuality.clamp(25, 95);

      for (int i = 0; i < pdfDocument.pagesCount; i++) {
        final page = await pdfDocument.getPage(i + 1);

        final renderWidth = (page.width * scale).round().clamp(200, 2000);
        final renderHeight = (page.height * scale).round().clamp(200, 2000);

        final pageImage = await page.render(
          width: renderWidth.toDouble(),
          height: renderHeight.toDouble(),
          format: pdfx.PdfPageImageFormat.jpeg,
          backgroundColor: '#FFFFFF',
          quality: imageQuality,
        );

        await page.close();

        if (pageImage != null) {
          Uint8List compressedImageBytes = pageImage.bytes;

          if (originalSize < 100 * 1024) {
            compressedImageBytes = await _aggressiveImageCompression(pageImage.bytes, imageQuality);
          }

          final image = pw.MemoryImage(compressedImageBytes);
          pdf.addPage(
            pw.Page(
              pageFormat: PdfPageFormat(page.width, page.height, marginAll: 0),
              build: (pw.Context context) {
                return pw.Center(
                  child: pw.Image(image, fit: pw.BoxFit.contain),
                );
              },
            ),
          );
        }
      }

      final compressedPdfBytes = await pdf.save();
      final resultFile = File(targetPath);
      await resultFile.writeAsBytes(compressedPdfBytes);

      final compressedSize = resultFile.lengthSync();
      final reduction = ((originalSize - compressedSize) / originalSize * 100);

      if (compressedSize >= originalSize) {
        await resultFile.delete();
        return CompressionResult(
            file: file,
            wasCompressed: false,
            message: 'file_already_optimized'.tr,
            originalSize: originalSize,
            compressedSize: originalSize
        );
      } else if (reduction > 5) {
        return CompressionResult(
          file: resultFile,
          wasCompressed: true,
          message: 'compression_successful'.tr,
          originalSize: originalSize,
          compressedSize: compressedSize,
        );
      } else {
        await resultFile.delete();
        return CompressionResult(
          file: file,
          wasCompressed: false,
          message: 'pdf_already_optimized'.tr,
          originalSize: originalSize,
          compressedSize: compressedSize,
        );
      }
    } catch (e) {
      return CompressionResult(
        file: file,
        wasCompressed: false,
        message: 'compression_error_occurred'.tr,
        originalSize: 0,
        compressedSize: 0,
      );
    } finally {
      await pdfDocument?.close();
    }
  }

  static Future<File> compressPdf(File file, {int quality = 85}) async {
    final result = await compressPdfWithStatus(file, quality: quality);
    return result.file;
  }

  static Future<CompressionResult> _compressWordDocumentWithStatus(File file) async {
    final dir = await getTemporaryDirectory();
    final filename = path.basenameWithoutExtension(file.path);
    final extension = path.extension(file.path).toLowerCase();
    final targetPath = path.join(dir.path, 'compressed_$filename$extension');

    try {
      final bytes = await file.readAsBytes();

      final archive = ZipDecoder().decodeBytes(bytes);

      final newArchive = Archive();

      for (final fileEntry in archive.files) {
        if (fileEntry.isFile) {
          var content = fileEntry.content as List<int>;

          if (fileEntry.name.toLowerCase().contains('media/') ||
              _isImageFile(fileEntry.name)) {
            content = _compressImagefordocx(Uint8List.fromList(content), quality: 75);
          }

          newArchive.addFile(ArchiveFile(
            fileEntry.name,
            fileEntry.size,
            content,
          ));
        } else {
          newArchive.addFile(fileEntry);
        }
      }

      final compressed = ZipEncoder().encode(newArchive, level: 9);

      final resultFile = File(targetPath);
      await resultFile.writeAsBytes(compressed!);

      final originalSize = file.lengthSync();
      final compressedSize = resultFile.lengthSync();
      final reduction = ((originalSize - compressedSize) / originalSize * 100);

      if (reduction > 5) {
        return CompressionResult(
          file: resultFile,
          wasCompressed: true,
          message: 'compression_successful'.tr,
          compressedSize: compressedSize,
          originalSize: originalSize,
        );
      } else {
        await resultFile.delete();
        return CompressionResult(
            file: file,
            wasCompressed: false,
            message: 'document_already_optimized'.tr,
            originalSize: originalSize,
            compressedSize: compressedSize
        );
      }
    } catch (e) {
      return CompressionResult(
          file: file,
          wasCompressed: false,
          message: 'compression_error_occurred'.tr,
          compressedSize: 0,
          originalSize: 0
      );
    }
  }

  static Future<File> _compressWordDocument(File file) async {
    final result = await _compressWordDocumentWithStatus(file);
    return result.file;
  }

  static Future<CompressionResult> _compressPptxWithStatus(File file) async {
    final dir = await getTemporaryDirectory();
    final filename = path.basenameWithoutExtension(file.path);
    final extension = path.extension(file.path).toLowerCase();
    final targetPath = path.join(dir.path, 'compressed_$filename$extension');

    try {
      final bytes = await file.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);
      final optimized = Archive();

      for (final archiveFile in archive.files) {
        if (archiveFile.isFile) {
          if (archiveFile.name.startsWith('ppt/media/')) {
            final compressed = await _compressImageBytes(archiveFile.content as Uint8List);
            optimized.addFile(ArchiveFile(archiveFile.name, compressed.length, compressed));
          } else {
            optimized.addFile(archiveFile);
          }
        }
      }

      final compressedBytes = ZipEncoder().encode(optimized);
      final resultFile = File(targetPath);
      await resultFile.writeAsBytes(compressedBytes!);

      final originalSize = file.lengthSync();
      final compressedSize = resultFile.lengthSync();
      final reduction = ((originalSize - compressedSize) / originalSize * 100);

      if (reduction > 5) {
        return CompressionResult(
            file: resultFile,
            wasCompressed: true,
            message: 'compression_successful'.tr,
            compressedSize: compressedSize,
            originalSize: originalSize
        );
      } else {
        await resultFile.delete();
        return CompressionResult(
            file: file,
            wasCompressed: false,
            message: 'presentation_already_optimized'.tr,
            compressedSize: compressedSize,
            originalSize: originalSize
        );
      }
    } catch (e) {
      return CompressionResult(
          file: file,
          wasCompressed: false,
          message: 'compression_error_occurred'.tr,
          compressedSize: 0,
          originalSize: 0
      );
    }
  }

  static Future<File> _compressPptx(File file, String targetPath) async {
    final result = await _compressPptxWithStatus(file);
    return result.file;
  }

  static Future<Uint8List> _aggressiveImageCompression(Uint8List imageBytes, int quality) async {
    try {
      final image = img.decodeImage(imageBytes);
      if (image == null) return imageBytes;

      final resizedImage = img.copyResize(
        image,
        width: (image.width * 0.7).round(),
        height: (image.height * 0.7).round(),
        interpolation: img.Interpolation.average,
      );

      return Uint8List.fromList(img.encodeJpg(resizedImage, quality: quality.clamp(20, 60)));
    } catch (e) {
      return imageBytes;
    }
  }

  static Future<Uint8List> _compressImageBytes(Uint8List imageBytes, {int quality = 85}) async {
    try {
      final image = img.decodeImage(imageBytes);
      if (image == null) {
        return imageBytes;
      }

      final compressQuality = quality.clamp(1, 100);

      img.Image processedImage = image;
      if (quality < 50) {
        final scale = 0.5 + (quality / 100);
        processedImage = img.copyResize(
          image,
          width: (image.width * scale).round(),
          height: (image.height * scale).round(),
          interpolation: img.Interpolation.average,
        );
      }

      return Uint8List.fromList(img.encodeJpg(processedImage, quality: compressQuality));
    } catch (e) {
      return imageBytes;
    }
  }

  static bool _isImageFile(String filename) {
    final lower = filename.toLowerCase();
    return lower.endsWith('.png') ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg');
  }

  static Uint8List _compressImagefordocx(Uint8List imageData, {int quality = 75}) {
    try {
      final image = img.decodeImage(imageData);
      if (image == null) return imageData;

      return Uint8List.fromList(img.encodeJpg(image, quality: quality));
    } catch (e) {
      return imageData;
    }
  }

  static String _formatSizefordocx(int bytes) {
    if (bytes < 1024) return '$bytes ${'bytes'.tr}';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} ${'kb'.tr}';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} ${'mb'.tr}';
  }

  static String getReadableFileSize(int bytes) {
    if (bytes <= 0) return "0 ${'bytes'.tr}";

    final suffixes = ["bytes".tr, "kb".tr, "mb".tr, "gb".tr, "tb".tr];
    int i = 0;
    double size = bytes.toDouble();

    while (size >= 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }

    return "${size.toStringAsFixed(2)} ${suffixes[i]}";
  }
}