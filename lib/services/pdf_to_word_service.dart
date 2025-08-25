import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive.dart';
import 'package:share_plus/share_plus.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class PdfToWordService {
  Future<File> convertPdfToWord(File pdfFile) async {
    try {
      // Extract text content from PDF using Syncfusion PDF
      final PdfDocument document = PdfDocument(inputBytes: pdfFile.readAsBytesSync());
      String pdfText = '';

      // Extract text from each page
      for (int i = 0; i < document.pages.count; i++) {
        PdfTextExtractor extractor = PdfTextExtractor(document);
        String pageText = extractor.extractText(startPageIndex: i, endPageIndex: i);
        pdfText += '$pageText\n\n';
      }

      // Close the document
      document.dispose();

      // Create Word document
      final archive = Archive();

      // Add required files for Word document structure
      _addRequiredFiles(archive);

      // Generate document content with extracted PDF text
      final docXml = _generateWordDocumentXml(
        pdfFile.path.split('/').last,
        pdfFile.lengthSync(),
        pdfFile.lastModifiedSync(),
        pdfText, // Pass the extracted text
      );

      archive.addFile(
          ArchiveFile('word/document.xml', docXml.length, utf8.encode(docXml)));

      // Encode to ZIP
      final zipData = ZipEncoder().encode(archive);
      if (zipData == null) {
        throw Exception("Failed to create ZIP archive");
      }

      // Create output directory if it doesn't exist
      final directory = await getApplicationDocumentsDirectory();
      final outputDir = Directory('${directory.path}/converted_files');
      if (!await outputDir.exists()) {
        await outputDir.create(recursive: true);
      }

      // Generate output filename
      final originalName = pdfFile.path.split('/').last.replaceAll('.pdf', '');
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath =
          '${outputDir.path}/converted_${originalName}_$timestamp.docx';

      // Save the file
      final file = File(filePath);
      await file.writeAsBytes(zipData);

      return file;
    } catch (e) {
      throw Exception('Failed to convert PDF to Word: ${e.toString()}');
    }
  }

  Future<void> shareDocument(File file) async {
    try {
      await Share.shareXFiles([XFile(file.path)],
          text: 'Check out this document');
    } catch (e) {
      throw Exception('Failed to share document: ${e.toString()}');
    }
  }

  void _addRequiredFiles(Archive archive) {
    // Content Types
    archive.addFile(ArchiveFile('[Content_Types].xml',
        _getContentTypesXml().length, utf8.encode(_getContentTypesXml())));

    // Package Relationships
    archive.addFile(ArchiveFile('_rels/.rels', _getRelationshipsXml().length,
        utf8.encode(_getRelationshipsXml())));

    // Document Relationships
    archive.addFile(ArchiveFile(
        'word/_rels/document.xml.rels',
        _getDocumentRelationshipsXml().length,
        utf8.encode(_getDocumentRelationshipsXml())));

    // Add Styles
    archive.addFile(ArchiveFile('word/styles.xml', _getStylesXml().length,
        utf8.encode(_getStylesXml())));

    // Add Settings
    archive.addFile(ArchiveFile('word/settings.xml', _getSettingsXml().length,
        utf8.encode(_getSettingsXml())));
  }

  String _generateWordDocumentXml(
      String filename, int fileSize, DateTime modifiedDate, String pdfContent) {
    final sizeInMb = (fileSize / (1024 * 1024)).toStringAsFixed(2);
    final modified =
        '${modifiedDate.day}/${modifiedDate.month}/${modifiedDate.year}';

    // Escape XML special characters in the PDF content
    String escapedContent = pdfContent
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');

    // Convert content into paragraphs
    List<String> paragraphs = escapedContent.split('\n\n');
    String formattedContent = '';

    // Create a title section
    String titleSection = '''
    <w:p>
      <w:pPr><w:pStyle w:val="Title"/></w:pPr>
      <w:r><w:t>Converted PDF Document</w:t></w:r>
    </w:p>
    <w:p>
      <w:pPr><w:pStyle w:val="Subtitle"/></w:pPr>
      <w:r><w:t>Original: $filename</w:t></w:r>
    </w:p>
    <w:p>
      <w:pPr><w:pStyle w:val="Subtitle"/></w:pPr>
      <w:r><w:t>Size: $sizeInMb MB | Modified: $modified</w:t></w:r>
    </w:p>
    <w:p/>
    ''';

    // Process each paragraph
    for (String paragraph in paragraphs) {
      if (paragraph.trim().isEmpty) continue;

      // Split paragraph into lines for better formatting
      List<String> lines = paragraph.split('\n');
      String formattedParagraph = '';

      for (String line in lines) {
        if (line.trim().isEmpty) continue;
        formattedParagraph += '<w:r><w:t>${line.trim()}</w:t></w:r><w:r><w:br/></w:r>';
      }

      // Remove last line break
      if (formattedParagraph.endsWith('<w:r><w:br/></w:r>')) {
        formattedParagraph = formattedParagraph.substring(0, formattedParagraph.length - 18);
      }

      formattedContent += '<w:p>$formattedParagraph</w:p>';
    }

    return '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:body>
    $titleSection
    $formattedContent
  </w:body>
</w:document>''';
  }

  String _getContentTypesXml() {
    return '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
  <Override PartName="/word/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml"/>
  <Override PartName="/word/settings.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.settings+xml"/>
</Types>''';
  }

  String _getRelationshipsXml() {
    return '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>
</Relationships>''';
  }

  String _getDocumentRelationshipsXml() {
    return '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>
  <Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/settings" Target="settings.xml"/>
</Relationships>''';
  }

  String _getStylesXml() {
    return '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:styles xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:style w:type="paragraph" w:styleId="Title">
    <w:name w:val="Title"/>
    <w:pPr>
      <w:spacing w:before="240" w:after="120"/>
      <w:jc w:val="center"/>
    </w:pPr>
    <w:rPr>
      <w:rFonts w:ascii="Calibri" w:hAnsi="Calibri"/>
      <w:b/>
      <w:sz w:val="36"/>
      <w:szCs w:val="36"/>
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="Subtitle">
    <w:name w:val="Subtitle"/>
    <w:pPr>
      <w:spacing w:before="120" w:after="120"/>
      <w:jc w:val="center"/>
    </w:pPr>
    <w:rPr>
      <w:rFonts w:ascii="Calibri" w:hAnsi="Calibri"/>
      <w:i/>
      <w:sz w:val="24"/>
      <w:szCs w:val="24"/>
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="Normal">
    <w:name w:val="Normal"/>
    <w:pPr>
      <w:spacing w:before="120" w:after="120"/>
    </w:pPr>
    <w:rPr>
      <w:rFonts w:ascii="Calibri" w:hAnsi="Calibri"/>
      <w:sz w:val="22"/>
      <w:szCs w:val="22"/>
    </w:rPr>
  </w:style>
</w:styles>''';
  }

  String _getSettingsXml() {
    return '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:settings xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:zoom w:percent="100"/>
  <w:defaultTabStop w:val="720"/>
  <w:characterSpacingControl w:val="doNotCompress"/>
  <w:compat/>
  <w:rsids>
    <w:rsidRoot w:val="00000000"/>
  </w:rsids>
  <w:themeFontLang w:val="en-US"/>
  <w:clrSchemeMapping w:bg1="light1" w:t1="dark1" w:bg2="light2" w:t2="dark2" w:accent1="accent1" w:accent2="accent2" w:accent3="accent3" w:accent4="accent4" w:accent5="accent5" w:accent6="accent6" w:hyperlink="hyperlink" w:followedHyperlink="followedHyperlink"/>
</w:settings>''';
  }
}