import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:archive/archive.dart';
import 'package:xml/xml.dart';
import 'package:path_provider/path_provider.dart';

class WordToImageService {

  Future<File> convertWordToImage(File wordFile, {
    int width = 800,
    int height = 1200,
    double fontSize = 16.0,
    String outputFormat = 'jpg',
  }) async {
    try {
      // Read the Word file
      final bytes = await wordFile.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      // Extract text content from the Word document
      String textContent = await _extractTextFromDocx(archive);

      // Create image from text
      final imageBytes = await _createImageFromText(
          textContent,
          width,
          height,
          fontSize,
          outputFormat == 'jpg'
      );

      // Create output file path
      final outputDir = await getTemporaryDirectory();
      final fileName = wordFile.path.split('/').last.replaceAll('.docx', '.$outputFormat');
      final outputFile = File('${outputDir.path}/$fileName');

      await outputFile.writeAsBytes(imageBytes);

      return outputFile;

    } catch (e) {
      throw Exception('Failed to convert Word to Image: $e');
    }
  }

  /// Converts Word document to multiple images (one per page simulation)
  Future<List<File>> convertWordToMultipleImages(File wordFile, {
    int width = 800,
    int height = 1200,
    double fontSize = 16.0,
    int linesPerPage = 45,
    bool createZip = true,
  }) async {
    try {
      final bytes = await wordFile.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      String textContent = await _extractTextFromDocx(archive);

      // Calculate characters per line based on width and font size
      final charsPerLine = (width / (fontSize * 0.6)).floor();
      final lines = _wrapText(textContent, charsPerLine);

      List<File> imageFiles = [];
      final outputDir = await getTemporaryDirectory();
      final baseFileName = wordFile.path.split('/').last.replaceAll('.docx', '');

      // Split text into pages
      for (int pageIndex = 0; pageIndex < lines.length; pageIndex += linesPerPage) {
        final pageLines = lines.skip(pageIndex).take(linesPerPage).toList();
        final pageText = pageLines.join('\n');

        // Create image for this page
        final imageBytes = await _createImageFromText(
            pageText,
            width,
            height,
            fontSize,
            true // Always use JPG for multiple pages
        );

        // Save page image
        final pageFileName = '${baseFileName}_page_${(pageIndex ~/ linesPerPage) + 1}.jpg';
        final pageFile = File('${outputDir.path}/$pageFileName');

        await pageFile.writeAsBytes(imageBytes);
        imageFiles.add(pageFile);
      }

      // Create ZIP file if requested and multiple pages exist
      if (createZip && imageFiles.length > 1) {
        final zipFile = await _createZipFile(imageFiles, baseFileName);
        return [zipFile];
      }

      return imageFiles;

    } catch (e) {
      throw Exception('Failed to convert Word to multiple images: $e');
    }
  }

  /// Creates a ZIP file containing all image files
  Future<File> _createZipFile(List<File> imageFiles, String baseName) async {
    try {
      final outputDir = await getTemporaryDirectory();
      final zipFile = File('${outputDir.path}/${baseName}_pages.zip');

      final encoder = ZipEncoder();
      final archive = Archive();

      for (final imageFile in imageFiles) {
        final imageBytes = await imageFile.readAsBytes();
        final fileName = imageFile.path.split('/').last;
        archive.addFile(ArchiveFile(fileName, imageBytes.length, imageBytes));
      }

      final zipBytes = encoder.encode(archive);
      await zipFile.writeAsBytes(zipBytes!);

      // Clean up individual image files
      for (final imageFile in imageFiles) {
        if (await imageFile.exists()) {
          await imageFile.delete();
        }
      }

      return zipFile;
    } catch (e) {
      throw Exception('Failed to create ZIP file: $e');
    }
  }

  /// Creates an image from text using Flutter's text rendering
  Future<Uint8List> _createImageFromText(
      String text,
      int width,
      int height,
      double fontSize,
      bool isJpg
      ) async {
    // Create a custom painter to render text
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Fill background
    final backgroundPaint = Paint()..color = Colors.white;
    canvas.drawRect(Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()), backgroundPaint);

    // Create text painter
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: Colors.black,
          fontSize: fontSize,
          fontFamily: 'Arial',
          height: 1.4, // Line height
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.left,
    );

    // Layout the text with constraints
    textPainter.layout(maxWidth: width - 80.0); // 40px padding on each side

    // Draw the text on canvas
    textPainter.paint(canvas, const Offset(40, 40)); // 40px padding from top-left

    // Convert to image
    final picture = recorder.endRecording();
    final image = await picture.toImage(width, height);
    final byteData = await image.toByteData(
        format: isJpg ? ui.ImageByteFormat.png : ui.ImageByteFormat.png
    );

    return byteData!.buffer.asUint8List();
  }

  /// Extracts all embedded images from Word document
  Future<List<File>> extractImagesFromWord(File wordFile) async {
    try {
      final bytes = await wordFile.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      List<File> extractedImages = [];
      final outputDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      // Find all media files (images) in the archive
      for (final file in archive) {
        if (file.name.startsWith('word/media/') && file.isFile) {
          final extension = _getFileExtension(file.name);
          if (_isImageFile(extension)) {
            final imageName = 'extracted_${timestamp}_${extractedImages.length + 1}.$extension';
            final imagePath = '${outputDir.path}/$imageName';

            final imageFile = File(imagePath);
            await imageFile.writeAsBytes(file.content as List<int>);
            extractedImages.add(imageFile);
          }
        }
      }

      return extractedImages;
    } catch (e) {
      throw Exception('Failed to extract images from Word: $e');
    }
  }

  /// Shares the converted image document
  Future<void> shareDocument(File imageFile) async {
    try {
      await Share.shareXFiles(
        [XFile(imageFile.path)],
        text: 'Converted Image from Word Document',
      );
    } catch (e) {
      throw Exception('Failed to share image: $e');
    }
  }

  /// Shares multiple image files or ZIP file
  Future<void> shareMultipleDocuments(List<File> files) async {
    try {
      final xFiles = files.map((file) => XFile(file.path)).toList();
      await Share.shareXFiles(
        xFiles,
        text: 'Converted Images from Word Document',
      );
    } catch (e) {
      throw Exception('Failed to share files: $e');
    }
  }

  /// Gets the file size in a readable format
  String getFormattedFileSize(File file) {
    final bytes = file.lengthSync();
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Gets total size of multiple files
  String getFormattedTotalSize(List<File> files) {
    final totalBytes = files.fold<int>(0, (sum, file) => sum + file.lengthSync());
    if (totalBytes < 1024) return '$totalBytes B';
    if (totalBytes < 1024 * 1024) return '${(totalBytes / 1024).toStringAsFixed(1)} KB';
    return '${(totalBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  // Private helper methods

  Future<String> _extractTextFromDocx(Archive archive) async {
    try {
      // Find document.xml
      for (final file in archive) {
        if (file.name == 'word/document.xml') {
          final xmlContent = utf8.decode(file.content as List<int>);
          final document = XmlDocument.parse(xmlContent);

          // Extract text from all <w:t> elements with better formatting
          final textElements = document.findAllElements('w:t');
          final paragraphs = document.findAllElements('w:p');

          final textBuffer = StringBuffer();

          for (final paragraph in paragraphs) {
            final textInParagraph = paragraph.findAllElements('w:t');
            if (textInParagraph.isNotEmpty) {
              for (final textElement in textInParagraph) {
                textBuffer.write(textElement.innerText);
              }
              textBuffer.write('\n\n'); // Add paragraph break
            }
          }

          final result = textBuffer.toString().trim();
          return result.isEmpty ? 'No text content found in document' : result;
        }
      }

      return 'No document.xml found in Word file';
    } catch (e) {
      return 'Error extracting text: $e';
    }
  }

  List<String> _wrapText(String text, int maxCharsPerLine) {
    final lines = <String>[];
    final paragraphs = text.split('\n');

    for (final paragraph in paragraphs) {
      if (paragraph.trim().isEmpty) {
        lines.add(''); // Empty line for paragraph breaks
        continue;
      }

      final words = paragraph.split(' ');
      StringBuffer currentLine = StringBuffer();

      for (final word in words) {
        if (currentLine.length + word.length + 1 <= maxCharsPerLine) {
          if (currentLine.isNotEmpty) currentLine.write(' ');
          currentLine.write(word);
        } else {
          if (currentLine.isNotEmpty) {
            lines.add(currentLine.toString());
            currentLine = StringBuffer();
          }

          // Handle very long words
          if (word.length > maxCharsPerLine) {
            // Split long words
            for (int i = 0; i < word.length; i += maxCharsPerLine) {
              lines.add(word.substring(i, (i + maxCharsPerLine).clamp(0, word.length)));
            }
          } else {
            currentLine.write(word);
          }
        }
      }

      if (currentLine.isNotEmpty) {
        lines.add(currentLine.toString());
      }
    }

    return lines;
  }

  String _getFileExtension(String filename) {
    return filename.split('.').last.toLowerCase();
  }

  bool _isImageFile(String extension) {
    return ['jpg', 'jpeg', 'png'].contains(extension);
  }
}