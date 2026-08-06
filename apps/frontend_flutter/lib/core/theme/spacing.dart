import 'tokens/app_radius.dart';
import 'tokens/app_spacing.dart';

/// Façade rétrocompatible. Source : [AppSpacing] / [AppRadius].
abstract final class ConfidiaSpacing {
  static const double xs = AppSpacing.xs;
  static const double sm = AppSpacing.sm;
  static const double md = AppSpacing.md;
  static const double lg = AppSpacing.lg;
  static const double xl = AppSpacing.xl;
  static const double xxl = AppSpacing.xxl;
  static const double xxxl = AppSpacing.xxxl;

  static const double radiusSm = AppRadius.sm;
  static const double radiusMd = AppRadius.md;
  static const double radiusLg = AppRadius.lg;
  static const double radiusXl = AppRadius.xxl;

  static const double sidebarWidth = AppSpacing.sidebarWidth;
  static const double sidebarCollapsedWidth = AppSpacing.sidebarCollapsedWidth;
  static const double topBarHeight = AppSpacing.topBarHeight;
  static const double maxContentWidth = AppSpacing.maxContentWidth;
}
