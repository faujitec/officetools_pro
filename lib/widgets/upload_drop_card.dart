import 'package:flutter/material.dart';

/// Dashed-card upload area used across tools (matches Image Tools picker style).
class UploadDropCard extends StatelessWidget {
  final VoidCallback? onTap;
  final String title;
  final String subtitle;
  final Widget? preview;
  final bool isDark;

  const UploadDropCard({
    super.key,
    required this.onTap,
    required this.isDark,
    this.title = 'Choose Image',
    this.subtitle = 'Tap to upload from gallery',
    this.preview,
  });

  @override
  Widget build(BuildContext context) {
    final hasPreview = preview != null;
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
          child: hasPreview
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(26),
                  child: preview!,
                )
              : Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.add_photo_alternate_outlined,
                        size: 54,
                        color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
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
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
