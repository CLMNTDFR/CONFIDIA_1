import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../core/theme/tokens/tokens.dart';

class SkeletonBox extends StatelessWidget {
  final double? width;
  final double height;
  final BorderRadius borderRadius;

  const SkeletonBox({super.key, this.width, this.height = 16, this.borderRadius = const BorderRadius.all(Radius.circular(8))});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? AppColors.darkSurface2 : const Color(0xFFE8E8EE);
    final highlight = isDark
        ? Color.lerp(AppColors.darkSurface2, Colors.white, 0.12)!
        : Colors.white;

    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: highlight,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(color: base, borderRadius: borderRadius),
      ),
    );
  }
}

class SkeletonCard extends StatelessWidget {
  const SkeletonCard({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface1(isDark),
          borderRadius: BorderRadius.circular(16),
          border: Border.fromBorderSide(AppBorders.standard(isDark)),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkeletonBox(width: 120, height: 12),
            SizedBox(height: 12),
            SkeletonBox(height: 18),
            SizedBox(height: 8),
            SkeletonBox(width: 200, height: 14),
          ],
        ),
      ),
    );
  }
}
