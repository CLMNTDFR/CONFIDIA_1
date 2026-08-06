import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/theme_context.dart';

/// En-tête centré pour les écrans scan / import.
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
    final palette = context.palette;

    return Column(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            gradient: palette.accentGradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: palette.primary.withValues(alpha: 0.22),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 26),
        ),
        const SizedBox(height: 14),
        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.45),
        ),
      ],
    );
  }
}

/// Zone de prévisualisation avec animation pulse lorsqu'elle est vide.
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

class _DocumentIngestPreviewZoneState extends State<DocumentIngestPreviewZone> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palette = context.palette;
    final hasContent = widget.child != null;

    final zone = AnimatedBuilder(
      animation: _pulse,
      builder: (context, _) {
        final pulseAlpha = hasContent ? 0.25 : 0.18 + _pulse.value * 0.14;
        return Container(
          height: widget.height,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(ConfidiaSpacing.radiusMd),
            border: Border.all(color: palette.primary.withValues(alpha: pulseAlpha), width: 1.5),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                palette.primary.withValues(alpha: isDark ? 0.08 : 0.04),
                palette.secondary.withValues(alpha: isDark ? 0.06 : 0.03),
              ],
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(ConfidiaSpacing.radiusMd - 1),
            child: widget.child ??
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(widget.emptyIcon, size: 48, color: palette.primary.withValues(alpha: 0.55)),
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
      },
    );

    if (widget.onTap == null) return zone;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(ConfidiaSpacing.radiusMd),
        child: zone,
      ),
    );
  }
}

/// Ligne fichier compacte pour l'écran d'import.
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
    final palette = context.palette;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
              color: palette.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.insert_drive_file_rounded, size: 18, color: palette.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.labelLarge),
                Text(sizeLabel, style: Theme.of(context).textTheme.labelSmall),
              ],
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: Icon(Icons.close_rounded, size: 18, color: ConfidiaColors.textSecondary(isDark)),
            onPressed: onRemove,
            tooltip: 'Retirer',
          ),
        ],
      ),
    );
  }
}
