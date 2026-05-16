import 'package:flutter/material.dart';

/// Dashed-card upload area used across tools (matches Image Tools picker style).
class UploadDropCard extends StatelessWidget {
  final VoidCallback? onTap;
  final String title;
  final String subtitle;
  final Widget? preview;
  final bool isDark;

  /// When set together with [preview], only the preview slot uses this
  /// width/height ratio (full card width). Controls outside this widget are
  /// unaffected.
  final double? previewAspectRatio;

  /// Max height of the preview slot when [previewAspectRatio] is set.
  final double? maxPreviewHeight;

  const UploadDropCard({
    super.key,
    required this.onTap,
    required this.isDark,
    this.title = 'Choose Image',
    this.subtitle = 'Tap to upload from gallery',
    this.preview,
    this.previewAspectRatio,
    this.maxPreviewHeight,
  });

  @override
  Widget build(BuildContext context) {
    final hasPreview = preview != null;
    final heightCap =
        maxPreviewHeight ?? MediaQuery.sizeOf(context).height * 0.52;

    final Widget body;
    if (!hasPreview) {
      body = Padding(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.add_photo_alternate_outlined,
              size: 54,
              color: isDark
                  ? const Color(0xFF64748B)
                  : const Color(0xFF94A3B8),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF0F172A),
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark
                    ? const Color(0xFF94A3B8)
                    : const Color(0xFF64748B),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    } else if (previewAspectRatio != null) {
      body = ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            if (w <= 0) return const SizedBox.shrink();
            final ar = previewAspectRatio!;
            var slotH = w / ar;
            if (slotH > heightCap) slotH = heightCap;
            return SizedBox(
              width: w,
              height: slotH,
              child: preview!,
            );
          },
        ),
      );
    } else {
      body = ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: preview!,
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(26),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFDCE2EB),
              width: 1.5,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x12000000),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: body,
        ),
      ),
    );
  }
}
