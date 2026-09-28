import 'package:flutter/material.dart';

import '../../core/theme/spacing.dart';
import '../../core/theme/tokens/app_spacing.dart';

/// Insets tied to the mobile shell (bottom bar + safe area).
abstract final class ConfidiaMobileShell {
  /// Nav chrome height excluding the safe area (8×2 padding + icon + label + item pads).
  static const double navBarHeight = AppSpacing.navBarHeight;

  /// Comfort gap between the bottom of the content / FAB and the top of the bar.
  static const double contentGap = AppSpacing.md;

  static bool isMobileShell(BuildContext context) => MediaQuery.sizeOf(context).width < 900;

  /// Actual bar occupancy (chrome + home indicator), without the comfort margin.
  static double barOccupiedHeight(BuildContext context) {
    if (!isMobileShell(context)) return 0;
    return navBarHeight + MediaQuery.viewPaddingOf(context).bottom;
  }

  /// Space to reserve under scrollable content (bar + safe area + gap).
  static double bottomScrollInset(BuildContext context) {
    if (!isMobileShell(context)) return 0;
    return barOccupiedHeight(context) + contentGap;
  }

  /// Offset for FAB / floating actions above the bar.
  static double fabBottom(BuildContext context, {double gap = contentGap}) {
    if (!isMobileShell(context)) return gap + ConfidiaSpacing.lg;
    return barOccupiedHeight(context) + gap;
  }

  /// Extra scroll padding so content does not pass under a FAB (~40 px).
  static double fabScrollClearance({double fabHeight = 40}) => fabHeight + contentGap;
}

/// Page padding consistent with the mobile shell.
abstract final class ConfidiaInsets {
  static EdgeInsets page(BuildContext context) {
    final isMobile = ConfidiaMobileShell.isMobileShell(context);
    final side = isMobile ? ConfidiaSpacing.md : ConfidiaSpacing.lg;
    return EdgeInsets.fromLTRB(side, side, side, side + ConfidiaMobileShell.bottomScrollInset(context));
  }

  static EdgeInsets pageBottom(BuildContext context) {
    return EdgeInsets.only(bottom: ConfidiaMobileShell.bottomScrollInset(context));
  }

  static EdgeInsets list(BuildContext context) {
    return page(context);
  }

  static EdgeInsets pageWithExtra(BuildContext context, {double extraBottom = 0}) {
    final base = page(context);
    return base.copyWith(bottom: base.bottom + extraBottom);
  }

  /// Trailing space under a list (horizontal padding already handled elsewhere).
  static double scrollTail(BuildContext context) {
    if (MediaQuery.sizeOf(context).width >= 900) return ConfidiaSpacing.lg;
    return ConfidiaSpacing.lg + ConfidiaMobileShell.bottomScrollInset(context);
  }
}
