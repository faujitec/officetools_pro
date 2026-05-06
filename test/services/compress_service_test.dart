import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:office_toolspro/services/compress_service.dart';

void main() {
  group('CompressService', () {
    test('compressImage returns a non-empty payload', () {
      final source = img.Image(width: 120, height: 120);
      img.fill(source, color: img.ColorRgb8(240, 120, 80));
      final input = Uint8List.fromList(img.encodeJpg(source, quality: 95));

      const service = CompressService();
      final out = service.compressImage(
        inputBytes: input,
        quality: 60,
        outputFormat: 'jpg',
      );

      expect(out.bytes, isNotEmpty);
      expect(out.originalSize, equals(input.lengthInBytes));
      expect(out.compressedSize, equals(out.bytes.lengthInBytes));
    });

    test('compressDocumentAsZip returns bytes and extension', () {
      final input =
          Uint8List.fromList(List<int>.generate(2048, (i) => i % 251));
      const service = CompressService();
      final out = service.compressDocumentAsZip(
        inputBytes: input,
        fileName: 'sample.docx',
      );

      expect(out.bytes, isNotEmpty);
      expect(out.extension, isNotEmpty);
      expect(out.originalSize, equals(input.lengthInBytes));
    });
  });
}
