import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/theme_context.dart';
import '../../core/theme/tokens/tokens.dart';
import 'confidia_chrome_material.dart';
import 'confidia_tappable.dart';

/// Entrée d'un menu CONFIDIA (actions ou liste déroulante).
class ConfidiaMenuEntry<T> {
  final T value;
  final String label;
  final IconData? icon;
  final bool destructive;
  final bool selected;
  final bool enabled;

  const ConfidiaMenuEntry({
    required this.value,
    required this.label,
    this.icon,
    this.destructive = false,
    this.selected = false,
    this.enabled = true,
  });
}

/// Menu flottant ancré sur le widget appelant.
/// Même matière chrome que les modales, aéré, avec survol.
Future<T?> showConfidiaMenu<T>({
  required BuildContext context,
  required List<ConfidiaMenuEntry<T>> items,
  bool matchAnchorWidth = false,
  double minWidth = 228,
  double maxWidth = 320,
}) {
  if (items.isEmpty) return Future<T?>.value();

  final box = context.findRenderObject();
  if (box is! RenderBox || !box.hasSize) return Future<T?>.value();

  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  final overlayBox = overlay?.context.findRenderObject();
  if (overlayBox is! RenderBox) return Future<T?>.value();

  final origin = box.localToGlobal(Offset.zero, ancestor: overlayBox);
  final anchor = origin & box.size;
  final screen = overlayBox.size;

  return showGeneralDialog<T>(
    context: context,
    useRootNavigator: true,
    barrierDismissible: true,
    barrierLabel: 'Fermer le menu',
    barrierColor: Colors.transparent,
    transitionDuration: AppDurations.quick,
    pageBuilder: (context, animation, secondaryAnimation) => const SizedBox.shrink(),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return _ConfidiaMenuLayer<T>(
        animation: animation,
        items: items,
        anchor: anchor,
        screen: screen,
        matchAnchorWidth: matchAnchorWidth,
        minWidth: minWidth,
        maxWidth: maxWidth,
      );
    },
  );
}

/// Bouton icône qui ouvre [showConfidiaMenu], calé sur [IconButton] compact.
class ConfidiaMenuButton<T> extends StatelessWidget {
  final List<ConfidiaMenuEntry<T>> items;
  final ValueChanged<T> onSelected;
  final IconData icon;
  final String? tooltip;

  const ConfidiaMenuButton({
    super.key,
    required this.items,
    required this.onSelected,
    this.icon = Icons.more_vert_rounded,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      visualDensity: VisualDensity.compact,
      tooltip: tooltip,
      icon: Icon(icon),
      onPressed: () async {
        final selected = await showConfidiaMenu<T>(context: context, items: items);
        if (!context.mounted || selected == null) return;
        onSelected(selected);
      },
    );
  }
}

class _ConfidiaMenuLayer<T> extends StatelessWidget {
  final Animation<double> animation;
  final List<ConfidiaMenuEntry<T>> items;
  final Rect anchor;
  final Size screen;
  final bool matchAnchorWidth;
  final double minWidth;
  final double maxWidth;

  const _ConfidiaMenuLayer({
    required this.animation,
    required this.items,
    required this.anchor,
    required this.screen,
    required this.matchAnchorWidth,
    required this.minWidth,
    required this.maxWidth,
  });

  static const double _gap = 8;
  static const double _edge = 12;
  static const double _itemExtent = 48;
  static const double _panelPad = 10;
  static const double _maxHeight = 360;

  @override
  Widget build(BuildContext context) {
    final available = math.max(120.0, screen.width - _edge * 2);
    final width = (matchAnchorWidth
            ? anchor.width.clamp(math.min(minWidth, available), available)
            : minWidth.clamp(math.min(minWidth, available), math.min(maxWidth, available)))
        .toDouble();

    final estimated = math.min(_maxHeight, _panelPad * 2 + items.length * _itemExtent + 8);
    final spaceBelow = screen.height - anchor.bottom - _gap - _edge;
    final spaceAbove = anchor.top - _gap - _edge;
    final openDown = spaceBelow >= estimated || spaceBelow >= spaceAbove;

    final maxPanelHeight =
        math.min(_maxHeight, math.max(96.0, openDown ? spaceBelow : spaceAbove)).toDouble();
    final panelHeight = math.min(estimated, maxPanelHeight);

    var top = openDown ? anchor.bottom + _gap : anchor.top - _gap - panelHeight;
    top = top.clamp(_edge, math.max(_edge, screen.height - _edge - 80)).toDouble();

    var left = matchAnchorWidth ? anchor.left : anchor.right - width;
    left = left.clamp(_edge, math.max(_edge, screen.width - width - _edge)).toDouble();

    final alignment = openDown
        ? (matchAnchorWidth ? Alignment.topCenter : Alignment.topRight)
        : (matchAnchorWidth ? Alignment.bottomCenter : Alignment.bottomRight);

    final curve = animation.status == AnimationStatus.reverse ? Curves.easeInCubic : Curves.easeOutCubic;

    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final t = curve.transform(animation.value.clamp(0.0, 1.0)).clamp(0.0, 1.0).toDouble();
        return SizedBox.expand(
          child: Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => Navigator.of(context).pop(),
                ),
              ),
              Positioned(
                left: left,
                top: top,
                width: width,
                child: Opacity(
                  opacity: t,
                  child: Transform.translate(
                    offset: Offset(0, openDown ? (1 - t) * 8 : (t - 1) * 8),
                    child: Transform.scale(
                      alignment: alignment,
                      scale: 0.96 + (0.04 * t),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minWidth: width,
                          maxWidth: width,
                          maxHeight: maxPanelHeight,
                        ),
                        child: ConfidiaChromeMaterial(
                          borderRadius: AppRadius.lgAll,
                          padding: const EdgeInsets.all(_panelPad),
                          child: Material(
                            type: MaterialType.transparency,
                            child: SingleChildScrollView(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  for (var i = 0; i < items.length; i++) ...[
                                    if (i > 0 && items[i].destructive && !items[i - 1].destructive)
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(10, 4, 10, 8),
                                        child: Divider(
                                          height: 1,
                                          color: ConfidiaColors.border(Theme.of(context).brightness == Brightness.dark),
                                        ),
                                      ),
                                    if (i > 0 && !(items[i].destructive && !items[i - 1].destructive))
                                      const SizedBox(height: 2),
                                    _ConfidiaMenuTile<T>(entry: items[i]),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ConfidiaMenuTile<T> extends StatelessWidget {
  final ConfidiaMenuEntry<T> entry;

  const _ConfidiaMenuTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palette = context.palette;
    final muted = ConfidiaColors.textSecondary(isDark);
    final Color fg;
    if (!entry.enabled) {
      fg = muted.withValues(alpha: 0.45);
    } else if (entry.destructive) {
      fg = ConfidiaColors.error;
    } else if (entry.selected) {
      fg = palette.primary;
    } else {
      fg = ConfidiaColors.textPrimary(isDark);
    }

    return ConfidiaTappable(
      onTap: entry.enabled ? () => Navigator.of(context).pop(entry.value) : null,
      pressScale: 0.98,
      borderRadius: AppRadius.mdAll,
      child: AnimatedContainer(
        duration: AppDurations.fast,
        curve: Curves.easeOut,
        constraints: const BoxConstraints(minHeight: 44),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: AppRadius.mdAll,
          color: entry.selected
              ? palette.primary.withValues(alpha: isDark ? AppOpacity.tintSoft : AppOpacity.tintQuiet)
              : Colors.transparent,
        ),
        child: Row(
          children: [
            if (entry.icon != null) ...[
              Icon(entry.icon, size: 18, color: fg),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(
                entry.label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: entry.selected ? FontWeight.w600 : FontWeight.w500,
                      fontSize: 13.5,
                      height: 1.3,
                      color: fg,
                    ),
              ),
            ),
            if (entry.selected) ...[
              const SizedBox(width: 8),
              Icon(Icons.check_rounded, size: 18, color: fg),
            ],
          ],
        ),
      ),
    );
  }
}
