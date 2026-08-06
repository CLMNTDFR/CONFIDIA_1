import 'package:flutter/material.dart';

import '../../core/theme/spacing.dart';
import '../../core/theme/tokens/app_spacing.dart';

/// Insets liés au shell mobile (bottom bar + safe area).
abstract final class ConfidiaMobileShell {
  /// Hauteur du chrome nav hors safe area (padding 8×2 + icône + label + pads item).
  static const double navBarHeight = AppSpacing.navBarHeight;

  /// Air confortable entre le bas du contenu / FAB et le haut de la barre.
  static const double contentGap = AppSpacing.md;

  static bool isMobileShell(BuildContext context) => MediaQuery.sizeOf(context).width < 900;

  /// Emprise réelle de la barre (chrome + home indicator), sans marge de confort.
  static double barOccupiedHeight(BuildContext context) {
    if (!isMobileShell(context)) return 0;
    return navBarHeight + MediaQuery.viewPaddingOf(context).bottom;
  }

  /// Espace à réserver sous le contenu scrollable (barre + safe area + air).
  static double bottomScrollInset(BuildContext context) {
    if (!isMobileShell(context)) return 0;
    return barOccupiedHeight(context) + contentGap;
  }

  /// Décalage pour FAB / actions flottantes au-dessus de la barre.
  static double fabBottom(BuildContext context, {double gap = contentGap}) {
    if (!isMobileShell(context)) return gap + ConfidiaSpacing.lg;
    return barOccupiedHeight(context) + gap;
  }

  /// Padding scroll supplémentaire pour ne pas passer sous un FAB (~40 px).
  static double fabScrollClearance({double fabHeight = 40}) => fabHeight + contentGap;
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
