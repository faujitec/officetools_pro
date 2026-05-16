import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_selfie_segmentation/google_mlkit_selfie_segmentation.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

/// On-device background removal using Google ML Kit Selfie Segmentation (Android / iOS).
class SelfieSegmentationService {
  const SelfieSegmentationService();

  Future<Uint8List> removeBackground(
    Uint8List imageBytes, {
    double edgeSoftness = 0.55,
    bool highQuality = true,
  }) async {
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
      return _applyMask(
        decoded,
        mask,
        edgeSoftness: edgeSoftness,
        highQuality: highQuality,
      );
    } finally {
      await segmenter.close();
      try {
        await tempFile.delete();
      } catch (e) {
        debugPrint('[remove-bg] temp delete failed: $e');
      }
    }
  }

  Uint8List _applyMask(
    img.Image source,
    SegmentationMask mask, {
    required double edgeSoftness,
    required bool highQuality,
  }) {
    final w = source.width;
    final h = source.height;
    final out = img.Image(width: w, height: h, numChannels: 4);
    final alpha = List<double>.filled(w * h, 0);

    // Build a confidence/alpha map first so we can smooth it and avoid
    // rough outlines / edge halos around hair and clothes.
    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        final conf = _confidenceAt(mask, x, y, w, h);
        alpha[y * w + x] = conf.clamp(0.0, 1.0);
      }
    }

    final blurPasses = highQuality ? 2 : 1;
    var blurred = alpha;
    for (int i = 0; i < blurPasses; i++) {
      blurred = _boxBlur3x3(blurred, w, h);
    }
    final softness = edgeSoftness.clamp(0.0, 1.0);
    final low = (0.14 + softness * 0.2).clamp(0.05, 0.42);
    final high = (0.72 + softness * 0.22).clamp(0.55, 0.97);
    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        final p = source.getPixel(x, y);
        final a0 = blurred[y * w + x];
        final a = _smoothstep(low, high, a0);
        final ia = (a * 255).round().clamp(0, 255);

        // Basic foreground decontamination to reduce white fringe from
        // bright backgrounds near uncertain edges.
        final edgeFactor = math.pow(a, highQuality ? 0.8 : 0.9).toDouble();
        final r = (p.r * edgeFactor).round().clamp(0, 255);
        final g = (p.g * edgeFactor).round().clamp(0, 255);
        final b = (p.b * edgeFactor).round().clamp(0, 255);
        out.setPixelRgba(x, y, r, g, b, ia);
      }
    }

    return Uint8List.fromList(img.encodePng(out));
  }

  List<double> _boxBlur3x3(List<double> src, int w, int h) {
    final out = List<double>.filled(src.length, 0);
    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        var sum = 0.0;
        var count = 0;
        for (var ky = -1; ky <= 1; ky++) {
          final ny = y + ky;
          if (ny < 0 || ny >= h) continue;
          for (var kx = -1; kx <= 1; kx++) {
            final nx = x + kx;
            if (nx < 0 || nx >= w) continue;
            sum += src[ny * w + nx];
            count++;
          }
        }
        out[y * w + x] = count == 0 ? src[y * w + x] : (sum / count);
      }
    }
    return out;
  }

  double _smoothstep(double edge0, double edge1, double x) {
    final t = ((x - edge0) / (edge1 - edge0)).clamp(0.0, 1.0);
    return t * t * (3 - 2 * t);
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
