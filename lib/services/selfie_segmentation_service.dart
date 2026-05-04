import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_selfie_segmentation/google_mlkit_selfie_segmentation.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

/// On-device background removal using Google ML Kit Selfie Segmentation (Android / iOS).
class SelfieSegmentationService {
  const SelfieSegmentationService();

  Future<Uint8List> removeBackground(Uint8List imageBytes) async {
    if (kIsWeb) {
      throw UnsupportedError('Selfie segmentation is not available on web.');
    }
    if (!Platform.isAndroid && !Platform.isIOS) {
      throw UnsupportedError('Selfie segmentation requires Android or iOS.');
    }

    final decoded = img.decodeImage(imageBytes);
    if (decoded == null) {
      throw Exception('Could not decode image');
    }

    final dir = await getTemporaryDirectory();
    final tempFile = File(
      '${dir.path}/selfie_seg_${DateTime.now().microsecondsSinceEpoch}.png',
    );
    await tempFile.writeAsBytes(imageBytes);

    final segmenter = SelfieSegmenter(
      mode: SegmenterMode.single,
      enableRawSizeMask: true,
    );

    try {
      final inputImage = InputImage.fromFilePath(tempFile.path);
      final mask = await segmenter.processImage(inputImage);
      if (mask == null) {
        throw Exception('No segmentation mask returned');
      }
      return _applyMask(decoded, mask);
    } finally {
      await segmenter.close();
      try {
        await tempFile.delete();
      } catch (_) {}
    }
  }

  Uint8List _applyMask(img.Image source, SegmentationMask mask) {
    final w = source.width;
    final h = source.height;
    final out = img.Image(width: w, height: h, numChannels: 4);

    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        final p = source.getPixel(x, y);
        final conf = _confidenceAt(mask, x, y, w, h);
        // Slightly lift mid-tones for softer hair/edges; raw-size mask keeps detail.
        final shaped = math.pow(conf.clamp(0.0, 1.0), 0.78).toDouble();
        final a = (shaped * 255).round().clamp(0, 255);
        out.setPixelRgba(x, y, p.r, p.g, p.b, a);
      }
    }

    return Uint8List.fromList(img.encodePng(out));
  }

  double _confidenceAt(SegmentationMask m, int x, int y, int imgW, int imgH) {
    if (m.width <= 0 || m.height <= 0 || m.confidences.isEmpty) return 0;
    if (m.width == imgW && m.height == imgH) {
      final i = y * m.width + x;
      if (i >= 0 && i < m.confidences.length) {
        return m.confidences[i].clamp(0.0, 1.0);
      }
    }
    final fx = imgW <= 1 ? 0.0 : x / (imgW - 1);
    final fy = imgH <= 1 ? 0.0 : y / (imgH - 1);
    final mx = (fx * (m.width - 1)).round().clamp(0, m.width - 1);
    final my = (fy * (m.height - 1)).round().clamp(0, m.height - 1);
    final i = my * m.width + mx;
    if (i < 0 || i >= m.confidences.length) return 0;
    return m.confidences[i].clamp(0.0, 1.0);
  }
}
