import 'package:flutter/material.dart';

import '../../core/theme/spacing.dart';
import '../../core/theme/tokens/tokens.dart';
import '../../shared/widgets/confidia_tappable.dart';

/// Deux actions Scanner / Importer (liste Documents + sheet dashboard).
class DocumentSourceActions extends StatelessWidget {
  final VoidCallback? onScan;
  final VoidCallback? onImport;
  /// Empile verticalement (sheet) au lieu d'une rangée.
  final bool stacked;

  const DocumentSourceActions({
    super.key,
    this.onScan,
    this.onImport,
    this.stacked = false,
  });

  @override
  Widget build(BuildContext context) {
    const gap = ConfidiaSpacing.sm;
    final scan = DocumentSourceCard(
      title: 'Scanner',
      icon: Icons.document_scanner_rounded,
      onTap: onScan,
    );
    final import = DocumentSourceCard(
      title: 'Importer',
      icon: Icons.upload_rounded,
      onTap: onImport,
    );

    if (stacked) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          scan,
          const SizedBox(height: gap),
          import,
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: scan),
        const SizedBox(width: gap),
        Expanded(child: import),
      ],
    );
  }
}

/// Même langage que le sélecteur Mois / Semaine / Jour : lave grise, bordure, ombre douce.
class DocumentSourceCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback? onTap;

  const DocumentSourceCard({
    super.key,
    required this.title,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? Colors.white : Colors.black;
    final radius = AppRadius.mdAll;

    return ConfidiaTappable(
      onTap: onTap,
      pressScale: 0.98,
      borderRadius: radius,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: radius,
          border: Border.fromBorderSide(AppBorders.standard(isDark)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.12 : 0.05),
              blurRadius: 12,
              spreadRadius: -4,
            ),
          ],
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              ink.withValues(alpha: isDark ? 0.07 : 0.055),
              ink.withValues(alpha: isDark ? 0.03 : 0.02),
            ],
            stops: const [0.0, 0.55],
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: AppColors.textSecondary(isDark)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                  color: AppColors.textPrimary(isDark),
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 16,
              color: AppColors.textSecondary(isDark).withValues(alpha: 0.65),
            ),
          ],
        ),
      ),
    );
  }
}
