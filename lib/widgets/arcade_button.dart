import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Tactile 3D push button with Duolingo / Arcade mechanical compression on tap
class ArcadeButton extends StatefulWidget {
  final Widget? child;
  final String? label;
  final IconData? icon;
  final Color? textColor;
  final VoidCallback? onPressed;
  final Color color;
  final Color shadowColor;
  final Color? borderColor;
  final double borderWidth;
  final double depth;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;

  const ArcadeButton({
    super.key,
    this.child,
    this.label,
    this.icon,
    this.textColor,
    Color? backgroundColor,
    this.onPressed,
    Color? color,
    this.shadowColor = const Color(0xFFCBD5E1),
    this.borderColor,
    this.borderWidth = 2.0,
    this.depth = 4.0,
    this.borderRadius,
    this.padding,
    this.width,
    this.height,
  })  : color = backgroundColor ?? color ?? Colors.white,
        assert(child != null || label != null, 'Either child or label must be provided');

  @override
  State<ArcadeButton> createState() => _ArcadeButtonState();
}

class _ArcadeButtonState extends State<ArcadeButton> {
  bool _isPressed = false;

  void _handleTapDown(TapDownDetails _) {
    if (widget.onPressed == null) return;
    HapticFeedback.lightImpact();
    setState(() => _isPressed = true);
  }

  void _handleTapUp(TapUpDetails _) {
    if (widget.onPressed == null) return;
    setState(() => _isPressed = false);
    widget.onPressed?.call();
  }

  void _handleTapCancel() {
    if (widget.onPressed == null) return;
    setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    final effectiveBorderRadius = widget.borderRadius ?? BorderRadius.circular(16);
    final effectiveBorderColor = widget.borderColor ?? widget.shadowColor;
    final double currentOffset = _isPressed ? (widget.depth > 1 ? widget.depth - 1.0 : 0.0) : 0.0;
    final double currentShadowDepth = _isPressed ? 1.0 : widget.depth;

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      behavior: HitTestBehavior.opaque,
      child: Transform.translate(
        offset: Offset(0, currentOffset),
        child: Container(
          width: widget.width,
          height: widget.height,
          padding: widget.padding ?? const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: widget.color,
            borderRadius: effectiveBorderRadius,
            border: Border.all(
              color: effectiveBorderColor,
              width: widget.borderWidth,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.shadowColor,
                offset: Offset(0, currentShadowDepth),
                blurRadius: 0,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Center(
            widthFactor: widget.width == null ? 1.0 : null,
            heightFactor: widget.height == null ? 1.0 : null,
            child: widget.child ??
                Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.icon != null) ...[
                      Icon(
                        widget.icon,
                        size: 18,
                        color: widget.textColor ?? Colors.black87,
                      ),
                      const SizedBox(width: 6),
                    ],
                    if (widget.label != null)
                      Text(
                        widget.label!,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: widget.textColor ?? Colors.black87,
                        ),
                      ),
                  ],
                ),
          ),
        ),
      ),
    );
  }
}
