import 'dart:io';
import 'dart:math';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:xml/xml.dart';

class DocxPage {
  final String pageXml;
  final String previewText;

  DocxPage({required this.pageXml, required this.previewText});
}

class SplitDocumentResult {
  final int startPage;
  final int endPage;
  final String filePath;
  final String previewText;

  SplitDocumentResult({
    required this.startPage,
    required this.endPage,
    required this.filePath,
    required this.previewText,
  });
}

class DocxSplitterService {
  Future<List<DocxPage>> extractPages(File docxFile) async {
    try {
      final bytes = await docxFile.readAsBytes();

      final archive = ZipDecoder().decodeBytes(bytes);

      if (archive.files.isEmpty) {
        throw Exception(
            "Could not read the file as a ZIP archive. The file might be corrupted.");
      }

      final documentEntry = archive.findFile('word/document.xml');
      if (documentEntry == null) {
        final filesList = archive.files.map((f) => f.name).join(', ');
        throw Exception(
            "Invalid DOCX file: document.xml not found. Files in archive: $filesList");
      }

      final documentContent = documentEntry.content as List<int>;
      if (documentContent.isEmpty) {
        throw Exception("Document content is empty");
      }

      final documentString = String.fromCharCodes(documentContent);

      final xmlDocument = XmlDocument.parse(documentString);

      final bodyElements = xmlDocument.findAllElements('w:body');
      if (bodyElements.isEmpty) {
        throw Exception("Invalid DOCX structure: w:body element not found");
      }

      final bodyElement = bodyElements.first;

      final paragraphs = bodyElement.findAllElements('w:p').toList();
      if (paragraphs.isEmpty) {
        final allText =
        xmlDocument.findAllElements('w:t').map((e) => e.text).join(' ');
        if (allText.isNotEmpty) {
          throw Exception(
              "No paragraphs found, but document contains text: ${allText.substring(0, min(50, allText.length))}...");
        } else {
          throw Exception(
              "No paragraphs or text content found in the document");
        }
      }

      List<DocxPage> pages = [];
      List<XmlElement> currentPageParagraphs = [];

      for (final paragraph in paragraphs) {
        currentPageParagraphs.add(paragraph);

        final pageBreaks = paragraph
            .findAllElements('w:br')
            .where((br) => br.getAttribute('w:type') == 'page')
            .toList();

        final hasPageBreak = pageBreaks.isNotEmpty;

        if (hasPageBreak ||
            (currentPageParagraphs.length >= 5 &&
                pages.length < paragraphs.length ~/ 5)) {
          final pageXml = _buildPageXml(currentPageParagraphs);
          final previewText = _extractPreviewText(currentPageParagraphs);

          pages.add(DocxPage(
            pageXml: pageXml,
            previewText: previewText,
          ));

          currentPageParagraphs = [];
        }
      }

      if (currentPageParagraphs.isNotEmpty) {
        final pageXml = _buildPageXml(currentPageParagraphs);
        final previewText = _extractPreviewText(currentPageParagraphs);

        pages.add(DocxPage(
          pageXml: pageXml,
          previewText: previewText,
        ));
      }

      if (pages.isEmpty && paragraphs.isNotEmpty) {
        final pageXml = _buildPageXml(paragraphs);
        final previewText = _extractPreviewText(paragraphs);

        pages.add(DocxPage(
          pageXml: pageXml,
          previewText: previewText,
        ));
      }

      return pages;
    } catch (e, stackTrace) {
      print("Error extracting pages: $e");
      print("Stack trace: $stackTrace");
      rethrow;
    }
  }

  Future<File> rearrangeDocxPages(File originalFile, List<int> newPageOrder) async {
    try {
      final pages = await extractPages(originalFile);

      if (newPageOrder.any((index) => index >= pages.length)) {
        throw Exception('Invalid page order - index out of bounds');
      }

      final pageRanges = newPageOrder.map((index) => [index]).toList();

      final results = await splitDocxByRanges(originalFile, pageRanges);

      if (results.isEmpty) {
        throw Exception('No pages were processed');
      }

      return File(results.first.filePath);
    } catch (e) {
      print('Error rearranging DOCX pages: $e');
      rethrow;
    }
  }

  Future<File> createDocumentFromPages(List<dynamic> pages, String outputPath) async {
    await Future.delayed(const Duration(seconds: 3));

    final outputFile = File(outputPath);
    await outputFile.writeAsString('This is a rearranged document with ${pages.length} pages.');

    return outputFile;
  }


  String _extractPreviewText(List<XmlElement> paragraphs) {
    final buffer = StringBuffer();

    for (final paragraph in paragraphs) {
      for (final textElement in paragraph.findAllElements('w:t')) {
        buffer.write(textElement.text);
      }
      buffer.write(' ');
    }

    final fullText = buffer.toString().trim();
    return fullText.length > 50 ? '${fullText.substring(0, 47)}...' : fullText;
  }

  Future<File> createDocumentFromPagesWithOriginal(
      List<DocxPage> pages,
      String outputPath,
      File originalFile
      ) async {
    try {
      if (pages.isEmpty) {
        throw Exception("No pages provided for document creation");
      }

      final originalBytes = await originalFile.readAsBytes();
      final originalArchive = ZipDecoder().decodeBytes(originalBytes);
      final newArchive = Archive();

      for (final file in originalArchive.files) {
        if (!file.isFile || file.name == 'word/document.xml') continue;
        newArchive.addFile(ArchiveFile(file.name, file.size, file.content));
      }

      final combinedXml = combinePages(pages);
      final docFile = ArchiveFile(
        'word/document.xml',
        combinedXml.length,
        combinedXml.codeUnits,
      );
      newArchive.addFile(docFile);

      final docxBytes = ZipEncoder().encode(newArchive);
      if (docxBytes == null) {
        throw Exception("Failed to encode DOCX file");
      }

      final outputFile = File(outputPath);
      await outputFile.writeAsBytes(docxBytes);

      if (!await outputFile.exists()) {
        throw Exception("Output file was not created");
      }

      print("Successfully created DOCX: $outputPath");
      return outputFile;

    } catch (e) {
      print("Error creating document: $e");
      final outputFile = File(outputPath);
      await originalFile.copy(outputPath);
      return outputFile;
    }
  }

  String _buildPageXml(List<XmlElement> paragraphs) {
    const xmlHeader =
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n';
    const namespaces = '''
      xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"
      xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"
      xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"
      xmlns:m="http://schemas.openxmlformats.org/wordprocessingml/2006/math"
      xmlns:v="urn:schemas-microsoft-com:vml"
      xmlns:wp="http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing"
      xmlns:w10="urn:schemas-microsoft-com:office:word"
      xmlns:wp14="http://schemas.microsoft.com/office/word/2010/wordprocessingDrawing"
      xmlns:wpg="http://schemas.microsoft.com/office/word/2010/wordprocessingGroup"
      xmlns:wpi="http://schemas.microsoft.com/office/word/2010/wordprocessingInk"
      xmlns:wne="http://schemas.microsoft.com/office/word/2006/wordml"
      xmlns:wps="http://schemas.microsoft.com/office/word/2010/wordprocessingShape"
    ''';

    const documentOpen = '<w:document $namespaces>\n';
    const documentClose = '</w:document>';
    const bodyOpen = '<w:body>\n';
    const bodyClose = '</w:body>\n';

    String pageContent = '';
    for (final paragraph in paragraphs) {
      pageContent += '${paragraph.toXmlString()}\n';
    }

    return xmlHeader +
        documentOpen +
        bodyOpen +
        pageContent +
        bodyClose +
        documentClose;
  }
  Future<List<SplitDocumentResult>> splitDocxByRanges(
      File docxFile, List<List<int>> rangesList) async {
    try {
      final pages = await extractPages(docxFile);

      final bytes = await docxFile.readAsBytes();
      final originalArchive = ZipDecoder().decodeBytes(bytes);

      final outputDir = await _createOutputDirectory();
      final fileName = path.basenameWithoutExtension(docxFile.path);

      List<SplitDocumentResult> results = [];

      for (int i = 0; i < rangesList.length; i++) {
        final pageIndices = rangesList[i];
        if (pageIndices.isEmpty) continue;

        final startPage = pageIndices.first + 1;
        final endPage = pageIndices.last + 1;

        final newArchive = Archive();

        for (final file in originalArchive.files) {
          if (!file.isFile) continue;

          if (file.name == 'word/document.xml') {
            continue;
          }

          newArchive.addFile(ArchiveFile(
            file.name,
            file.size,
            file.content,
          ));
        }

        final combinedPagesXml = combinePages(
          pageIndices.map((index) => pages[index]).toList(),
        );

        final docFile = ArchiveFile(
          'word/document.xml',
          combinedPagesXml.length,
          combinedPagesXml.codeUnits,
        );
        newArchive.addFile(docFile);

        final newDocxBytes = ZipEncoder().encode(newArchive);
        if (newDocxBytes == null) {
          throw Exception("Failed to encode the new DOCX file");
        }

        final outputPath = path.join(
          outputDir.path,
          '${fileName}_pages_$startPage-$endPage.docx',
        );
        await File(outputPath).writeAsBytes(newDocxBytes);

        String previewText = "Content from pages $startPage-$endPage";
        if (pageIndices.length == 1) {
          previewText = pages[pageIndices[0]].previewText;
        } else {
          previewText += ": ${pages[pageIndices[0]].previewText}";
        }

        results.add(SplitDocumentResult(
          startPage: startPage,
          endPage: endPage,
          filePath: outputPath,
          previewText: previewText,
        ));
      }

      return results;
    } catch (e, stackTrace) {
      print("Error splitting document by ranges: $e");
      print("Stack trace: $stackTrace");
      rethrow;
    }
  }
  String combinePages(List<DocxPage> pages) {
    if (pages.isEmpty) {
      throw Exception("No pages to combine");
    }

    final firstPageXml = XmlDocument.parse(pages[0].pageXml);

    final bodyElements = firstPageXml.findAllElements('w:body');
    if (bodyElements.isEmpty) {
      throw Exception("Invalid document structure: w:body element not found");
    }

    final bodyElement = bodyElements.first;

    bodyElement.children.clear();

    for (int i = 0; i < pages.length; i++) {
      final page = pages[i];
      final pageDoc = XmlDocument.parse(page.pageXml);

      final paragraphs = pageDoc.findAllElements('w:p');

      for (final paragraph in paragraphs) {
        if (paragraph.parent != null) {
          paragraph.remove();
        }

        bodyElement.children.add(paragraph);
      }

      if (i < pages.length - 1) {
        final pageBreakPara = XmlElement(
          XmlName('w:p'),
          [],
          [
            XmlElement(
              XmlName('w:r'),
              [],
              [
                XmlElement(
                  XmlName('w:br'),
                  [XmlAttribute(XmlName('w:type'), 'page')],
                  [],
                ),
              ],
            ),
          ],
        );

        bodyElement.children.add(pageBreakPara);
      }
    }

    return firstPageXml.toXmlString();
  }
  Future<Directory> _createOutputDirectory() async {
    final tempDir = await getTemporaryDirectory();
    final outputDir = Directory(path.join(
        tempDir.path, 'docx_splits_${DateTime.now().millisecondsSinceEpoch}'));

    if (!await outputDir.exists()) {
      await outputDir.create(recursive: true);
    }

    return outputDir;
  }
}