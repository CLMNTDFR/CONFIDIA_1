/// Design System spacing (strict 4 px grid).
///
/// Main scale: 4 · 8 · 16 · 24 · 32 · 48 · 64.
/// Intermediate steps: 12 · 20 · 28 (when a step between sm/md or lg/xl is useful).
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double s = 12;
  static const double md = 16;
  static const double m = 20;
  static const double lg = 24;
  static const double l = 28;
  static const double xl = 32;
  static const double xxl = 48;
  static const double xxxl = 64;

  static const double sidebarWidth = 260;
  static const double sidebarCollapsedWidth = 72;
  static const double topBarHeight = 64;
  static const double maxContentWidth = 1400;

  /// Material [NavigationBarThemeData] height.
  static const double materialNavBarHeight = 68;

  /// Custom chrome bottom nav (padding + icon + label), excluding safe area.
  static const double navBarHeight = 72;
}
