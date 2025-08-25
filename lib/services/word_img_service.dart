import 'dart:io';
import 'dart:math';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive.dart';
import 'package:image/image.dart' as img;

class WordImageService {
  // Reduced maximum dimensions (about 60% of original)
  static const int maxPageWidthEmu = 4663440; // ~5.1 inches (was 8.5)
  static const int maxPageHeightEmu = 6035040; // ~6.6 inches (was 11)
  Future<String> createWordDocumentWithImage(File imageFile) async {
    // Read the image file
    final imageBytes = await imageFile.readAsBytes();
    final image = img.decodeImage(imageBytes)!;

    // Convert image to base64 for embedding
    final base64Image = base64Encode(imageBytes);
    var imageWidthPx = image.width;
    var imageHeightPx = image.height;

    // Convert pixels to Word's EMU units (1px = 9525 EMU)
    var widthEmu = imageWidthPx * 9525;
    var heightEmu = imageHeightPx * 9525;

    // Scale down if image is too large for the page
    final scaleFactor = _calculateScaleFactor(widthEmu, heightEmu);
    if (scaleFactor < 1.0) {
      widthEmu = (widthEmu * scaleFactor).toInt();
      heightEmu = (heightEmu * scaleFactor).toInt();
    }

    final archive = Archive();

    // Add content types
    archive.addFile(ArchiveFile('[Content_Types].xml',
        _getContentTypesXml().length, utf8.encode(_getContentTypesXml())));

    // Add package relationships
    archive.addFile(ArchiveFile('_rels/.rels', _getRelationshipsXml().length,
        utf8.encode(_getRelationshipsXml())));

    // Add document relationships
    final docRelsXml = _getDocumentRelationshipsXml();
    archive.addFile(ArchiveFile('word/_rels/document.xml.rels',
        docRelsXml.length, utf8.encode(docRelsXml)));

    // Add media (image) file
    const imageId = 'rId1';
    final imageExt = _getImageExtension(imageFile.path);
    archive.addFile(ArchiveFile(
        'word/media/image1.$imageExt', imageBytes.length, imageBytes));

    // Add main document content with embedded image
    final docXml =
    _generateWordDocumentWithImageXml(imageId, widthEmu, heightEmu);
    archive.addFile(
        ArchiveFile('word/document.xml', docXml.length, utf8.encode(docXml)));

    // Add styles
    final stylesXml = _getStylesXml();
    archive.addFile(ArchiveFile(
        'word/styles.xml', stylesXml.length, utf8.encode(stylesXml)));

    // Encode to ZIP
    final zipData = ZipEncoder().encode(archive);
    if (zipData == null) {
      throw Exception("Failed to create ZIP archive");
    }

    // Save to file
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final filePath = '${directory.path}/image_$timestamp.docx';

    final file = File(filePath);
    await file.writeAsBytes(zipData);

    return filePath;
  }

  double _calculateScaleFactor(int widthEmu, int heightEmu) {
    final widthScale = maxPageWidthEmu / widthEmu;
    final heightScale = maxPageHeightEmu / heightEmu;
    return min(widthScale, heightScale).clamp(0.0, 1.0);
  }

  String _getImageExtension(String path) {
    final ext = path.split('.').last.toLowerCase();
    return ext == 'jpg' ? 'jpeg' : ext; // Word uses .jpeg not .jpg
  }

  String _generateWordDocumentWithImageXml(
      String imageId, int widthEmu, int heightEmu) {
    return '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"
            xmlns:wp="http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing"
            xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
  <w:body>
    <w:p>
      <w:r>
        <w:drawing>
          <wp:inline distT="0" distB="0" distL="0" distR="0">
            <wp:extent cx="$widthEmu" cy="$heightEmu"/>
            <wp:effectExtent l="0" t="0" r="0" b="0"/>
            <wp:docPr id="1" name="Picture 1" descr="Converted Image"/>
            <wp:cNvGraphicFramePr>
              <a:graphicFrameLocks xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" noChangeAspect="1"/>
            </wp:cNvGraphicFramePr>
            <a:graphic xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main">
              <a:graphicData uri="http://schemas.openxmlformats.org/drawingml/2006/picture">
                <pic:pic xmlns:pic="http://schemas.openxmlformats.org/drawingml/2006/picture">
                  <pic:nvPicPr>
                    <pic:cNvPr id="0" name="Picture 1" descr="Converted Image"/>
                    <pic:cNvPicPr/>
                  </pic:nvPicPr>
                  <pic:blipFill>
                    <a:blip r:embed="$imageId"/>
                    <a:stretch>
                      <a:fillRect/>
                    </a:stretch>
                  </pic:blipFill>
                  <pic:spPr>
                    <a:xfrm>
                      <a:off x="0" y="0"/>
                      <a:ext cx="$widthEmu" cy="$heightEmu"/>
                    </a:xfrm>
                    <a:prstGeom prst="rect">
                      <a:avLst/>
                    </a:prstGeom>
                  </pic:spPr>
                </pic:pic>
              </a:graphicData>
            </a:graphic>
          </wp:inline>
        </w:drawing>
      </w:r>
    </w:p>
    <w:sectPr>
      <w:pgSz w:w="11906" w:h="16838"/>
      <w:pgMar w:top="1440" w:right="1440" w:bottom="1440" w:left="1440" w:header="720" w:footer="720" w:gutter="0"/>
      <w:cols w:space="720"/>
      <w:docGrid w:linePitch="360"/>
    </w:sectPr>
  </w:body>
</w:document>''';
  }

  String _getContentTypesXml() {
    return '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Default Extension="jpeg" ContentType="image/jpeg"/>
  <Default Extension="png" ContentType="image/png"/>
  <Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
  <Override PartName="/word/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml"/>
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
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/image" Target="media/image1.jpeg"/>
</Relationships>''';
  }

  String _getStylesXml() {
    return '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:styles xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:docDefaults>
    <w:rPrDefault>
      <w:rPr>
        <w:sz w:val="24"/>
        <w:szCs w:val="24"/>
      </w:rPr>
    </w:rPrDefault>
  </w:docDefaults>
</w:styles>''';
  }
}
