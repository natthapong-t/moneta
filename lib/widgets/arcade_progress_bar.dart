import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

/// Reusable Duolingo-style Chunky 3D Progress Bar
class ArcadeProgressBar extends StatelessWidget {
  final double value; // 0.0 to 1.0
  final Color? progressColor;
  final Color backgroundColor;
  final double height;
  final BorderRadius? borderRadius;

  const ArcadeProgressBar({
    super.key,
    required this.value,
    this.progressColor,
    this.backgroundColor = AppColors.surfaceLight,
    this.height = 8.0,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = borderRadius ?? BorderRadius.circular(height / 2);
    final clampedValue = value.clamp(0.0, 1.0);

    // Dynamic default color if not explicitly provided
    final effectiveProgressColor = progressColor ??
        (clampedValue > 0.85
            ? AppColors.waxSealRed
            : (clampedValue > 0.65 ? AppColors.gold : const Color(0xFF10B981)));

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: effectiveRadius,
        border: Border.all(color: AppColors.border, width: 1.0),
      ),
      child: ClipRRect(
        borderRadius: effectiveRadius,
        child: FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: clampedValue,
          child: Container(
            decoration: BoxDecoration(
              color: effectiveProgressColor,
              borderRadius: effectiveRadius,
            ),
          ),
        ),
      ),
    );
  }
}
