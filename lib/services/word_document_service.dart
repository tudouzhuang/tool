import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive.dart';

class WordDocumentService {
  Future<String> createWordDocument(String text) async {
    final archive = Archive();

    // Add content types
    archive.addFile(ArchiveFile(
        '[Content_Types].xml',
        _getContentTypesXml().length,
        utf8.encode(_getContentTypesXml())));

    // Add package relationships
    archive.addFile(ArchiveFile('_rels/.rels', _getRelationshipsXml().length,
        utf8.encode(_getRelationshipsXml())));

    // Add document relationships
    archive.addFile(ArchiveFile(
        'word/_rels/document.xml.rels',
        _getDocumentRelationshipsXml().length,
        utf8.encode(_getDocumentRelationshipsXml())));

    // Add main document content
    final docXml = _generateWordDocumentXml(text);
    archive.addFile(
        ArchiveFile('word/document.xml', docXml.length, utf8.encode(docXml)));

    // Encode to ZIP
    final zipData = ZipEncoder().encode(archive);
    if (zipData == null) {
      throw Exception("Failed to create ZIP archive");
    }

    // Save to file
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final filePath = '${directory.path}/ocr_text_$timestamp.docx';

    final file = File(filePath);
    await file.writeAsBytes(zipData);

    return filePath;
  }

  String _generateWordDocumentXml(String text) {
    // Escape special characters
    text = text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');

    // Format each line as a paragraph
    text = text
        .split('\n')
        .map((line) =>
    line.isEmpty ? '<w:p/>' : '<w:p><w:r><w:t>$line</w:t></w:r></w:p>')
        .join('');

    return '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:body>
    $text
  </w:body>
</w:document>''';
  }

  String _getContentTypesXml() {
    return '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
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
</Relationships>''';
  }
}