import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

/// Blinking Cartoon Eyes (Signature Mintio Googly Eyes 👀)
class BlinkingCreatureEyes extends StatefulWidget {
  final double width;
  final double height;
  final Color eyeColor;
  final Color pupilColor;
  final Alignment pupilAlignment;
  final bool autoBlink;

  const BlinkingCreatureEyes({
    super.key,
    this.width = 54,
    this.height = 36,
    this.eyeColor = Colors.white,
    this.pupilColor = const Color(0xFF4F5FFA),
    this.pupilAlignment = const Alignment(0.4, -0.6), // Peering slightly up-right
    this.autoBlink = true,
  });

  @override
  State<BlinkingCreatureEyes> createState() => _BlinkingCreatureEyesState();
}

class _BlinkingCreatureEyesState extends State<BlinkingCreatureEyes>
    with SingleTickerProviderStateMixin {
  late AnimationController _blinkController;
  Timer? _blinkTimer;
  late Alignment _currentPupilAlignment;

  @override
  void initState() {
    super.initState();
    _currentPupilAlignment = widget.pupilAlignment;
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
    );

    if (widget.autoBlink) {
      _startRandomBlinking();
    }
  }

  void _startRandomBlinking() {
    _blinkTimer?.cancel();
    final randomSeconds = 3 + (math.Random().nextInt(4)); // 3 to 6 seconds
    _blinkTimer = Timer(Duration(seconds: randomSeconds), () async {
      if (mounted) {
        await _blinkController.forward();
        await _blinkController.reverse();
        _startRandomBlinking();
      }
    });
  }

  void _onTap() {
    // Playful reaction: wink or shift pupils
    _blinkController.forward().then((_) {
      if (mounted) {
        setState(() {
          _currentPupilAlignment = _currentPupilAlignment == widget.pupilAlignment
              ? const Alignment(-0.5, -0.6)
              : widget.pupilAlignment;
        });
        _blinkController.reverse();
      }
    });
  }

  @override
  void dispose() {
    _blinkTimer?.cancel();
    _blinkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _onTap,
      child: AnimatedBuilder(
        animation: _blinkController,
        builder: (context, child) {
          final scaleY = (1.0 - _blinkController.value).clamp(0.08, 1.0);
          final singleEyeWidth = (widget.width - 6) / 2;

          return SizedBox(
            width: widget.width,
            height: widget.height,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildSingleEye(singleEyeWidth, widget.height, scaleY),
                const SizedBox(width: 4),
                _buildSingleEye(singleEyeWidth, widget.height, scaleY),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSingleEye(double width, double height, double scaleY) {
    return Transform.scale(
      scaleY: scaleY,
      alignment: Alignment.center,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: widget.eyeColor,
          borderRadius: BorderRadius.circular(height * 0.45),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        alignment: _currentPupilAlignment,
        padding: EdgeInsets.symmetric(
          horizontal: width * 0.18,
          vertical: height * 0.15,
        ),
        child: Container(
          width: width * 0.5,
          height: height * 0.55,
          decoration: BoxDecoration(
            color: widget.pupilColor,
            borderRadius: BorderRadius.circular(width * 0.25),
          ),
        ),
      ),
    );
  }
}

enum CreatureShape {
  caterpillar,
  donut,
  creditCard,
  shuriken,
  speechBubble,
  burger,
  boxWithGlasses,
  flag,
}

/// The Living Creature Component (Mintio Mascot System)
class LivingCreatureWidget extends StatefulWidget {
  final CreatureShape shape;
  final double size;
  final String? percentage;
  final String? label;
  final Color? primaryColor;
  final VoidCallback? onTap;

  const LivingCreatureWidget({
    super.key,
    required this.shape,
    this.size = 110,
    this.percentage,
    this.label,
    this.primaryColor,
    this.onTap,
  });

  @override
  State<LivingCreatureWidget> createState() => _LivingCreatureWidgetState();
}

class _LivingCreatureWidgetState extends State<LivingCreatureWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _floatController;
  late Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(begin: -3.0, end: 3.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _floatAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _floatAnimation.value),
          child: GestureDetector(
            onTap: widget.onTap,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildBody(),
                if (widget.percentage != null) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      widget.percentage!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ],
                if (widget.label != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    widget.label!,
                    style: const TextStyle(
                      color: AppColors.mintioTextSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBody() {
    switch (widget.shape) {
      case CreatureShape.caterpillar:
        return _buildCaterpillar();
      case CreatureShape.donut:
        return _buildDonut();
      case CreatureShape.creditCard:
        return _buildCreditCard();
      case CreatureShape.shuriken:
        return _buildShuriken();
      case CreatureShape.speechBubble:
        return _buildSpeechBubble();
      case CreatureShape.burger:
        return _buildBurger();
      case CreatureShape.boxWithGlasses:
        return _buildBoxWithGlasses();
      case CreatureShape.flag:
        return _buildFlag();
    }
  }

  /// Caterpillar (Mintio Primary Mascot: Stacked pills)
  Widget _buildCaterpillar() {
    final color = widget.primaryColor ?? AppColors.mintioIndigo;
    final s = widget.size;

    return SizedBox(
      width: s,
      height: s * 0.85,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Bottom segment
          Positioned(
            bottom: 0,
            child: Container(
              width: s * 0.95,
              height: s * 0.32,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(s * 0.16),
              ),
            ),
          ),
          // Middle segment
          Positioned(
            bottom: s * 0.22,
            child: Container(
              width: s * 0.85,
              height: s * 0.32,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(s * 0.16),
              ),
            ),
          ),
          // Top segment
          Positioned(
            top: 0,
            child: Container(
              width: s * 0.72,
              height: s * 0.32,
              decoration: BoxDecoration(
                color: Color.lerp(color, Colors.white, 0.25),
                borderRadius: BorderRadius.circular(s * 0.16),
              ),
            ),
          ),
          // Eyes
          Positioned(
            top: s * 0.12,
            child: BlinkingCreatureEyes(
              width: s * 0.48,
              height: s * 0.38,
              pupilColor: color,
            ),
          ),
        ],
      ),
    );
  }

  /// Credit Card Creature (Debt category)
  Widget _buildCreditCard() {
    final color = widget.primaryColor ?? AppColors.mintioPurple;
    final s = widget.size;

    return Container(
      width: s * 1.15,
      height: s * 0.75,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Chip
          Positioned(
            bottom: 12,
            right: 12,
            child: Container(
              width: s * 0.2,
              height: s * 0.15,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          // Eyes in center
          Center(
            child: BlinkingCreatureEyes(
              width: s * 0.44,
              height: s * 0.34,
              pupilColor: color,
            ),
          ),
        ],
      ),
    );
  }

  /// Organic 4-Lobed Shuriken (Emergency / Miscellaneous)
  Widget _buildShuriken() {
    final color = widget.primaryColor ?? const Color(0xFF636E72);
    final s = widget.size;

    return SizedBox(
      width: s,
      height: s,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Cross blobs
          Transform.rotate(
            angle: 0.2,
            child: Container(
              width: s * 0.9,
              height: s * 0.45,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(s * 0.22),
              ),
            ),
          ),
          Transform.rotate(
            angle: 0.2 + (math.pi / 2),
            child: Container(
              width: s * 0.9,
              height: s * 0.45,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(s * 0.22),
              ),
            ),
          ),
          // Center core
          Container(
            width: s * 0.6,
            height: s * 0.6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          // Eyes
          BlinkingCreatureEyes(
            width: s * 0.44,
            height: s * 0.34,
            pupilColor: color,
          ),
        ],
      ),
    );
  }

  /// Speech Bubble Creature (Food / Quick chat)
  Widget _buildSpeechBubble() {
    final color = widget.primaryColor ?? AppColors.mintioCoral;
    final s = widget.size;

    return SizedBox(
      width: s * 0.9,
      height: s * 0.95,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Bubble body
          Positioned(
            top: 0,
            child: Container(
              width: s * 0.85,
              height: s * 0.72,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
          // Bubble tail
          Positioned(
            bottom: s * 0.05,
            left: s * 0.18,
            child: Transform.rotate(
              angle: 0.7,
              child: Container(
                width: s * 0.28,
                height: s * 0.28,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ),
          // Eyes
          Positioned(
            top: s * 0.18,
            child: BlinkingCreatureEyes(
              width: s * 0.44,
              height: s * 0.34,
              pupilColor: color,
            ),
          ),
        ],
      ),
    );
  }

  /// Donut Mascot (Budget / Salary)
  Widget _buildDonut() {
    final color = widget.primaryColor ?? AppColors.mintioIndigo;
    final s = widget.size;

    return SizedBox(
      width: s,
      height: s,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Donut ring
          Container(
            width: s,
            height: s,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          // Center cutout
          Container(
            width: s * 0.42,
            height: s * 0.42,
            decoration: const BoxDecoration(
              color: AppColors.mintioMidnight,
              shape: BoxShape.circle,
            ),
          ),
          // Eyes peering
          BlinkingCreatureEyes(
            width: s * 0.42,
            height: s * 0.32,
            pupilColor: color,
          ),
        ],
      ),
    );
  }

  /// Burger Mascot (Food & Beverage)
  Widget _buildBurger() {
    final color = widget.primaryColor ?? AppColors.mintioMint;
    final s = widget.size;

    return SizedBox(
      width: s * 0.95,
      height: s * 0.85,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Top bun
          Positioned(
            top: 0,
            child: Container(
              width: s * 0.9,
              height: s * 0.45,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.vertical(top: Radius.circular(s * 0.4)),
              ),
            ),
          ),
          // Bottom bun
          Positioned(
            bottom: 0,
            child: Container(
              width: s * 0.85,
              height: s * 0.3,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(s * 0.15)),
              ),
            ),
          ),
          // Patty / Eyes
          Positioned(
            top: s * 0.25,
            child: BlinkingCreatureEyes(
              width: s * 0.42,
              height: s * 0.32,
              pupilColor: color,
            ),
          ),
        ],
      ),
    );
  }

  /// Box with 3D Red/Cyan Glasses (Seen in October Summary)
  Widget _buildBoxWithGlasses() {
    final color = widget.primaryColor ?? AppColors.mintioPurple;
    final s = widget.size;

    return SizedBox(
      width: s * 0.9,
      height: s * 0.9,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: s * 0.85,
            height: s * 0.85,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(22),
            ),
          ),
          // 3D Glasses frame
          Positioned(
            top: s * 0.18,
            child: Row(
              children: [
                // Red lens frame
                Container(
                  width: s * 0.28,
                  height: s * 0.18,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: const Color(0xFFFF4757), width: 3),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                Container(width: 4, height: 3, color: Colors.white),
                // Cyan lens frame
                Container(
                  width: s * 0.28,
                  height: s * 0.18,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: const Color(0xFF00D2D3), width: 3),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ],
            ),
          ),
          // Eyes behind glasses
          Positioned(
            top: s * 0.38,
            child: BlinkingCreatureEyes(
              width: s * 0.38,
              height: s * 0.28,
              pupilColor: color,
            ),
          ),
        ],
      ),
    );
  }

  /// Flag / Mailbox Mascot (Notifications)
  Widget _buildFlag() {
    final color = widget.primaryColor ?? AppColors.mintioIndigo;
    final s = widget.size;

    return SizedBox(
      width: s * 0.85,
      height: s,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Base
          Positioned(
            bottom: 0,
            child: Container(
              width: s * 0.65,
              height: s * 0.2,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(s * 0.1),
              ),
            ),
          ),
          // Pole
          Positioned(
            bottom: s * 0.15,
            child: Container(
              width: s * 0.2,
              height: s * 0.45,
              color: color,
            ),
          ),
          // Flag head
          Positioned(
            top: 0,
            child: Container(
              width: s * 0.8,
              height: s * 0.5,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Center(
                child: BlinkingCreatureEyes(
                  width: s * 0.42,
                  height: s * 0.32,
                  pupilColor: color,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

