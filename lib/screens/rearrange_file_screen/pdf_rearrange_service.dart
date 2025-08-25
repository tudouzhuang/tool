import 'dart:io';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PdfRearrangeService {
  Future<List<pw.Document>> extractPages(File pdfFile) async {
    try {
      final bytes = await pdfFile.readAsBytes();
      List<pw.Document> pages = [];

      await for (final page in Printing.raster(bytes, dpi: 150)) {
        final pngBytes = await page.toPng();

        final docPage = pw.Document();
        docPage.addPage(
          pw.Page(
            build: (pw.Context context) {
              return pw.Image(
                pw.MemoryImage(pngBytes),
                fit: pw.BoxFit.contain,
              );
            },
          ),
        );

        pages.add(docPage);
      }

      return pages;
    } catch (e) {
      throw Exception('Error extracting PDF pages: $e');
    }
  }

  Future<File> createPdfFromPages(List<pw.Document> pages, String outputPath) async {
    try {
      final combinedDoc = pw.Document();

      for (final pageDoc in pages) {
        final pageBytes = await pageDoc.save();

        await for (final page in Printing.raster(pageBytes, dpi: 150)) {
          final pngBytes = await page.toPng();

          combinedDoc.addPage(
            pw.Page(
              build: (pw.Context context) {
                return pw.Image(
                  pw.MemoryImage(pngBytes),
                  fit: pw.BoxFit.contain,
                );
              },
            ),
          );
        }
      }

      final outputFile = File(outputPath);
      await outputFile.writeAsBytes(await combinedDoc.save());

      return outputFile;
    } catch (e) {
      throw Exception('Error creating PDF: $e');
    }
  }

  Future<int> getPageCount(File pdfFile) async {
    try {
      final bytes = await pdfFile.readAsBytes();
      int count = 0;

      await for (final _ in Printing.raster(bytes, dpi: 72)) {
        count++;
      }

      return count;
    } catch (e) {
      throw Exception('Error getting page count: $e');
    }
  }
}