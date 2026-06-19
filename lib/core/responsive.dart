import 'package:flutter/widgets.dart';

/// MediaQuery-backed responsive helpers.
///
/// Designed for a phone-first app. Paddings and sizes scale smoothly
/// from small Android phones (~320 px) up to phablets (~480 px). On
/// tablets (≥ 600 px) bottom sheets and dialogs get a max-width cap
/// so modal content doesn't span a 10-inch screen.
///
/// Accessed via the [BuildContext] extension:
///
/// ```dart
/// final edge = context.responsive.edgePad;     // 12 / 16 / 20
/// final padded = context.responsive.pad(14);   // scales 0.88–1.10×
/// if (context.responsive.isCompact) { ... }
/// ```
///
/// Fonts are intentionally **not** scaled here — Flutter's built-in
/// [TextScaler] handles accessibility text size from OS settings, and
/// layering another factor on top makes text jump awkwardly between
/// devices. The inner spacings scale instead so the composition stays
/// proportional regardless of font metrics.
class Responsive {
  Responsive._(this._size, this._insets);

  factory Responsive.of(BuildContext context) {
    final mq = MediaQuery.of(context);
    return Responsive._(mq.size, mq.viewInsets);
  }

  final Size _size;
  final EdgeInsets _insets;

  // ──────────── raw values ────────────
  double get width => _size.width;
  double get height => _size.height;

  /// Bottom inset from a visible soft keyboard.
  double get keyboardInset => _insets.bottom;

  // ──────────── categories ────────────
  /// Very small phones (≤ iPhone SE 1st gen, older compact Androids).
  bool get isCompact => _size.width < 360;

  /// Phone-range width.
  bool get isPhone => _size.width < 600;

  /// Tablet / foldable width.
  bool get isTablet => _size.width >= 600;

  // ──────────── scaling ────────────
  /// 0.88 – 1.10, anchored on a 375 px design width.
  /// Clamped so the UI never squeezes too tight or sprawls too loose.
  double get _scale => (_size.width / 375).clamp(0.88, 1.10);

  /// Scale a design-time dimension (padding, margin, icon size, …).
  double pad(double base) => base * _scale;

  // ──────────── adaptive values ────────────
  /// Outer screen edge padding — tighter on small phones, roomier on
  /// phablets. Fixed at three discrete values to keep layouts crisp.
  double get edgePad {
    if (_size.width < 360) return 12;
    if (_size.width > 420) return 20;
    return 16;
  }

  /// Max width for modal bottom sheets so they don't span a tablet.
  double get sheetMaxWidth => isTablet ? 560 : double.infinity;

  /// Max width for primary content columns on tablets.
  double get contentMaxWidth => isTablet ? 680 : double.infinity;
}

extension ResponsiveX on BuildContext {
  Responsive get responsive => Responsive.of(this);
}
