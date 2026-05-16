import 'package:flutter/widgets.dart';

/// Bottom padding for scrollables on scaffolds that extend edge-to-edge
/// (no [SafeArea] shrinking the body). Use for [ListView] / [SingleChildScrollView]
/// `padding.bottom` so controls clear the home indicator without a dead band.
double edgeToEdgeBottomPadding(BuildContext context, {double extra = 16}) {
  final m = MediaQuery.of(context);
  if (m.viewInsets.bottom > 0) {
    return extra + m.viewInsets.bottom + m.padding.bottom;
  }
  return extra + m.padding.bottom;
}

/// Bottom inset for scroll views, list padding, and fixed bottom toolbars.
///
/// Under [SafeArea], [MediaQuery.padding] bottom is often zero while the
/// physical inset remains in [viewPadding]. Using only [padding] then clips
/// the last control and shows a seam above the system nav bar.
///
/// When the keyboard is open ([viewInsets] non-zero), returns
/// `viewInsets.bottom + padding.bottom` so content clears the IME.
///
/// Prefer [edgeToEdgeBottomPadding] when the scaffold body has no bottom
/// [SafeArea].
double scrollBottomInset(BuildContext context) {
  final m = MediaQuery.of(context);
  if (m.viewInsets.bottom > 0) {
    return m.viewInsets.bottom + m.padding.bottom;
  }
  if (m.padding.bottom >= m.viewPadding.bottom) {
    return m.padding.bottom;
  }
  return m.viewPadding.bottom;
}

/// Bottom padding for scroll content whose parent already applies
/// [SafeArea] on the bottom edge.
///
/// The gesture / home-indicator inset is **outside** the child's layout box,
/// so adding [viewPadding.bottom] again (via [scrollBottomInset]) **double
/// counts** and shows as an empty band (often very visible in dark theme).
///
/// Still adds space when the **keyboard** is open ([viewInsets]).
double scrollBottomInsetUnderSafeArea(BuildContext context) {
  final m = MediaQuery.of(context);
  if (m.viewInsets.bottom > 0) {
    return m.viewInsets.bottom + m.padding.bottom;
  }
  return 0;
}
