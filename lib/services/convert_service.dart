import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:http/http.dart' as http;
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
  final String cloudConvertApiKey;

  const ConvertService({required this.cloudConvertApiKey});

  ConvertResult imageToPdf(Uint8List imageBytes) {
    final doc = PdfDocument();
    try {
      final page = doc.pages.add();
      final bmp = PdfBitmap(imageBytes);
      page.graphics.drawImage(bmp, Rect.fromLTWH(0, 0, page.size.width, page.size.height));
      final out = Uint8List.fromList(doc.saveSync());
      return ConvertResult(bytes: out, extension: 'pdf');
    } finally {
      doc.dispose();
    }
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

  Future<ConvertResult> cloudConvert({
    required Uint8List inputBytes,
    required String fileName,
    required String inputFormat,
    required String outputFormat,
  }) async {
    if (cloudConvertApiKey.isEmpty) {
      throw Exception('Missing CLOUDCONVERT_API_KEY');
    }

    late http.Response create;
    try {
      create = await http
          .post(
            Uri.parse('https://api.cloudconvert.com/v2/jobs'),
            headers: {
              'Authorization': 'Bearer $cloudConvertApiKey',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'tasks': {
                'import-1': {'operation': 'import/upload'},
                'convert-1': {
                  'operation': 'convert',
                  'input': 'import-1',
                  'input_format': inputFormat,
                  'output_format': outputFormat,
                },
                'export-1': {
                  'operation': 'export/url',
                  'input': 'convert-1',
                },
              },
            }),
          )
          .timeout(const Duration(seconds: 25));
    } on SocketException {
      throw Exception('No internet connection for CloudConvert.');
    } on http.ClientException {
      throw Exception('Network request failed for CloudConvert.');
    } on TimeoutException {
      throw Exception('CloudConvert request timed out.');
    }
    if (create.statusCode >= 300) {
      throw Exception(
        'CloudConvert job create failed (${create.statusCode}): ${create.body}',
      );
    }
    final job = jsonDecode(create.body)['data'] as Map<String, dynamic>;
    final tasks = (job['tasks'] as List).cast<Map<String, dynamic>>();
    final importTask = tasks.firstWhere((t) => t['name'] == 'import-1');
    final upload = importTask['result']['form'] as Map<String, dynamic>;
    final uploadParams = (upload['parameters'] as Map).cast<String, dynamic>();

    final req = http.MultipartRequest('POST', Uri.parse(upload['url']));
    uploadParams.forEach((key, value) {
      req.fields[key] = value.toString();
    });
    req.files.add(http.MultipartFile.fromBytes('file', inputBytes, filename: fileName));
    final uploadResp = await req.send();
    if (uploadResp.statusCode >= 300) {
      throw Exception('CloudConvert upload failed (${uploadResp.statusCode})');
    }

    final jobId = job['id'];
    Map<String, dynamic>? exportTask;
    for (int i = 0; i < 60; i++) {
      final poll = await http
          .get(
            Uri.parse('https://api.cloudconvert.com/v2/jobs/$jobId'),
            headers: {'Authorization': 'Bearer $cloudConvertApiKey'},
          )
          .timeout(const Duration(seconds: 25));
      if (poll.statusCode >= 300) {
        throw Exception('CloudConvert poll failed (${poll.statusCode})');
      }
      final polled = jsonDecode(poll.body)['data'] as Map<String, dynamic>;
      final polledTasks = (polled['tasks'] as List).cast<Map<String, dynamic>>();
      final maybeExport = polledTasks.firstWhere(
        (t) => t['name'] == 'export-1',
        orElse: () => <String, dynamic>{},
      );
      if (maybeExport.isNotEmpty && maybeExport['status'] == 'finished') {
        exportTask = maybeExport;
        break;
      }
      await Future<void>.delayed(const Duration(seconds: 2));
    }
    if (exportTask == null) throw Exception('CloudConvert timeout');

    final files = (exportTask['result']['files'] as List).cast<Map<String, dynamic>>();
    if (files.isEmpty) throw Exception('No output file from CloudConvert');
    final url = files.first['url'] as String;
    final dl = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 25));
    if (dl.statusCode >= 300) {
      throw Exception('CloudConvert download failed (${dl.statusCode})');
    }
    return ConvertResult(bytes: dl.bodyBytes, extension: outputFormat);
  }
}
