import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:intl/intl.dart';
import 'package:office_toolspro/models/file_item.dart';
import 'package:office_toolspro/services/file_store.dart';
import 'package:office_toolspro/widgets/global_banner_ad.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:permission_handler/permission_handler.dart';

enum _ScanStage { capture, edit, filter, review }
enum _PageFilter { original, bw, grayscale, enhance }

class _ScanPage {
  final Uint8List bytes;

  const _ScanPage({required this.bytes});
}

class ScannerScreen extends StatefulWidget {
  final String apiKey;
  const ScannerScreen({super.key, required this.apiKey});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  CameraController? _camera;
  List<CameraDescription> _cameras = const [];
  bool _flashOn = false;
  bool _busy = false;
  _ScanStage _stage = _ScanStage.capture;

  Uint8List? _captured;
  Uint8List? _cropped;
  _PageFilter _activeFilter = _PageFilter.original;
  final List<_ScanPage> _pages = [];

  List<Offset> _corners = const [
    Offset(0.08, 0.08),
    Offset(0.92, 0.08),
    Offset(0.92, 0.92),
    Offset(0.08, 0.92),
  ];
  int? _dragCorner;
  int _reviewPageIndex = 0;
  PageController? _reviewPageController;

  List<Offset> _defaultCorners() => const [
        Offset(0.08, 0.08),
        Offset(0.92, 0.08),
        Offset(0.92, 0.92),
        Offset(0.08, 0.92),
      ];

  /// Rough document bounds on light backgrounds (non-white pixels → bbox).
  List<Offset> _autoDocumentCornersNormalized(img.Image source) {
    final targetW = math.min(560, source.width);
    final small = img.copyResize(source, width: targetW);
    final gray = img.grayscale(small);
    final w = gray.width;
    final h = gray.height;
    const thresh = 248;
    int? minX;
    int? maxX;
    int? minY;
    int? maxY;
    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        final l = gray.getPixel(x, y).r.toInt();
        if (l < thresh) {
          minX = minX == null ? x : math.min(minX as int, x);
          maxX = maxX == null ? x : math.max(maxX as int, x);
          minY = minY == null ? y : math.min(minY as int, y);
          maxY = maxY == null ? y : math.max(maxY as int, y);
        }
      }
    }
    if (minX == null || maxX == null || minY == null || maxY == null) {
      return _defaultCorners();
    }
    final ix0 = minX;
    final ix1 = maxX;
    final iy0 = minY;
    final iy1 = maxY;
    const margin = 0.02;
    final nx0 = (ix0 / w - margin).clamp(0.04, 0.45);
    final ny0 = (iy0 / h - margin).clamp(0.04, 0.45);
    final nx1 = (ix1 / w + margin).clamp(0.55, 0.96);
    final ny1 = (iy1 / h + margin).clamp(0.55, 0.96);
    if (nx1 <= nx0 + 0.05 || ny1 <= ny0 + 0.05) {
      return _defaultCorners();
    }
    return [
      Offset(nx0, ny0),
      Offset(nx1, ny0),
      Offset(nx1, ny1),
      Offset(nx0, ny1),
    ];
  }

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  @override
  void dispose() {
    _camera?.dispose();
    _reviewPageController?.dispose();
    super.dispose();
  }

  Future<void> _initCamera() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) return;
    _cameras = await availableCameras();
    if (_cameras.isEmpty) return;
    final controller = CameraController(
      _cameras.first,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );
    await controller.initialize();
    if (!mounted) return;
    setState(() => _camera = controller);
  }

  Future<void> _toggleFlash() async {
    if (_camera == null) return;
    _flashOn = !_flashOn;
    await _camera!.setFlashMode(_flashOn ? FlashMode.torch : FlashMode.off);
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _capture() async {
    if (_camera == null || _busy) return;
    setState(() => _busy = true);
    try {
      final x = await _camera!.takePicture();
      final bytes = await x.readAsBytes();
      if (!mounted) return;
      final decoded = img.decodeImage(bytes);
      final corners =
          decoded != null ? _autoDocumentCornersNormalized(decoded) : _defaultCorners();
      if (!mounted) return;
      setState(() {
        _captured = bytes;
        _cropped = bytes;
        _corners = corners;
        _stage = _ScanStage.edit;
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Uint8List _applyFilter(Uint8List source, _PageFilter filter) {
    final decoded = img.decodeImage(source);
    if (decoded == null) return source;
    img.Image processed = img.Image.from(decoded);
    switch (filter) {
      case _PageFilter.original:
        break;
      case _PageFilter.bw:
        processed = img.grayscale(processed);
        processed = img.contrast(processed, contrast: 220);
        break;
      case _PageFilter.grayscale:
        processed = img.grayscale(processed);
        break;
      case _PageFilter.enhance:
        processed = img.contrast(processed, contrast: 170);
        processed = img.adjustColor(processed, saturation: 1.08, brightness: 1.03);
        break;
    }
    return Uint8List.fromList(img.encodeJpg(processed, quality: 92));
  }

  void _cropWithCorners() {
    if (_captured == null) return;
    final decoded = img.decodeImage(_captured!);
    if (decoded == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not read this photo. Try Retake.')),
      );
      return;
    }
    // Axis-aligned crop from the four handles (reliable on all devices).
    final output = _boundingCrop(decoded);
    setState(() {
      _cropped = Uint8List.fromList(img.encodeJpg(output, quality: 95));
      _stage = _ScanStage.filter;
    });
  }

  img.Image _boundingCrop(img.Image decoded) {
    final xs = _corners.map((p) => p.dx).toList()..sort();
    final ys = _corners.map((p) => p.dy).toList()..sort();
    final left = (xs.first * decoded.width).clamp(0, decoded.width - 1).toInt();
    final top = (ys.first * decoded.height).clamp(0, decoded.height - 1).toInt();
    final right = (xs.last * decoded.width).clamp(left + 1, decoded.width).toInt();
    final bottom = (ys.last * decoded.height).clamp(top + 1, decoded.height).toInt();
    return img.copyCrop(
      decoded,
      x: left,
      y: top,
      width: math.max(1, right - left),
      height: math.max(1, bottom - top),
    );
  }

  void _retake() {
    setState(() {
      _captured = null;
      _cropped = null;
      _activeFilter = _PageFilter.original;
      _stage = _ScanStage.capture;
    });
  }

  void _commitScannedPage({required bool goToCaptureAfter}) {
    if (_cropped == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nothing to add. Capture and crop a page first.')),
      );
      return;
    }
    final filtered = _applyFilter(_cropped!, _activeFilter);
    if (filtered.length < 32) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Page image is empty. Go back and crop again.')),
      );
      return;
    }
    setState(() {
      _pages.add(_ScanPage(bytes: filtered));
      _captured = null;
      _cropped = null;
      _activeFilter = _PageFilter.original;
      _reviewPageIndex = _pages.length - 1;
      _stage = goToCaptureAfter ? _ScanStage.capture : _ScanStage.review;
    });
    if (!goToCaptureAfter) {
      void syncReviewScroll() {
        if (!mounted || _pages.isEmpty) return;
        final c = _reviewPageController;
        if (c == null || !c.hasClients) return;
        final last = (_pages.length - 1).clamp(0, _pages.length - 1);
        c.jumpToPage(last);
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        syncReviewScroll();
        // PageView may not attach the controller until a later frame.
        WidgetsBinding.instance.addPostFrameCallback((_) => syncReviewScroll());
      });
    }
  }

  Future<void> _savePdf() async {
    if (_pages.isEmpty) return;
    final nameController = TextEditingController(text: 'Scanned_Document');
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Save PDF'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: 'Document name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(nameController.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (name == null || name.trim().isEmpty) return;

    final doc = pw.Document();
    for (final page in _pages) {
      final mem = pw.MemoryImage(page.bytes);
      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (_) => pw.Center(
            child: pw.Image(mem, fit: pw.BoxFit.contain),
          ),
        ),
      );
    }
    final bytes = await doc.save();
    final dir = await getApplicationDocumentsDirectory();
    final ts = DateTime.now().millisecondsSinceEpoch;
    final fileName = '${name.replaceAll(RegExp(r'[^a-zA-Z0-9_\- ]'), '').trim().replaceAll(' ', '_')}_$ts.pdf';
    final path = '${dir.path}/$fileName';
    await File(path).writeAsBytes(bytes, flush: true);

    final thumbPath = '${dir.path}/thumb_$ts.jpg';
    await File(thumbPath).writeAsBytes(_pages.first.bytes, flush: true);

    FileStore.addFile(
      FileItem(
        id: ts.toString(),
        name: fileName,
        type: FileType.pdf,
        date: DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now()),
        path: path,
        thumbnailPath: thumbPath,
      ),
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('PDF saved to My Files')),
    );
    Navigator.pushNamed(context, '/my-files');
  }

  @override
  Widget build(BuildContext context) {
    switch (_stage) {
      case _ScanStage.capture:
        return _buildCamera();
      case _ScanStage.edit:
        return _buildEdit();
      case _ScanStage.filter:
        return _buildFilter();
      case _ScanStage.review:
        return _buildReview();
    }
  }

  Widget _buildCamera() {
    final initialized = _camera?.value.isInitialized ?? false;
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: initialized
                  ? CameraPreview(_camera!)
                  : const Center(child: CircularProgressIndicator()),
            ),
            Positioned(
              top: 12,
              left: 12,
              child: CircleAvatar(
                backgroundColor: Colors.black54,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: CircleAvatar(
                backgroundColor: Colors.black54,
                child: IconButton(
                  icon: Icon(_flashOn ? Icons.flash_on : Icons.flash_off, color: Colors.white),
                  onPressed: _toggleFlash,
                ),
              ),
            ),
            Positioned(
              bottom: 28,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: _capture,
                  child: Container(
                    width: 78,
                    height: 78,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                    ),
                    child: Container(
                      margin: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEdit() {
    final data = _captured;
    if (data == null) return const SizedBox.shrink();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Document'),
        actions: [
          TextButton.icon(
            onPressed: () {
              final decoded = img.decodeImage(data);
              if (decoded == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Could not auto-detect edges on this photo.')),
                );
                return;
              }
              setState(() => _corners = _autoDocumentCornersNormalized(decoded));
            },
            icon: const Icon(Icons.auto_fix_high_outlined),
            label: const Text('Auto edges'),
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          const InlineBannerAd(),
          const SizedBox(height: 8),
          Expanded(
            child: LayoutBuilder(
              builder: (context, c) {
                final decoded = img.decodeImage(data);
                final imageSize = decoded == null
                    ? Size(c.maxWidth, c.maxHeight)
                    : Size(decoded.width.toDouble(), decoded.height.toDouble());
                final imageRect = _containRect(Size(c.maxWidth, c.maxHeight), imageSize);
                final hit = math.max(48.0, MediaQuery.of(context).size.shortestSide * 0.09);
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onPanStart: (d) {
                    final local = d.localPosition;
                    double best = 100000;
                    int idx = 0;
                    for (int i = 0; i < _corners.length; i++) {
                      final p = Offset(
                        imageRect.left + (_corners[i].dx * imageRect.width),
                        imageRect.top + (_corners[i].dy * imageRect.height),
                      );
                      final dist = (p - local).distance;
                      if (dist < best) {
                        best = dist;
                        idx = i;
                      }
                    }
                    final use = best <= hit;
                    setState(() {
                      _dragCorner = use ? idx : null;
                    });
                  },
                  onPanUpdate: (d) {
                    if (_dragCorner == null) return;
                    final nx = ((d.localPosition.dx - imageRect.left) / imageRect.width).clamp(0.02, 0.98);
                    final ny = ((d.localPosition.dy - imageRect.top) / imageRect.height).clamp(0.02, 0.98);
                    setState(() {
                      _corners[_dragCorner!] = Offset(nx, ny);
                    });
                  },
                  onPanEnd: (_) {
                    setState(() => _dragCorner = null);
                  },
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.memory(data, fit: BoxFit.contain),
                      CustomPaint(
                        painter: _CornersPainter(corners: _corners, imageRect: imageRect),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              12,
              10,
              12,
              16 + MediaQuery.of(context).padding.bottom,
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _retake,
                    child: const Text('Retake'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    onPressed: _cropWithCorners,
                    child: const Text('Crop'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.tonal(
                    onPressed: _cropWithCorners,
                    child: const Text('Continue'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilter() {
    final data = _cropped;
    if (data == null) return const SizedBox.shrink();
    final preview = _applyFilter(data, _activeFilter);
    return Scaffold(
      appBar: AppBar(title: const Text('Apply Filter')),
      body: Column(
        children: [
          const SizedBox(height: 8),
          const InlineBannerAd(),
          const SizedBox(height: 8),
          Expanded(
            child: Container(
              width: double.infinity,
              color: Colors.black,
              child: Image.memory(preview, fit: BoxFit.contain),
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                _filterChip('Original', _PageFilter.original),
                _filterChip('B & W', _PageFilter.bw),
                _filterChip('Grayscale', _PageFilter.grayscale),
                _filterChip('Enhance', _PageFilter.enhance),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              12,
              10,
              12,
              16 + MediaQuery.of(context).padding.bottom,
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _commitScannedPage(goToCaptureAfter: true),
                    child: const Text('Add Page'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    onPressed: () => _commitScannedPage(goToCaptureAfter: false),
                    child: const Text('Review'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, _PageFilter value) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: _activeFilter == value,
        onSelected: (_) => setState(() => _activeFilter = value),
      ),
    );
  }

  Widget _buildReview() {
    return Scaffold(
      appBar: AppBar(title: const Text('Review & Save')),
      body: Column(
        children: [
          const SizedBox(height: 8),
          const InlineBannerAd(),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Text('Pages: ${_pages.length}', style: const TextStyle(fontWeight: FontWeight.w700)),
                const Spacer(),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 170),
                  child: OutlinedButton.icon(
                    onPressed: () => setState(() => _stage = _ScanStage.capture),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Page'),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _pages.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.layers_outlined, size: 56, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          Text(
                            'No pages yet',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Capture a page, apply a filter, then tap Review or Add Page.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey.shade600, height: 1.35),
                          ),
                          const SizedBox(height: 20),
                          FilledButton.icon(
                            onPressed: () => setState(() => _stage = _ScanStage.capture),
                            icon: const Icon(Icons.camera_alt_outlined),
                            label: const Text('Start scanning'),
                          ),
                        ],
                      ),
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: PageView.builder(
                              controller: _reviewPageController ??= PageController(
                                initialPage: _reviewPageIndex.clamp(0, _pages.length - 1),
                              ),
                              itemCount: _pages.length,
                              onPageChanged: (i) => setState(() => _reviewPageIndex = i),
                              itemBuilder: (_, i) {
                                final p = _pages[i];
                                return LayoutBuilder(
                                  builder: (context, constraints) {
                                    final w = constraints.maxWidth;
                                    final h = constraints.maxHeight;
                                    if (w <= 0 || h <= 0) {
                                      return const Center(child: CircularProgressIndicator());
                                    }
                                    // Explicit size avoids InteractiveViewer + Image getting
                                    // unbounded constraints (blank preview on some devices).
                                    return InteractiveViewer(
                                      minScale: 0.35,
                                      maxScale: 5,
                                      constrained: true,
                                      boundaryMargin: const EdgeInsets.all(64),
                                      child: SizedBox(
                                        width: w,
                                        height: h,
                                        child: Image.memory(
                                          p.bytes,
                                          fit: BoxFit.contain,
                                          gaplessPlayback: true,
                                          errorBuilder: (_, __, ___) => const Padding(
                                            padding: EdgeInsets.all(24),
                                            child: Text('Could not display this page.'),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                      if (_pages.length > 1)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'Page ${_reviewPageIndex + 1} of ${_pages.length} — swipe',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 116,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          itemCount: _pages.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (_, i) {
                            final p = _pages[i];
                            final selected = i == _reviewPageIndex;
                            return InkWell(
                              onTap: () {
                                _reviewPageController?.jumpToPage(i);
                                setState(() => _reviewPageIndex = i);
                              },
                              child: Stack(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: selected
                                            ? const Color(0xFF1857E6)
                                            : Colors.transparent,
                                        width: 3,
                                      ),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.memory(
                                        p.bytes,
                                        width: 80,
                                        height: 108,
                                        fit: BoxFit.cover,
                                        gaplessPlayback: true,
                                        errorBuilder: (_, __, ___) => Container(
                                          width: 80,
                                          height: 108,
                                          color: Colors.grey.shade300,
                                          child: const Icon(Icons.broken_image_outlined),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    right: 2,
                                    top: 2,
                                    child: InkWell(
                                      onTap: () {
                                        setState(() {
                                          _pages.removeAt(i);
                                          _reviewPageIndex =
                                              _pages.isEmpty ? 0 : _reviewPageIndex.clamp(0, _pages.length - 1);
                                          if (_pages.isEmpty) {
                                            _reviewPageController?.dispose();
                                            _reviewPageController = null;
                                          }
                                        });
                                        WidgetsBinding.instance.addPostFrameCallback((_) {
                                          if (!mounted || _pages.isEmpty) return;
                                          _reviewPageController?.jumpToPage(_reviewPageIndex);
                                        });
                                      },
                                      child: const CircleAvatar(
                                        radius: 10,
                                        backgroundColor: Colors.black54,
                                        child: Icon(Icons.close, size: 12, color: Colors.white),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              12,
              8,
              12,
              16 + MediaQuery.of(context).padding.bottom,
            ),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _pages.isEmpty ? null : _savePdf,
                icon: const Icon(Icons.picture_as_pdf_outlined),
                label: const Text('Save as PDF'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Rect _containRect(Size container, Size image) {
    final imageRatio = image.width / image.height;
    final containerRatio = container.width / container.height;
    if (imageRatio > containerRatio) {
      final width = container.width;
      final height = width / imageRatio;
      final top = (container.height - height) / 2;
      return Rect.fromLTWH(0, top, width, height);
    }
    final height = container.height;
    final width = height * imageRatio;
    final left = (container.width - width) / 2;
    return Rect.fromLTWH(left, 0, width, height);
  }
}

class _CornersPainter extends CustomPainter {
  final List<Offset> corners;
  final Rect imageRect;
  const _CornersPainter({required this.corners, required this.imageRect});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    for (int i = 0; i < corners.length; i++) {
      final p = Offset(
        imageRect.left + corners[i].dx * imageRect.width,
        imageRect.top + corners[i].dy * imageRect.height,
      );
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    path.close();
    final line = Paint()
      ..color = const Color(0xFF1857E6)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, line);
    final pointPaint = Paint()..color = const Color(0xFF1857E6);
    for (final c in corners) {
      final p = Offset(
        imageRect.left + c.dx * imageRect.width,
        imageRect.top + c.dy * imageRect.height,
      );
      canvas.drawCircle(p, 12, pointPaint);
      canvas.drawCircle(
        p,
        16,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CornersPainter oldDelegate) =>
      oldDelegate.corners != corners || oldDelegate.imageRect != imageRect;
}
