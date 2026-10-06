import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

/// Reusable Cartoon Pill / Badge Widget
/// Used for counters, streak status, metric tags, and category chips
class ArcadeBadge extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Widget? leading;
  final Color color;
  final Color? textColor;
  final Color? iconColor;
  final Color? borderColor;
  final Color? shadowColor;
  final double depth;
  final EdgeInsetsGeometry padding;
  final double fontSize;
  final FontWeight fontWeight;
  final BorderRadius? borderRadius;

  const ArcadeBadge({
    super.key,
    required this.label,
    this.icon,
    this.leading,
    this.color = AppColors.surfaceLight,
    this.textColor,
    this.iconColor,
    this.borderColor,
    this.shadowColor,
    this.depth = 2.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    this.fontSize = 11.5,
    this.fontWeight = FontWeight.w800,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveTextColor = textColor ?? AppColors.textPrimary;
    final effectiveIconColor = iconColor ?? effectiveTextColor;
    final effectiveBorderColor = borderColor ?? (shadowColor ?? AppColors.borderDark);
    final effectiveRadius = borderRadius ?? BorderRadius.circular(12);

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: effectiveRadius,
        border: Border.all(
          color: effectiveBorderColor,
          width: 1.5,
        ),
        boxShadow: shadowColor != null && depth > 0
            ? AppTheme.arcadeShadow(
                shadowColor: shadowColor!,
                depth: depth,
              )
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leading != null) ...[
            leading!,
            const SizedBox(width: 5),
          ] else if (icon != null) ...[
            Icon(icon, size: fontSize + 3, color: effectiveIconColor),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: fontWeight,
              color: effectiveTextColor,
            ),
          ),
        ],
      ),
    );
  }
}
