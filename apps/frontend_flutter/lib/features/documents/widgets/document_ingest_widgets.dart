import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';
import '../../../shared/widgets/confidia_button.dart';

/// En-tête centré pour l'écran d'ajout document.
class DocumentIngestHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const DocumentIngestHeader({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = ConfidiaColors.textSecondary(isDark);

    return Column(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: ConfidiaColors.surface2(isDark),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: muted, size: 26),
        ),
        const SizedBox(height: 16),
        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.45),
        ),
      ],
    );
  }
}

/// Zone de prévisualisation ; pulse uniquement à vide.
class DocumentIngestPreviewZone extends StatefulWidget {
  final double height;
  final Widget? child;
  final IconData emptyIcon;
  final String emptyTitle;
  final String emptySubtitle;
  final VoidCallback? onTap;

  const DocumentIngestPreviewZone({
    super.key,
    required this.height,
    this.child,
    required this.emptyIcon,
    required this.emptyTitle,
    required this.emptySubtitle,
    this.onTap,
  });

  @override
  State<DocumentIngestPreviewZone> createState() => _DocumentIngestPreviewZoneState();
}

class _DocumentIngestPreviewZoneState extends State<DocumentIngestPreviewZone>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  bool get _hasContent => widget.child != null;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200));
    if (!_hasContent) _pulse.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant DocumentIngestPreviewZone oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_hasContent) {
      _pulse.stop();
    } else if (!_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = ConfidiaColors.textSecondary(isDark);

    Widget zone;
    if (_hasContent) {
      zone = _zone(context, muted, isDark, borderAlpha: 0.2, child: widget.child);
    } else {
      zone = AnimatedBuilder(
        animation: _pulse,
        builder: (context, _) => _zone(
          context,
          muted,
          isDark,
          borderAlpha: 0.12 + _pulse.value * 0.1,
          child: null,
        ),
      );
    }

    if (widget.onTap == null) return zone;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(ConfidiaSpacing.radiusMd),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: widget.onTap,
        mouseCursor: SystemMouseCursors.click,
        borderRadius: BorderRadius.circular(ConfidiaSpacing.radiusMd),
        child: zone,
      ),
    );
  }

  Widget _zone(
    BuildContext context,
    Color muted,
    bool isDark, {
    required double borderAlpha,
    required Widget? child,
  }) {
    return Container(
      height: widget.height,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(ConfidiaSpacing.radiusMd),
        border: Border.all(color: muted.withValues(alpha: borderAlpha), width: 1.5),
        color: muted.withValues(alpha: isDark ? 0.06 : 0.04),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(ConfidiaSpacing.radiusMd),
        child: child ??
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(widget.emptyIcon, size: 48, color: muted.withValues(alpha: 0.7)),
                const SizedBox(height: 12),
                Text(
                  widget.emptyTitle,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.emptySubtitle,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: ConfidiaColors.textSecondary(isDark),
                      ),
                ),
              ],
            ),
      ),
    );
  }
}

/// Ligne fichier compacte pour l'écran d'ajout.
class DocumentFileRow extends StatelessWidget {
  final String name;
  final String sizeLabel;
  final VoidCallback onRemove;

  const DocumentFileRow({
    super.key,
    required this.name,
    required this.sizeLabel,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = ConfidiaColors.textSecondary(isDark);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ConfidiaColors.border(isDark)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: muted.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.insert_drive_file_rounded, size: 18, color: muted),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.labelLarge),
                Text(sizeLabel, style: Theme.of(context).textTheme.labelSmall),
              ],
            ),
          ),
          ConfidiaCloseButton(
            tooltip: 'Retirer',
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}
