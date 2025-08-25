import 'dart:io';
import 'dart:convert';
import 'dart:ui';
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive.dart';
import 'package:share_plus/share_plus.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class WordToPdfService {
  Future<File> convertWordToPdf(File wordFile) async {
    try {
      // Extract content from Word document
      String wordContent = await _extractWordContent(wordFile);

      // Get document metadata
      Map<String, dynamic> metadata = await _extractWordMetadata(wordFile);

      // Create PDF document
      final PdfDocument pdfDocument = PdfDocument();

      // Set document properties
      pdfDocument.documentInformation.title = metadata['title'] ?? 'Converted Word Document';
      pdfDocument.documentInformation.author = metadata['author'] ?? 'Word to PDF Converter';
      pdfDocument.documentInformation.subject = 'Converted from ${wordFile.path.split('/').last}';
      pdfDocument.documentInformation.creator = 'Flutter ToolKit App';

      // Create the first page
      PdfPage page = pdfDocument.pages.add();
      PdfGraphics graphics = page.graphics;

      // Set up fonts and styles
      PdfFont titleFont = PdfStandardFont(PdfFontFamily.helvetica, 16, style: PdfFontStyle.bold);
      PdfFont subtitleFont = PdfStandardFont(PdfFontFamily.helvetica, 12, style: PdfFontStyle.italic);
      PdfFont bodyFont = PdfStandardFont(PdfFontFamily.helvetica, 10);

      // Page margins and layout
      double margin = 40;
      double pageWidth = page.getClientSize().width;
      double pageHeight = page.getClientSize().height;
      double currentY = margin;

      // Add content
      currentY = await _addContentToPdf(graphics, wordContent, bodyFont, margin, pageWidth, pageHeight, currentY, pdfDocument);

      // Create output directory
      final directory = await getApplicationDocumentsDirectory();
      final outputDir = Directory('${directory.path}/converted_files');
      if (!await outputDir.exists()) {
        await outputDir.create(recursive: true);
      }

      // Generate output filename
      final originalName = wordFile.path.split('/').last.replaceAll(RegExp(r'\.(docx?|rtf)$'), '');
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = '${outputDir.path}/converted_${originalName}_$timestamp.pdf';

      // Save the PDF
      final file = File(filePath);
      await file.writeAsBytes(await pdfDocument.save());

      // Dispose the document
      pdfDocument.dispose();

      return file;
    } catch (e) {
      throw Exception('Failed to convert Word to PDF: ${e.toString()}');
    }
  }

  Future<String> _extractWordContent(File wordFile) async {
    try {
      // Read the Word file as bytes
      final bytes = await wordFile.readAsBytes();

      // Extract the ZIP archive
      final archive = ZipDecoder().decodeBytes(bytes);

      // Find and extract the main document content
      ArchiveFile? documentFile;
      for (final file in archive) {
        if (file.name == 'word/document.xml') {
          documentFile = file;
          break;
        }
      }

      if (documentFile == null) {
        throw Exception('Invalid Word document format');
      }

      // Parse the XML content
      final xmlContent = utf8.decode(documentFile.content as List<int>);

      // Extract text from XML (basic implementation)
      return _parseWordXmlContent(xmlContent);
    } catch (e) {
      throw Exception('Failed to extract Word content: ${e.toString()}');
    }
  }

  String _parseWordXmlContent(String xmlContent) {
    // Basic XML text extraction - removes XML tags and extracts text content
    // This is a simplified approach; for production, consider using a proper XML parser

    String content = xmlContent;

    // Remove XML declarations and namespaces
    content = content.replaceAll(RegExp(r'<\?xml[^>]*\?>'), '');
    content = content.replaceAll(RegExp(r'xmlns[^=]*="[^"]*"'), '');

    // Extract text from <w:t> tags (Word text elements)
    final textRegex = RegExp(r'<w:t[^>]*>(.*?)</w:t>', dotAll: true);
    final matches = textRegex.allMatches(content);

    StringBuffer extractedText = StringBuffer();
    for (final match in matches) {
      String text = match.group(1) ?? '';
      // Decode XML entities
      text = text.replaceAll('&amp;', '&')
          .replaceAll('&lt;', '<')
          .replaceAll('&gt;', '>')
          .replaceAll('&quot;', '"')
          .replaceAll('&apos;', "'");
      extractedText.write(text);
      extractedText.write(' ');
    }

    // Clean up the text
    String result = extractedText.toString();
    result = result.replaceAll(RegExp(r'\s+'), ' ').trim();

    // FIXED: Add paragraph breaks where appropriate using proper callback function
    result = result.replaceAllMapped(RegExp(r'([.!?])\s+([A-Z])'), (match) {
      return '${match.group(1)}\n\n${match.group(2)}';
    });

    return result.isEmpty ? 'No text content found in the document.' : result;
  }

  Future<Map<String, dynamic>> _extractWordMetadata(File wordFile) async {
    try {
      final bytes = await wordFile.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      // Look for document properties
      Map<String, dynamic> metadata = {};

      for (final file in archive) {
        if (file.name == 'docProps/core.xml') {
          final xmlContent = utf8.decode(file.content as List<int>);

          // Extract basic metadata (simplified)
          final titleMatch = RegExp(r'<dc:title[^>]*>(.*?)</dc:title>').firstMatch(xmlContent);
          final authorMatch = RegExp(r'<dc:creator[^>]*>(.*?)</dc:creator>').firstMatch(xmlContent);

          if (titleMatch != null) metadata['title'] = titleMatch.group(1);
          if (authorMatch != null) metadata['author'] = authorMatch.group(1);
          break;
        }
      }

      return metadata;
    } catch (e) {
      return {};
    }
  }

  Future<double> _addContentToPdf(PdfGraphics graphics, String content, PdfFont font,
      double margin, double pageWidth, double pageHeight, double startY, PdfDocument document) async {

    double currentY = startY;
    double lineHeight = font.height + 5;
    double availableWidth = pageWidth - 2 * margin;
    double bottomMargin = 40;

    // Split content into paragraphs
    List<String> paragraphs = content.split('\n\n');

    for (String paragraph in paragraphs) {
      if (paragraph.trim().isEmpty) continue;

      // Word wrap the paragraph
      List<String> lines = _wrapText(paragraph, font, availableWidth);

      for (String line in lines) {
        // Check if we need a new page
        if (currentY + lineHeight > pageHeight - bottomMargin) {
          // Add new page
          PdfPage newPage = document.pages.add();
          graphics = newPage.graphics;
          currentY = margin;
        }

        // Draw the line
        graphics.drawString(line, font,
            bounds: Rect.fromLTWH(margin, currentY, availableWidth, lineHeight));
        currentY += lineHeight;
      }

      // Add extra space after paragraph
      currentY += 10;
    }

    return currentY;
  }

  List<String> _wrapText(String text, PdfFont font, double maxWidth) {
    List<String> lines = [];
    List<String> words = text.split(' ');
    String currentLine = '';

    for (String word in words) {
      String testLine = currentLine.isEmpty ? word : '$currentLine $word';
      Size textSize = font.measureString(testLine);

      if (textSize.width <= maxWidth) {
        currentLine = testLine;
      } else {
        if (currentLine.isNotEmpty) {
          lines.add(currentLine);
          currentLine = word;
        } else {
          // Word is too long, add it anyway
          lines.add(word);
        }
      }
    }

    if (currentLine.isNotEmpty) {
      lines.add(currentLine);
    }

    return lines;
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> shareDocument(File file) async {
    try {
      await Share.shareXFiles([XFile(file.path)],
          text: 'Check out this PDF document');
    } catch (e) {
      throw Exception('Failed to share document: ${e.toString()}');
    }
  }
}