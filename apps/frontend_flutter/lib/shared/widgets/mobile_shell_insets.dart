import 'package:flutter/material.dart';

import '../../core/theme/spacing.dart';

/// Insets liés au shell mobile (bottom bar flottante + safe area).
abstract final class ConfidiaMobileShell {
  /// Hauteur utile de la barre (icônes + labels + padding interne).
  static const double navBarHeight = 58;

  static bool isMobileShell(BuildContext context) => MediaQuery.sizeOf(context).width < 900;

  /// Espace à réserver sous le contenu scrollable.
  static double bottomScrollInset(BuildContext context) {
    if (!isMobileShell(context)) return 0;
    return navBarHeight + MediaQuery.viewPaddingOf(context).bottom;
  }

  /// Décalage pour FAB / actions flottantes au-dessus de la barre.
  static double fabBottom(BuildContext context, {double gap = ConfidiaSpacing.sm}) {
    if (!isMobileShell(context)) return gap + ConfidiaSpacing.lg;
    return bottomScrollInset(context) + gap;
  }
}

/// Padding de page cohérent avec le shell mobile.
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

  /// Espace final sous une liste (padding latéral déjà géré ailleurs).
  static double scrollTail(BuildContext context) {
    if (MediaQuery.sizeOf(context).width >= 900) return ConfidiaSpacing.lg;
    return ConfidiaSpacing.lg + ConfidiaMobileShell.bottomScrollInset(context);
  }
}
