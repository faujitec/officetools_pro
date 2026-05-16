import 'dart:convert';
import 'dart:typed_data';
import 'dart:isolate';
import 'dart:ui' show Rect;

import 'package:archive/archive.dart';
import 'package:image/image.dart' as img;
import 'package:syncfusion_flutter_pdf/pdf.dart';

class ConvertResult {
  final Uint8List bytes;
  final String extension;

  const ConvertResult({
    required this.bytes,
    required this.extension,
  });
}

class ConvertService {
  const ConvertService();

  Future<ConvertResult> imageToPdfAsync(Uint8List imageBytes) async {
    return Isolate.run(() => imageToPdf(imageBytes));
  }

  ConvertResult imageToPdf(Uint8List imageBytes) {
    final doc = PdfDocument();
    try {
      final page = doc.pages.add();
      final bmp = PdfBitmap(imageBytes);
      page.graphics.drawImage(
          bmp, Rect.fromLTWH(0, 0, page.size.width, page.size.height));
      final out = Uint8List.fromList(doc.saveSync());
      return ConvertResult(bytes: out, extension: 'pdf');
    } finally {
      doc.dispose();
    }
  }

  Future<ConvertResult> textToPdfAsync(String text) async {
    return Isolate.run(() => textToPdf(text));
  }

  ConvertResult textToPdf(String text) {
    final doc = PdfDocument();
    try {
      final page = doc.pages.add();
      final font = PdfStandardFont(PdfFontFamily.helvetica, 11);
      page.graphics.drawString(
        text.trim().isEmpty ? ' ' : text,
        font,
        bounds: const Rect.fromLTWH(0, 0, 500, 760),
      );
      final out = Uint8List.fromList(doc.saveSync());
      return ConvertResult(bytes: out, extension: 'pdf');
    } finally {
      doc.dispose();
    }
  }

  String extractTextFromDocx(Uint8List bytes) {
    final archive = ZipDecoder().decodeBytes(bytes, verify: true);
    ArchiveFile? docXml;
    for (final f in archive.files) {
      if (f.name == 'word/document.xml') {
        docXml = f;
        break;
      }
    }
    if (docXml == null) {
      throw Exception('Unsupported DOCX structure');
    }
    final xml = utf8.decode(docXml.content as List<int>);
    var text = xml
        .replaceAll(RegExp(r'<w:tab[^>]*/>'), '\t')
        .replaceAll(RegExp(r'</w:p>'), '\n')
        .replaceAll(RegExp(r'<[^>]+>'), '');
    text = text
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&apos;', "'")
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
    return text;
  }

  ConvertResult wordToPdfBasic(Uint8List docxBytes) {
    final text = extractTextFromDocx(docxBytes);
    return textToPdf(text.isEmpty ? ' ' : text);
  }

  ConvertResult pdfToWordBasic(Uint8List pdfBytes) {
    final doc = PdfDocument(inputBytes: pdfBytes);
    String text;
    try {
      final extractor = PdfTextExtractor(doc);
      text = extractor.extractText().trim();
    } finally {
      doc.dispose();
    }
    return ConvertResult(bytes: _buildSimpleDocx(text), extension: 'docx');
  }

  Uint8List _buildSimpleDocx(String text) {
    String esc(String v) => v
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
    String stripInvalidXmlChars(String input) {
      final b = StringBuffer();
      for (final r in input.runes) {
        final valid = r == 0x9 ||
            r == 0xA ||
            r == 0xD ||
            (r >= 0x20 && r <= 0xD7FF) ||
            (r >= 0xE000 && r <= 0xFFFD) ||
            (r >= 0x10000 && r <= 0x10FFFF);
        if (valid) b.writeCharCode(r);
      }
      return b.toString();
    }

    final safeText = stripInvalidXmlChars(text.isEmpty ? ' ' : text);
    final lines = safeText.split('\n');
    final paragraphs = lines
        .map((l) =>
            '<w:p><w:r><w:t xml:space="preserve">${esc(l)}</w:t></w:r></w:p>')
        .join();
    const contentTypes =
        '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
</Types>''';
    const rels = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>
</Relationships>''';
    const docRels = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"></Relationships>''';
    final docXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:document xmlns:wpc="http://schemas.microsoft.com/office/word/2010/wordprocessingCanvas"
 xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"
 xmlns:o="urn:schemas-microsoft-com:office:office"
 xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"
 xmlns:m="http://schemas.openxmlformats.org/officeDocument/2006/math"
 xmlns:v="urn:schemas-microsoft-com:vml"
 xmlns:wp14="http://schemas.microsoft.com/office/word/2010/wordprocessingDrawing"
 xmlns:wp="http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing"
 xmlns:w10="urn:schemas-microsoft-com:office:word"
 xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"
 xmlns:w14="http://schemas.microsoft.com/office/word/2010/wordml"
 xmlns:wpg="http://schemas.microsoft.com/office/word/2010/wordprocessingGroup"
 xmlns:wpi="http://schemas.microsoft.com/office/word/2010/wordprocessingInk"
 xmlns:wne="http://schemas.microsoft.com/office/word/2006/wordml"
 xmlns:wps="http://schemas.microsoft.com/office/word/2010/wordprocessingShape"
 mc:Ignorable="w14 wp14">
  <w:body>$paragraphs<w:sectPr/></w:body>
</w:document>''';
    final contentTypesBytes = utf8.encode(contentTypes);
    final relsBytes = utf8.encode(rels);
    final docRelsBytes = utf8.encode(docRels);
    final docXmlBytes = utf8.encode(docXml);
    final archive = Archive()
      ..addFile(ArchiveFile(
          '[Content_Types].xml', contentTypesBytes.length, contentTypesBytes))
      ..addFile(ArchiveFile('_rels/.rels', relsBytes.length, relsBytes))
      ..addFile(ArchiveFile(
          'word/_rels/document.xml.rels', docRelsBytes.length, docRelsBytes))
      ..addFile(
          ArchiveFile('word/document.xml', docXmlBytes.length, docXmlBytes));
    final encoded = ZipEncoder().encode(archive);
    return Uint8List.fromList(encoded);
  }

  ConvertResult convertImageFormat(Uint8List input, String toFormat) {
    final decoded = img.decodeImage(input);
    if (decoded == null) throw Exception('Invalid image');
    late Uint8List out;
    switch (toFormat) {
      case 'png':
        out = Uint8List.fromList(img.encodePng(decoded));
        break;
      case 'jpg':
      default:
        out = Uint8List.fromList(img.encodeJpg(decoded, quality: 92));
    }
    return ConvertResult(bytes: out, extension: toFormat);
  }
}
