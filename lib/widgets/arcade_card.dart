import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme/app_theme.dart';

/// Reusable Flat 3D Arcade / Cartoon Card Container
/// Encapsulates consistent zero-blur bevel shadow, borders, and corner styling
class ArcadeCard extends StatelessWidget {
  final Widget child;
  final Color color;
  final Color? borderColor;
  final double borderWidth;
  final Color shadowColor;
  final double depth;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final double? width;
  final double? height;

  const ArcadeCard({
    super.key,
    required this.child,
    this.color = AppColors.surface,
    this.borderColor,
    this.borderWidth = 1.8,
    this.shadowColor = AppColors.shadowDefault,
    this.depth = 3.5,
    this.borderRadius,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = borderRadius ?? BorderRadius.circular(20);
    final effectiveBorderColor = borderColor ?? shadowColor;

    final content = Container(
      width: width,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: effectiveRadius,
        border: Border.all(
          color: effectiveBorderColor,
          width: borderWidth,
        ),
        boxShadow: AppTheme.arcadeShadow(
          shadowColor: shadowColor,
          depth: depth,
        ),
      ),
      child: child,
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap?.call();
        },
        behavior: HitTestBehavior.opaque,
        child: content,
      );
    }

    return content;
  }
}
