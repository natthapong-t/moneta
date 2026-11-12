import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../core/theme/app_theme.dart';

/// Emotional mood of Goddess Moneta
enum GoddessMood {
  idle,        // Peaceful float, gentle breath, holding gold coin
  happy,       // Blushing, eye smile, coin glint (e.g. No-spend day / under budget)
  shocked,     // Wide eyes, sweat drop (e.g. over 80% budget / big expense)
  streakFlame, // Ascended flame aura, glowing crown (e.g. 7+ day streak)
}

/// The Sacred Roman Goose (Companion of Moneta)
enum GooseAction {
  idle,    // Waddling, head bobbing
  honking, // Stretched neck, open beak, wing flap
}

/// Interactive Hero Sanctum Widget featuring Chibi Pixel Goddess Moneta + Sacred Goose
class MonetaSanctumHero extends StatefulWidget {
  final double monthlyBudget;
  final double totalSpent;
  final double todaySpent;
  final int streakDays;
  final bool isTodayNoSpend;
  final int pendingSlipsCount;
  final VoidCallback? onAddExpensePressed;

  const MonetaSanctumHero({
    super.key,
    required this.monthlyBudget,
    required this.totalSpent,
    this.todaySpent = 0,
    required this.streakDays,
    required this.isTodayNoSpend,
    this.pendingSlipsCount = 0,
    this.onAddExpensePressed,
  });

  @override
  State<MonetaSanctumHero> createState() => _MonetaSanctumHeroState();
}

class _MonetaSanctumHeroState extends State<MonetaSanctumHero>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  String _activeSpeech = '';
  bool _isCustomSpeech = false;
  int _speechTapCount = 0;
  bool _gooseHonking = false;
  bool _goddessJumping = false;

  final List<String> _idleQuotes = [
    'เหรียญทุกเหรียญที่เจ้าประหยัด คืออิสรภาพในอนาคต 🏛️',
    'ข้ากับเจ้าห่านกำลังเฝ้าคลังสมบัติให้เจ้าอยู่นะ ✨',
    'ความมั่งคั่งที่แท้จริง เริ่มต้นที่ความมีสติ 🌿',
    'วันนี้มีสลิปอะไรให้ข้ากับน้องห่านช่วยตรวจไหม? 📜',
    'จดทุกวัน สตรีคไม่ขาด เทพีโมเนตาอวยพรให้เจ้า! 🌟',
  ];

  final List<String> _gooseHonks = [
    'HONK! 🪿 เฝ้าคลังทองให้อยู่นะ!',
    'ก๊าบ! ตรวจพบความมัธยัสถ์ในตัวเจ้า!',
    'HONK! 🪿 อย่าลืมเก็บสลิปด้วยล่ะ!',
    'ก๊าบ ก๊าบ! ข้าห่านศักดิ์สิทธิ์ขอคำนับ!',
  ];

  @override
  void initState() {
    super.initState();
    // 4-frame retro idle animation cycle (350ms per frame, 1400ms loop)
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    _updateDefaultSpeech();
  }

  @override
  void didUpdateWidget(covariant MonetaSanctumHero oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isCustomSpeech) {
      _updateDefaultSpeech();
    }
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  GoddessMood get currentMood {
    if (widget.streakDays >= 7) return GoddessMood.streakFlame;
    if (widget.monthlyBudget > 0 &&
        widget.totalSpent > widget.monthlyBudget * 0.8) {
      return GoddessMood.shocked;
    }
    if (widget.isTodayNoSpend) return GoddessMood.happy;
    return GoddessMood.idle;
  }

  void _updateDefaultSpeech() {
    if (widget.streakDays >= 7) {
      _activeSpeech = '🔥 ไฟลุกแล้วเจ้ามนุษย์! พลังแห่งความมัธยัสถ์แผ่ซ่าน!';
    } else if (widget.isTodayNoSpend) {
      _activeSpeech = '✨ วันนี้วิหารสงบสุข ไม่มีเงินไหลออกเลยสักสตางค์!';
    } else if (widget.monthlyBudget > 0 &&
        widget.totalSpent > widget.monthlyBudget * 0.8) {
      _activeSpeech = '😱 ใจเย็นก่อนเจ้ามนุษย์! ใกล้แตะเพดานงบเดือนแล้วนะ!';
    } else if (widget.pendingSlipsCount > 0) {
      _activeSpeech = '📜 มีสลิป ${widget.pendingSlipsCount} ใบรอเจ้ามาปัดแยกหมวดอยู่นะ';
    } else {
      _activeSpeech = _idleQuotes[0];
    }
  }

  void _onTapGoddess() {
    HapticFeedback.lightImpact();
    setState(() {
      _goddessJumping = true;
      _isCustomSpeech = true;
      _speechTapCount++;
      _activeSpeech = _idleQuotes[_speechTapCount % _idleQuotes.length];
    });

    Future.delayed(const Duration(milliseconds: 320), () {
      if (mounted) setState(() => _goddessJumping = false);
    });
  }

  void _onTapGoose() {
    HapticFeedback.mediumImpact();
    setState(() {
      _isCustomSpeech = true;
      _gooseHonking = true;
      _activeSpeech = _gooseHonks[_speechTapCount % _gooseHonks.length];
      _speechTapCount++;
    });

    Future.delayed(const Duration(milliseconds: 1600), () {
      if (mounted) {
        setState(() => _gooseHonking = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final mood = currentMood;
    final shortFormatter = NumberFormat('#,##0', 'th_TH');
    final hasBudget = widget.monthlyBudget > 0;
    final remainingBudget = hasBudget ? (widget.monthlyBudget - widget.totalSpent) : 0.0;

    final String subtitle = hasBudget ? 'งบที่เหลือ' : 'วันนี้ใช้ไป';
    final double mainAmount = hasBudget
        ? (remainingBudget > 0 ? remainingBudget : 0.0)
        : (widget.todaySpent > 0 ? widget.todaySpent : widget.totalSpent);

    final String miniHint = hasBudget
        ? (widget.streakDays > 0
            ? 'สตรีค ${widget.streakDays} วัน'
            : 'วันนี้ใช้ไป ฿${shortFormatter.format(widget.todaySpent)}')
        : (widget.streakDays > 0
            ? 'สตรีค ${widget.streakDays} วัน'
            : 'เดือนนี้ใช้ไป ฿${shortFormatter.format(widget.totalSpent)}');

    const double outerRadius = 24.0;
    final double innerRadius = AppTheme.innerRadius(outerRadius, 16);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF13141E),
        borderRadius: BorderRadius.circular(outerRadius),
        border: Border.all(
          color: mood == GoddessMood.streakFlame
              ? AppColors.mintioIndigo.withValues(alpha: 0.5)
              : AppColors.border,
          width: mood == GoddessMood.streakFlame ? 1.6 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: mood == GoddessMood.streakFlame
                ? AppColors.mintioIndigo.withValues(alpha: 0.15)
                : Colors.black.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Row: Financial Heart (Left) + Mascot Vignette (Right)
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left: Big, bold, confident number
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        if (widget.streakDays > 0) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF5722).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(innerRadius),
                              border: Border.all(
                                color: const Color(0xFFFF5722).withValues(alpha: 0.45),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('🔥', style: TextStyle(fontSize: 10)),
                                const SizedBox(width: 3),
                                Text(
                                  '${widget.streakDays} วัน',
                                  style: const TextStyle(
                                    color: Color(0xFFFF9F1A),
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '฿${shortFormatter.format(mainAmount)}',
                        style: AppTheme.tabularFigures(
                          base: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      miniHint,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Right: Little Goddess Moneta + The Sacred Goose vignette
              // (~80-90px high, crisp pixel art side-by-side, sleek minimal pedestal with no fake decorative lines)
              SizedBox(
                height: 94,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // The Sacred Goose (16-bit retro frame idle)
                        GestureDetector(
                          onTap: _onTapGoose,
                          child: AnimatedBuilder(
                            animation: _animCtrl,
                            builder: (context, _) {
                              final frame =
                                  (_animCtrl.value * 4).floor() % 4;
                              return SacredGoosePixelWidget(
                                size: 40,
                                action: _gooseHonking
                                    ? GooseAction.honking
                                    : GooseAction.idle,
                                frameIndex: frame,
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 4),
                        // Goddess Moneta (16-bit retro frame idle)
                        GestureDetector(
                          onTap: _onTapGoddess,
                          child: AnimatedBuilder(
                            animation: _animCtrl,
                            builder: (context, _) {
                              final frame =
                                  (_animCtrl.value * 4).floor() % 4;
                              return Transform.translate(
                                offset: Offset(0, _goddessJumping ? -3 : 0),
                                child: MonetaGoddessPixelWidget(
                                  size: 62,
                                  mood: mood,
                                  frameIndex: frame,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    // Sleek minimal pedestal (no fake decorative lines)
                    Container(
                      width: 104,
                      height: 5,
                      decoration: BoxDecoration(
                        color: const Color(0xFF242636),
                        borderRadius: BorderRadius.circular(2.5),
                        border: Border.all(
                          color: const Color(0xFF34384D),
                          width: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Speech Bubble (Rule 13: Remove crown emoji, Rule 14: inner radius)
          GestureDetector(
            onTap: _onTapGoddess,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(innerRadius),
                border: Border.all(
                  color: _gooseHonking
                      ? const Color(0xFFFF9F1A)
                      : AppColors.mintioIndigo.withValues(alpha: 0.25),
                  width: 1.0,
                ),
              ),
              child: Text(
                _activeSpeech,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Standalone Pixel Art Widget of Goddess Moneta
class MonetaGoddessPixelWidget extends StatefulWidget {
  final double size;
  final GoddessMood mood;
  final int? frameIndex;

  const MonetaGoddessPixelWidget({
    super.key,
    this.size = 100,
    this.mood = GoddessMood.idle,
    this.frameIndex,
  });

  @override
  State<MonetaGoddessPixelWidget> createState() =>
      _MonetaGoddessPixelWidgetState();
}

class _MonetaGoddessPixelWidgetState extends State<MonetaGoddessPixelWidget>
    with TickerProviderStateMixin {
  late AnimationController _idleAnimController;
  late AnimationController _blinkController;
  bool _isBlinking = false;

  @override
  void initState() {
    super.initState();
    _idleAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    if (widget.frameIndex == null) {
      _idleAnimController.repeat();
    }

    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          setState(() => _isBlinking = true);
          Future.delayed(const Duration(milliseconds: 140), () {
            if (mounted) {
              setState(() => _isBlinking = false);
              _blinkController.forward(from: 0);
            }
          });
        }
      });
    _blinkController.forward();
  }

  @override
  void didUpdateWidget(covariant MonetaGoddessPixelWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.frameIndex == null && !_idleAnimController.isAnimating) {
      _idleAnimController.repeat();
    } else if (widget.frameIndex != null && _idleAnimController.isAnimating) {
      _idleAnimController.stop();
    }
  }

  @override
  void dispose() {
    _idleAnimController.dispose();
    _blinkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.frameIndex != null) {
      return SizedBox(
        width: widget.size,
        height: widget.size * (27 / 20),
        child: CustomPaint(
          painter: GoddessPixelPainter(
            mood: widget.mood,
            isBlinking: _isBlinking,
            frameIndex: widget.frameIndex!,
          ),
        ),
      );
    }

    return AnimatedBuilder(
      animation: _idleAnimController,
      builder: (context, _) {
        final frame = (_idleAnimController.value * 4).floor() % 4;
        return SizedBox(
          width: widget.size,
          height: widget.size * (27 / 20),
          child: CustomPaint(
            painter: GoddessPixelPainter(
              mood: widget.mood,
              isBlinking: _isBlinking,
              frameIndex: frame,
            ),
          ),
        );
      },
    );
  }
}

/// Standalone Pixel Art Widget of The Sacred Roman Goose
class SacredGoosePixelWidget extends StatefulWidget {
  final double size;
  final GooseAction action;
  final int? frameIndex;

  const SacredGoosePixelWidget({
    super.key,
    this.size = 60,
    this.action = GooseAction.idle,
    this.frameIndex,
  });

  @override
  State<SacredGoosePixelWidget> createState() => _SacredGoosePixelWidgetState();
}

class _SacredGoosePixelWidgetState extends State<SacredGoosePixelWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _idleAnimController;

  @override
  void initState() {
    super.initState();
    _idleAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    if (widget.frameIndex == null) {
      _idleAnimController.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant SacredGoosePixelWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.frameIndex == null && !_idleAnimController.isAnimating) {
      _idleAnimController.repeat();
    } else if (widget.frameIndex != null && _idleAnimController.isAnimating) {
      _idleAnimController.stop();
    }
  }

  @override
  void dispose() {
    _idleAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.frameIndex != null) {
      return SizedBox(
        width: widget.size,
        height: widget.size,
        child: CustomPaint(
          painter: GoosePixelPainter(
            action: widget.action,
            frameIndex: widget.frameIndex!,
          ),
        ),
      );
    }

    return AnimatedBuilder(
      animation: _idleAnimController,
      builder: (context, _) {
        final frame = (_idleAnimController.value * 4).floor() % 4;
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: CustomPaint(
            painter: GoosePixelPainter(
              action: widget.action,
              frameIndex: frame,
            ),
          ),
        );
      },
    );
  }
}

// ============================================================================
// PIXEL MATRICES & PAINTERS
// ============================================================================

/// 20 x 26 Matrix for Chibi Roman Goddess Moneta
///
/// 0: Transparent
/// 1: Gold Wreath Light (#FFD32A)
/// 2: Gold Wreath Dark (#E58E26)
/// 3: Chestnut Hair Main (#5D4037)
/// 4: Chestnut Hair Shadow (#3E2723)
/// 5: Chestnut Hair Highlight (#8D6E63)
/// 6: Skin Tone (#FFE0BD)
/// 7: Blush Pink (#FFB8B8)
/// 8: Eye Midnight (#1E272E)
/// 9: Eye Sparkle (#FFFFFF)
/// 10: Toga White (#F5F6FA)
/// 11: Toga Shadow (#D2DAE2)
/// 12: Toga Indigo Trim (#4F5FFA)
/// 13: Gold Fibula/Clasp (#FFD32A)
/// 14: Roman Gold Coin (#FFD32A)
/// 15: Roman Coin Shadow (#E58E26)
/// 16: Sweat Drop Cyan (#00D2D3)
class GoddessPixelPainter extends CustomPainter {
  final GoddessMood mood;
  final bool isBlinking;
  final int frameIndex; // 0, 1, 2, 3

  const GoddessPixelPainter({
    required this.mood,
    required this.isBlinking,
    this.frameIndex = 0,
  });

  static const List<List<int>> baseGrid = [
    // Row 0-3: Golden Laurel Wreath & Top Hair
    [0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0],
    [0, 0, 0, 1, 1, 2, 3, 3, 3, 3, 3, 3, 3, 3, 2, 1, 1, 0, 0, 0],
    [0, 0, 1, 2, 3, 3, 5, 5, 3, 3, 3, 3, 5, 5, 3, 3, 2, 1, 0, 0],
    [0, 1, 2, 3, 3, 5, 5, 3, 3, 3, 3, 3, 3, 5, 5, 3, 3, 2, 1, 0],
    // Row 4-7: Forehead, Hair Curls, Bangs
    [0, 1, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 1, 0],
    [0, 0, 3, 3, 3, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 3, 3, 3, 0, 0],
    [0, 0, 3, 3, 6, 6, 3, 6, 6, 6, 6, 6, 6, 3, 6, 6, 3, 3, 0, 0],
    [0, 0, 3, 3, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 3, 3, 0, 0],
    // Row 8-11: Eyes & Face (Dynamic eyes rendered in paint)
    [0, 0, 3, 6, 6, 8, 8, 6, 6, 6, 6, 6, 8, 8, 6, 6, 6, 3, 0, 0],
    [0, 0, 3, 6, 6, 8, 9, 6, 6, 6, 6, 6, 8, 9, 6, 6, 6, 3, 0, 0],
    [0, 0, 3, 6, 7, 8, 8, 7, 6, 6, 6, 7, 8, 8, 7, 6, 6, 3, 0, 0],
    [0, 0, 3, 4, 6, 6, 6, 6, 6, 8, 6, 6, 6, 6, 6, 6, 4, 3, 0, 0],
    // Row 12-14: Chin, Neck & Gold Fibula Brooch
    [0, 0, 0, 3, 4, 6, 6, 6, 6, 6, 6, 6, 6, 6, 4, 3, 0, 0, 0, 0],
    [0, 0, 0, 0, 3, 3, 6, 6, 6, 6, 6, 6, 3, 3, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 12, 12, 13, 13, 10, 10, 10, 10, 10, 12, 12, 0, 0, 0, 0, 0, 0],
    // Row 15-18: Roman Toga with Indigo Border & Holding Golden Coin
    [0, 0, 12, 10, 10, 13, 13, 10, 10, 10, 10, 11, 10, 10, 12, 0, 0, 0, 0, 0],
    [0, 12, 10, 10, 10, 10, 10, 10, 10, 10, 11, 11, 10, 10, 10, 12, 0, 14, 14, 0],
    [0, 12, 10, 10, 11, 10, 10, 10, 10, 11, 11, 10, 10, 10, 6, 6, 14, 14, 15, 14],
    [0, 12, 10, 11, 11, 10, 10, 10, 11, 11, 10, 10, 10, 6, 6, 14, 14, 15, 15, 14],
    // Row 19-22: Toga Drapes & Bottom Trim
    [0, 12, 10, 11, 10, 10, 10, 11, 11, 10, 10, 10, 10, 10, 10, 12, 0, 14, 14, 0],
    [0, 0, 12, 10, 10, 10, 11, 11, 10, 10, 10, 10, 10, 10, 12, 0, 0, 0, 0, 0],
    [0, 0, 12, 10, 10, 11, 11, 10, 10, 10, 11, 10, 10, 10, 12, 0, 0, 0, 0, 0],
    [0, 0, 0, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 0, 0, 0, 0, 0, 0],
    // Row 23-25: Feet with Roman Sandals
    [0, 0, 0, 0, 0, 6, 6, 0, 0, 0, 0, 6, 6, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 2, 2, 0, 0, 0, 0, 2, 2, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 2, 2, 2, 0, 0, 0, 2, 2, 2, 0, 0, 0, 0, 0, 0, 0],
  ];

  static final Map<int, Color> palette = {
    1: const Color(0xFFFFD32A), // Gold Wreath
    2: const Color(0xFFE58E26), // Gold Shadow
    3: const Color(0xFF5D4037), // Chestnut Hair
    4: const Color(0xFF3E2723), // Hair Dark
    5: const Color(0xFF8D6E63), // Hair Highlight
    6: const Color(0xFFFFE0BD), // Skin
    7: const Color(0xFFFFB8B8), // Blush
    8: const Color(0xFF1E272E), // Eye / Mouth Dark
    9: const Color(0xFFFFFFFF), // Eye Sparkle
    10: const Color(0xFFF5F6FA), // Toga White
    11: const Color(0xFFD2DAE2), // Toga Shadow
    12: const Color(0xFF4F5FFA), // Electric Indigo Trim
    13: const Color(0xFFFFD32A), // Gold Clasp
    14: const Color(0xFFFFD32A), // Roman Gold Coin
    15: const Color(0xFFE58E26), // Coin Shade
    16: const Color(0xFF00D2D3), // Sweat Drop Cyan
  };

  @override
  void paint(Canvas canvas, Size size) {
    const rows = 27;
    const cols = 20;

    final pixelSize = min(size.width / cols, size.height / rows);
    final offsetX = (size.width - cols * pixelSize) / 2;
    final offsetY = (size.height - rows * pixelSize) / 2;

    final paint = Paint()..isAntiAlias = false;

    // 4-frame retro RPG idle:
    // Frame 0: Neutral rest
    // Frame 1: Inhale (head & chest rise 1px, hair curls sway out, coin lifts)
    // Frame 2: Peak breath (coin spins/glints with sparkle, wreath glints, toga hem sways)
    // Frame 3: Exhale settle (head returns, hair tips & toga folds follow through)
    final int headShift = (frameIndex == 1 || frameIndex == 2) ? 0 : 1;

    void drawPixel(int c, int targetY, Color col) {
      if (c >= 0 && c < cols && targetY >= 0 && targetY < rows) {
        paint.color = col;
        canvas.drawRect(
          Rect.fromLTWH(
            offsetX + c * pixelSize,
            offsetY + targetY * pixelSize,
            pixelSize,
            pixelSize,
          ),
          paint,
        );
      }
    }

    for (int r = 0; r < 26; r++) {
      // Feet & lower robes (rows 16..25) stay grounded; head/shoulders (0..14) breathe
      int targetY = r <= 14 ? (r + headShift) : (r + 1);

      for (int c = 0; c < cols; c++) {
        // Skip default coin pixels on frames 1 & 2 so we can animate the coin flip/bob cleanly
        final bool isCoinArea = (r >= 16 && r <= 19 && c >= 14);
        if (isCoinArea && (frameIndex == 1 || frameIndex == 2)) {
          continue;
        }

        int colorIdx = baseGrid[r][c];

        // Dynamic Eye Expressions based on mood and blink
        if (isBlinking && (r == 8 || r == 9) && (c == 5 || c == 6 || c == 12 || c == 13)) {
          // Closed eye line
          colorIdx = (r == 9) ? 8 : 6;
        } else if (mood == GoddessMood.happy) {
          // Happy curved eyes ^ ^
          if (r == 8 && (c == 5 || c == 7 || c == 12 || c == 14)) colorIdx = 8;
          if (r == 7 && (c == 6 || c == 13)) colorIdx = 8;
          if (r == 9 && (c == 5 || c == 6 || c == 7 || c == 12 || c == 13 || c == 14)) {
            colorIdx = 6;
          }
        } else if (mood == GoddessMood.shocked) {
          // Wide round shocked eyes + sweat drop
          if ((r == 8 || r == 9) && (c == 5 || c == 6 || c == 12 || c == 13)) {
            colorIdx = 9; // Wide white eye
          }
          if (r == 9 && (c == 6 || c == 13)) colorIdx = 8; // Small black pupil
          // Sweat drop on forehead
          if ((r == 5 || r == 6) && c == 15) colorIdx = 16;
          if (r == 7 && c == 15) colorIdx = 16;
        }

        // Frame 2: Laurel wreath golden catchlight glint
        if (frameIndex == 2 && r == 1 && (c == 4 || c == 15)) {
          colorIdx = 9;
        }

        // Frame 3: Fibula brooch glint
        if (frameIndex == 3 && r == 14 && c == 5) {
          colorIdx = 9;
        }

        if (colorIdx != 0 && palette.containsKey(colorIdx)) {
          drawPixel(c, targetY, palette[colorIdx]!);
          // Stretch neck/shoulder connection seamlessly when breathing up
          if (r == 14 && headShift == 0) {
            drawPixel(c, targetY + 1, palette[colorIdx]!);
          }
        }
      }
    }

    // Frame-specific hair curls, toga breeze, and animated hand/coin
    if (frameIndex == 1) {
      // Hair side locks sway outward in the breeze
      drawPixel(1, 6, palette[3]!);
      drawPixel(1, 7, palette[3]!);
      drawPixel(18, 6, palette[3]!);
      drawPixel(18, 7, palette[3]!);

      // Hand & Coin lifted 1px higher
      drawPixel(14, 17, palette[6]!);
      drawPixel(15, 17, palette[6]!);
      drawPixel(14, 18, palette[6]!);
      drawPixel(15, 18, palette[6]!);
      // Lifted Gold Coin (full face)
      drawPixel(17, 15, palette[14]!);
      drawPixel(18, 15, palette[14]!);
      drawPixel(16, 16, palette[14]!);
      drawPixel(17, 16, palette[9]!); // Shine
      drawPixel(18, 16, palette[15]!);
      drawPixel(19, 16, palette[14]!);
      drawPixel(16, 17, palette[14]!);
      drawPixel(17, 17, palette[15]!);
      drawPixel(18, 17, palette[15]!);
      drawPixel(19, 17, palette[14]!);
      drawPixel(17, 18, palette[14]!);
      drawPixel(18, 18, palette[14]!);
    } else if (frameIndex == 2) {
      // Hair side locks + lower hair tips sway
      drawPixel(1, 7, palette[3]!);
      drawPixel(1, 8, palette[4]!);
      drawPixel(18, 7, palette[3]!);
      drawPixel(18, 8, palette[4]!);

      // Toga hem ripples 1px to the right in the breeze
      drawPixel(15, 21, palette[12]!);
      drawPixel(15, 22, palette[12]!);

      // Hand holding spinning coin (edge-on 2px spin with sparkle above!)
      drawPixel(14, 17, palette[6]!);
      drawPixel(15, 17, palette[6]!);
      drawPixel(14, 18, palette[6]!);
      drawPixel(15, 18, palette[6]!);
      // Spinning narrow coin
      drawPixel(17, 15, palette[9]!); // Bright top glint
      drawPixel(18, 15, palette[14]!);
      drawPixel(17, 16, palette[14]!);
      drawPixel(18, 16, palette[15]!);
      drawPixel(17, 17, palette[14]!);
      drawPixel(18, 17, palette[15]!);
      drawPixel(17, 18, palette[15]!);
      drawPixel(18, 18, palette[14]!);
      // Floating sparkle star above coin
      drawPixel(18, 13, palette[9]!);
    } else if (frameIndex == 3) {
      // Secondary follow-through on lower hair locks & toga drape
      drawPixel(2, 12, palette[4]!);
      drawPixel(17, 12, palette[4]!);
      drawPixel(15, 22, palette[12]!);
    }

    // Flame aura particles for streak flame mood
    if (mood == GoddessMood.streakFlame) {
      final auraPaint = Paint()
        ..color = const Color(0xFFFF5722).withValues(alpha: 0.75)
        ..isAntiAlias = false;

      // 4 distinct retro flame ember animation frames
      final flameFrames = [
        [const Offset(1, 4), const Offset(18, 5), const Offset(0, 12), const Offset(19, 14)],
        [const Offset(1, 2), const Offset(18, 3), const Offset(0, 10), const Offset(19, 12), const Offset(17, 16)],
        [const Offset(2, 1), const Offset(17, 2), const Offset(1, 8), const Offset(18, 10), const Offset(16, 15)],
        [const Offset(1, 3), const Offset(18, 4), const Offset(0, 11), const Offset(19, 13)],
      ];

      final currentFlames = flameFrames[frameIndex % flameFrames.length];
      for (final p in currentFlames) {
        canvas.drawRect(
          Rect.fromLTWH(
            offsetX + p.dx * pixelSize,
            offsetY + p.dy * pixelSize,
            pixelSize * 1.2,
            pixelSize * 1.2,
          ),
          auraPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant GoddessPixelPainter oldDelegate) {
    return oldDelegate.mood != mood ||
        oldDelegate.isBlinking != isBlinking ||
        oldDelegate.frameIndex != frameIndex;
  }
}

/// 24 x 24 Matrix for The Sacred Roman Goose
class GoosePixelPainter extends CustomPainter {
  final GooseAction action;
  final int frameIndex; // 0, 1, 2, 3

  const GoosePixelPainter({
    required this.action,
    this.frameIndex = 0,
  });

  static const List<List<int>> idleGrid = [
    // Row 0: Laurel Crown leaves top
    [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 10, 10, 0, 10, 10, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    // Row 1: Laurel Crown leaves connected
    [0, 0, 0, 0, 0, 0, 0, 0, 10, 11, 10, 10, 10, 11, 10, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    // Row 2: Top of head outline
    [0, 0, 0, 0, 0, 0, 0, 19, 19, 19, 19, 19, 19, 19, 19, 19, 0, 0, 0, 0, 0, 0, 0, 0],
    // Row 3: Crown feathers
    [0, 0, 0, 0, 0, 0, 19, 1, 1, 2, 1, 1, 1, 1, 1, 1, 19, 0, 0, 0, 0, 0, 0, 0],
    // Row 4: Forehead
    [0, 0, 0, 0, 0, 19, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 19, 0, 0, 0, 0, 0, 0],
    // Row 5: Upper Beak & Big Sparkly Eye (2x2 eye with white catchlight)
    [0, 0, 0, 19, 19, 19, 1, 1, 5, 6, 1, 1, 1, 1, 1, 1, 1, 19, 0, 0, 0, 0, 0, 0],
    // Row 6: Gold Coin Sparkle & Beak gripping coin
    [0, 19, 19, 15, 6, 8, 19, 1, 5, 5, 1, 1, 1, 1, 1, 1, 3, 19, 0, 0, 0, 0, 0, 0],
    // Row 7: Gold Coin Body & Lower Beak + Blush
    [19, 15, 15, 15, 16, 8, 19, 7, 7, 1, 1, 1, 1, 1, 1, 3, 3, 19, 0, 0, 0, 0, 0, 0],
    // Row 8: Coin Bottom & Under-Beak
    [0, 19, 16, 16, 19, 19, 1, 1, 1, 1, 1, 1, 1, 1, 3, 3, 19, 0, 0, 0, 0, 0, 0, 0],
    // Row 9: Neck & Jaw
    [0, 0, 19, 19, 0, 19, 1, 1, 1, 1, 1, 1, 1, 3, 3, 19, 0, 0, 0, 0, 0, 0, 0, 0],
    // Row 10: Neck & Gold Clasp of Cape
    [0, 0, 0, 0, 0, 19, 1, 1, 1, 1, 1, 14, 12, 12, 19, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    // Row 11: Chest & Flowing Red Roman Cape
    [0, 0, 0, 0, 19, 1, 1, 1, 1, 1, 12, 12, 12, 13, 19, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    // Row 12: Chubby Chest & Cape Flutter
    [0, 0, 0, 19, 1, 1, 1, 1, 1, 12, 12, 12, 13, 13, 13, 19, 0, 0, 0, 0, 0, 0, 0, 0],
    // Row 13: Belly curve & Cape Edge
    [0, 0, 19, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 13, 13, 13, 19, 0, 0, 0, 0, 0, 0, 0],
    // Row 14: Chubby Round Body & Wing highlight
    [0, 19, 1, 1, 1, 1, 1, 1, 1, 1, 2, 1, 1, 1, 1, 1, 19, 0, 0, 0, 0, 0, 0, 0],
    // Row 15: Fluffy Wing & Tail Feather start
    [0, 19, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 19, 0, 0, 0, 0, 0, 0],
    // Row 16: Tail Feathers perky upward
    [0, 19, 1, 1, 1, 1, 1, 1, 1, 1, 1, 3, 3, 1, 1, 1, 1, 1, 19, 19, 0, 0, 0, 0],
    // Row 17: Underbelly curve & Tail tip
    [0, 0, 19, 1, 1, 1, 1, 1, 3, 3, 3, 3, 3, 3, 1, 1, 1, 1, 1, 1, 19, 0, 0, 0],
    // Row 18: Underbelly soft shadow
    [0, 0, 0, 19, 19, 3, 3, 3, 3, 4, 4, 3, 3, 3, 3, 3, 1, 1, 19, 19, 0, 0, 0, 0],
    // Row 19: Body bottom outline
    [0, 0, 0, 0, 0, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 0, 0, 0, 0, 0, 0],
    // Row 20: Legs
    [0, 0, 0, 0, 0, 0, 0, 19, 17, 19, 0, 0, 19, 17, 19, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    // Row 21: Cute Webbed Feet
    [0, 0, 0, 0, 0, 0, 19, 17, 17, 17, 19, 19, 17, 17, 17, 19, 0, 0, 0, 0, 0, 0, 0, 0],
    // Row 22: Feet Shadow
    [0, 0, 0, 0, 0, 0, 19, 18, 18, 18, 19, 19, 18, 18, 18, 19, 0, 0, 0, 0, 0, 0, 0, 0],
    // Row 23: Feet bottom outline
    [0, 0, 0, 0, 0, 0, 0, 19, 19, 19, 0, 0, 19, 19, 19, 0, 0, 0, 0, 0, 0, 0, 0, 0],
  ];

  static final Map<int, Color> palette = {
    1: const Color(0xFFFFFFFF), // White Feathers Main
    2: const Color(0xFFF5F7FC), // Feather Highlight
    3: const Color(0xFFCFD6E4), // Feather Slate Shadow
    4: const Color(0xFF9EAEC4), // Feather Dark Shadow
    5: const Color(0xFF141722), // Midnight Eye
    6: const Color(0xFFFFFFFF), // Eye Sparkle Catchlight
    7: const Color(0xFFFF8DA1), // Kawaii Blush Pink
    8: const Color(0xFFFF9F1A), // Orange Beak
    9: const Color(0xFFE67E22), // Beak Shade
    10: const Color(0xFFFFD32A), // Laurel Wreath Gold
    11: const Color(0xFFFFA801), // Laurel Wreath Gold Dark
    12: const Color(0xFFFF4757), // Scarlet Roman Cape
    13: const Color(0xFFC0392B), // Cape Deep Shadow
    14: const Color(0xFFFFD32A), // Gold Cape Clasp
    15: const Color(0xFFFFD32A), // Roman Gold Coin
    16: const Color(0xFFE58E26), // Coin Shadow
    17: const Color(0xFFFF9F1A), // Orange Webbed Feet
    18: const Color(0xFFE67E22), // Feet Shadow
    19: const Color(0xFF1C1E2A), // Sprite Outline
  };

  @override
  void paint(Canvas canvas, Size size) {
    const rows = 25;
    const cols = 24;

    final pixelSize = min(size.width / cols, size.height / rows);
    final offsetX = (size.width - cols * pixelSize) / 2;
    final offsetY = (size.height - rows * pixelSize) / 2;

    final paint = Paint()..isAntiAlias = false;

    void drawPixel(int c, int targetY, Color col) {
      if (c >= 0 && c < cols && targetY >= 0 && targetY < rows) {
        paint.color = col;
        canvas.drawRect(
          Rect.fromLTWH(
            offsetX + c * pixelSize,
            offsetY + targetY * pixelSize,
            pixelSize,
            pixelSize,
          ),
          paint,
        );
      }
    }

    final bool isHonking = (action == GooseAction.honking);
    // 4-frame retro RPG idle:
    // Frame 0: Standing proud at rest
    // Frame 1: Chest puffs out, head bobs up 1px, tail wags up, cape flutters
    // Frame 2: Coin gleams with cross sparkle, wing tucks 1px, cape billows
    // Frame 3: Settles back down with cape trailing fold
    final int headShift = isHonking
        ? ((frameIndex % 2 == 0) ? 0 : 1)
        : ((frameIndex == 1 || frameIndex == 2) ? 0 : 1);

    for (int r = 0; r < 24; r++) {
      // Feet & lower body (rows 13..23) stay grounded; head/neck (0..12) bob
      final int targetY = r <= 12 ? (r + headShift) : (r + 1);

      for (int c = 0; c < 24; c++) {
        int colorIdx = idleGrid[r][c];

        // Frame 2 coin glint catchlight
        if (frameIndex == 2 && r == 6 && c == 3) {
          colorIdx = 6; // Catchlight white
        } else if (frameIndex == 2 && r == 7 && c == 2) {
          colorIdx = 6; // Secondary coin shine
        }

        // Frame 2 wing feather tuck highlight shift
        if (frameIndex == 2 && r == 15 && (c == 11 || c == 12)) {
          colorIdx = 3; // Subtle wing fold shadow
        }

        if (colorIdx != 0 && palette.containsKey(colorIdx)) {
          drawPixel(c, targetY, palette[colorIdx]!);

          // Neck stretch connection when head bobs up
          if (r == 12 && headShift == 0) {
            drawPixel(c, targetY + 1, palette[colorIdx]!);
          }
        }
      }
    }

    // Frame-specific retro sprite details
    if (!isHonking) {
      if (frameIndex == 1) {
        // Plump belly puff forward + tail feather wag up + cape flutter
        drawPixel(1, 14, palette[19]!);
        drawPixel(2, 14, palette[1]!);
        drawPixel(19, 15, palette[19]!);
        drawPixel(18, 16, palette[1]!);
        drawPixel(15, 11, palette[12]!);
        drawPixel(16, 12, palette[12]!);
        drawPixel(16, 13, palette[19]!);
      } else if (frameIndex == 2) {
        // Cape billows out further + coin sparkle star + perky tail
        drawPixel(15, 11, palette[12]!);
        drawPixel(16, 11, palette[12]!);
        drawPixel(16, 12, palette[13]!);
        drawPixel(17, 12, palette[19]!);
        drawPixel(19, 15, palette[19]!);
        drawPixel(18, 16, palette[1]!);
        // Little sparkle above the gold coin
        drawPixel(1, 5, palette[6]!);
      } else if (frameIndex == 3) {
        // Cape trailing fold as it settles
        drawPixel(15, 13, palette[13]!);
        drawPixel(16, 14, palette[19]!);
      }
    } else {
      // Energetic HONK action: flapping wings, flaring cape, and sound wave!
      final orange = palette[8]!;
      final gold = palette[10]!;
      // Sound wave / exclamation above head
      drawPixel(4, 1, orange);
      drawPixel(4, 2, orange);
      drawPixel(2, 3, gold);
      drawPixel(3, 3, gold);
      // Flapping wing feathers & flaring cape
      drawPixel(16, 11, palette[12]!);
      drawPixel(17, 11, palette[12]!);
      drawPixel(19, 15, palette[1]!);
      drawPixel(20, 15, palette[19]!);
    }
  }

  @override
  bool shouldRepaint(covariant GoosePixelPainter oldDelegate) {
    return oldDelegate.action != action ||
        oldDelegate.frameIndex != frameIndex;
  }
}

