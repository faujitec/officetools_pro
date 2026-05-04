import 'dart:io';
import 'dart:typed_data';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class OcrService {
  const OcrService();

  Future<String> extractFromImage(Uint8List bytes) async {
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/ocr_${DateTime.now().microsecondsSinceEpoch}.jpg';
    final file = File(path);
    await file.writeAsBytes(bytes, flush: true);
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final input = InputImage.fromFilePath(path);
      final result = await recognizer.processImage(input);
      return result.text.trim();
    } finally {
      await recognizer.close();
      if (await file.exists()) {
        await file.delete();
      }
    }
  }

  String extractFromPdf(Uint8List bytes) {
    final doc = PdfDocument(inputBytes: bytes);
    try {
      final extractor = PdfTextExtractor(doc);
      return extractor.extractText().trim();
    } finally {
      doc.dispose();
    }
  }
}
