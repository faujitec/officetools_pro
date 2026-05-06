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
  final bool reduced;

  const CompressResult({
    required this.bytes,
    required this.extension,
    required this.originalSize,
    required this.compressedSize,
    required this.reduced,
  });
}

class CompressService {
  final PdfToolsService _pdfTools;

  const CompressService({PdfToolsService pdfTools = const PdfToolsService()})
      : _pdfTools = pdfTools;

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
        out = Uint8List.fromList(img.encodePng(working, level: 9));
        break;
      case 'jpg':
      default:
        var q = quality.clamp(12, 95);
        out = Uint8List.fromList(img.encodeJpg(working, quality: q));
        var guard = 0;
        // Tighten quality until smaller, or stop at acceptable floor.
        while (out.lengthInBytes >= inputBytes.lengthInBytes &&
            q > 22 &&
            guard < 18) {
          guard++;
          q = (q - 4).clamp(12, 95);
          out = Uint8List.fromList(img.encodeJpg(working, quality: q));
        }
    }

    if (out.lengthInBytes >= inputBytes.lengthInBytes) {
      final inputExt = _detectImageExt(inputBytes);
      return CompressResult(
        bytes: inputBytes,
        extension: inputExt,
        originalSize: inputBytes.lengthInBytes,
        compressedSize: inputBytes.lengthInBytes,
        reduced: false,
      );
    }

    return CompressResult(
      bytes: out,
      extension: outputFormat,
      originalSize: inputBytes.lengthInBytes,
      compressedSize: out.lengthInBytes,
      reduced: true,
    );
  }

  CompressResult compressPdf({
    required Uint8List inputBytes,
    required PdfCompressionLevel level,
  }) {
    final out = _pdfTools.compress(inputBytes, level);
    if (out.lengthInBytes >= inputBytes.lengthInBytes) {
      return CompressResult(
        bytes: inputBytes,
        extension: 'pdf',
        originalSize: inputBytes.lengthInBytes,
        compressedSize: inputBytes.lengthInBytes,
        reduced: false,
      );
    }
    return CompressResult(
      bytes: out,
      extension: 'pdf',
      originalSize: inputBytes.lengthInBytes,
      compressedSize: out.lengthInBytes,
      reduced: true,
    );
  }

  CompressResult compressDocumentAsZip({
    required Uint8List inputBytes,
    required String fileName,
  }) {
    final archive = Archive();
    archive
        .addFile(ArchiveFile(fileName, inputBytes.lengthInBytes, inputBytes));
    final zipped = Uint8List.fromList(ZipEncoder().encode(archive));
    if (zipped.lengthInBytes >= inputBytes.lengthInBytes) {
      final ext = _fileExt(fileName);
      return CompressResult(
        bytes: inputBytes,
        extension: ext,
        originalSize: inputBytes.lengthInBytes,
        compressedSize: inputBytes.lengthInBytes,
        reduced: false,
      );
    }
    return CompressResult(
      bytes: zipped,
      extension: 'zip',
      originalSize: inputBytes.lengthInBytes,
      compressedSize: zipped.lengthInBytes,
      reduced: true,
    );
  }

  String _fileExt(String fileName) {
    final dot = fileName.lastIndexOf('.');
    if (dot < 0 || dot == fileName.length - 1) return 'bin';
    return fileName.substring(dot + 1).toLowerCase();
  }

  String _detectImageExt(Uint8List bytes) {
    if (bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return 'png';
    }
    if (bytes.length >= 2 && bytes[0] == 0xFF && bytes[1] == 0xD8) {
      return 'jpg';
    }
    return 'jpg';
  }
}
