import 'dart:typed_data';
import 'package:google_generative_ai/google_generative_ai.dart';

enum OcrMode { fast, accurate, table }

class GeminiService {
  final String apiKey;
  late final GenerativeModel _model;

  GeminiService(this.apiKey) {
    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: apiKey,
    );
  }

  Future<String> extractTextFromImage(
    Uint8List bytes,
    String mimeType, {
    OcrMode mode = OcrMode.accurate,
    String language = 'Auto',
  }) async {
    try {
      final prompt = TextPart(_buildPrompt(mode, language));
      final imagePart = DataPart(mimeType, bytes);
      
      final response = await _model.generateContent([
        Content.multi([prompt, imagePart])
      ]);

      return response.text ?? "No text could be extracted.";
    } catch (e) {
      throw Exception("Failed to extract text. Please check your image and try again.");
    }
  }

  String _buildPrompt(OcrMode mode, String language) {
    final langHint = language == 'Auto'
        ? 'Detect the document language automatically.'
        : 'The document language is likely $language. Prioritize that language.';

    switch (mode) {
      case OcrMode.fast:
        return '''
Extract readable text quickly from this document image.
$langHint
Keep formatting simple and concise.
''';
      case OcrMode.table:
        return '''
Extract all readable text from this document image.
$langHint
Preserve table structure as clearly as possible using plain text rows/columns.
Prioritize numerical values, headers, and units.
''';
      case OcrMode.accurate:
        return '''
Extract all readable text from this document image as accurately as possible.
$langHint
Format clearly as plain text and preserve headings, lists, and key values.
If tables exist, represent them in a readable text structure.
''';
    }
  }
}
