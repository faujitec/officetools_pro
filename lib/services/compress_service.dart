import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:image/image.dart' as img;
import 'package:syncfusion_flutter_pdf/pdf.dart';

import 'package:office_toolspro/services/pdf_tools_service.dart';

class CompressResult {
  final Uint8List bytes;
  final String extension;
  final int originalSize;
  final int compressedSize;

  const CompressResult({
    required this.bytes,
    required this.extension,
    required this.originalSize,
    required this.compressedSize,
  });
}

class CompressService {
  final PdfToolsService _pdfTools;

  const CompressService({PdfToolsService pdfTools = const PdfToolsService()}) : _pdfTools = pdfTools;

  CompressResult compressImage({
    required Uint8List inputBytes,
    required int quality,
    required String outputFormat,
    bool downscale = false,
  }) {
    final decoded = img.decodeImage(inputBytes);
    if (decoded == null) {
      throw Exception('Invalid image input');
    }

    img.Image working = img.Image.from(decoded);
    if (downscale) {
      final width = (working.width * 0.8).round();
      final height = (working.height * 0.8).round();
      working = img.copyResize(working, width: width, height: height);
    }

    late Uint8List out;
    switch (outputFormat) {
      case 'png':
        out = Uint8List.fromList(img.encodePng(working, level: 6));
        break;
      case 'jpg':
      default:
        out = Uint8List.fromList(img.encodeJpg(working, quality: quality));
    }

    return CompressResult(
      bytes: out,
      extension: outputFormat,
      originalSize: inputBytes.lengthInBytes,
      compressedSize: out.lengthInBytes,
    );
  }

  CompressResult compressPdf({
    required Uint8List inputBytes,
    required PdfCompressionLevel level,
  }) {
    final out = _pdfTools.compress(inputBytes, level);
    return CompressResult(
      bytes: out,
      extension: 'pdf',
      originalSize: inputBytes.lengthInBytes,
      compressedSize: out.lengthInBytes,
    );
  }

  CompressResult compressDocumentAsZip({
    required Uint8List inputBytes,
    required String fileName,
  }) {
    final archive = Archive();
    archive.addFile(ArchiveFile(fileName, inputBytes.lengthInBytes, inputBytes));
    final zipped = Uint8List.fromList(ZipEncoder().encode(archive));
    return CompressResult(
      bytes: zipped,
      extension: 'zip',
      originalSize: inputBytes.lengthInBytes,
      compressedSize: zipped.lengthInBytes,
    );
  }
}
