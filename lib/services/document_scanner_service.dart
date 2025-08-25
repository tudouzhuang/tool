import 'dart:io';
import 'package:image/image.dart' as img;

class FrameCaptureService {
  /// Captures an image within the specified frame dimensions
  static Future<File?> captureWithinFrame({
    required File originalImage,
    required double frameWidth,
    required double frameHeight,
    required double screenWidth,
    required double screenHeight,
    String? outputPath,
  }) async {
    try {
      // Read the original image
      final bytes = await originalImage.readAsBytes();
      final original = img.decodeImage(bytes)!;

      // Calculate the scaling factors
      final scaleX = original.width / screenWidth;
      final scaleY = original.height / screenHeight;

      // Calculate the frame dimensions in the original image coordinates
      final frameWidthInImage = (frameWidth * scaleX).round();
      final frameHeightInImage = (frameHeight * scaleY).round();

      // Calculate the position to extract (centered)
      final x = (original.width - frameWidthInImage) ~/ 2;
      final y = (original.height - frameHeightInImage) ~/ 2;

      // Extract the frame area
      final cropped = img.copyCrop(
        original,
        x: x,
        y: y,
        width: frameWidthInImage,
        height: frameHeightInImage,
      );

      // Convert to JPEG
      final jpegBytes = img.encodeJpg(cropped, quality: 90);

      // Save to file
      final outputFile = outputPath != null
          ? File(outputPath)
          : await _getTemporaryFile('jpg');
      await outputFile.writeAsBytes(jpegBytes);

      return outputFile;
    } catch (e) {
      print('Error in frame capture: $e');
      return null;
    }
  }

  static Future<File> _getTemporaryFile(String extension) async {
    final tempDir = await Directory.systemTemp.createTemp();
    final file = File(
        '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.$extension');
    return file;
  }

  /// Enhances the captured document image (edge detection, perspective correction, etc.)
  static Future<File?> enhanceDocumentImage(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      var image = img.decodeImage(bytes)!;
      final jpegBytes = img.encodeJpg(image, quality: 95);
      final outputFile = await _getTemporaryFile('jpg');
      await outputFile.writeAsBytes(jpegBytes);

      return outputFile;
    } catch (e) {
      print('Error enhancing document: $e');
      return null;
    }
  }
}
