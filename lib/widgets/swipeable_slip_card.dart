import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../core/constants/categories.dart';
import '../core/theme/app_theme.dart';
import '../models/expense_card_item.dart';

class SwipeableSlipCard extends StatefulWidget {
  final ExpenseCardItem item;
  final bool isTopCard;
  final Function(CornerPosition corner) onCategorized;
  final Function(CornerPosition? corner) onProximityChanged;

  const SwipeableSlipCard({
    super.key,
    required this.item,
    required this.isTopCard,
    required this.onCategorized,
    required this.onProximityChanged,
  });

  @override
  State<SwipeableSlipCard> createState() => _SwipeableSlipCardState();
}

class _SwipeableSlipCardState extends State<SwipeableSlipCard>
    with SingleTickerProviderStateMixin {
  Offset _dragOffset = Offset.zero;
  CornerPosition? _activeCorner;

  late AnimationController _springController;
  late Animation<Offset> _springAnimation;

  @override
  void initState() {
    super.initState();
    _springController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _springController.addListener(() {
      setState(() {
        _dragOffset = _springAnimation.value;
      });
    });
  }

  @override
  void dispose() {
    _springController.dispose();
    super.dispose();
  }

  CornerPosition? _calculateHoverCorner(Offset offset) {
    const double threshold = 65.0;

    if (offset.dx < -threshold && offset.dy < -threshold) {
      return CornerPosition.topLeft;
    } else if (offset.dx > threshold && offset.dy < -threshold) {
      return CornerPosition.topRight;
    } else if (offset.dx < -threshold && offset.dy > threshold) {
      return CornerPosition.bottomLeft;
    } else if (offset.dx > threshold && offset.dy > threshold) {
      return CornerPosition.bottomRight;
    }
    return null;
  }

  void _onPanStart(DragStartDetails details) {
    if (!widget.isTopCard) return;
    _springController.stop();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!widget.isTopCard) return;

    setState(() {
      _dragOffset += details.delta;
    });

    final newCorner = _calculateHoverCorner(_dragOffset);
    if (newCorner != _activeCorner) {
      if (newCorner != null) {
        HapticFeedback.selectionClick();
      }
      _activeCorner = newCorner;
      widget.onProximityChanged(_activeCorner);
    }
  }

  void _onPanEnd(DragEndDetails details) {
    if (!widget.isTopCard) return;

    CornerPosition? targetCorner = _activeCorner;

    // Detect velocity-based flick if not already hovered in proximity
    final velocity = details.velocity.pixelsPerSecond;
    final speed = velocity.distance;

    if (targetCorner == null && speed > 550) {
      final vx = velocity.dx;
      final vy = velocity.dy;

      if (vx < 0 && vy < 0) {
        targetCorner = CornerPosition.topLeft;
      } else if (vx > 0 && vy < 0) {
        targetCorner = CornerPosition.topRight;
      } else if (vx < 0 && vy > 0) {
        targetCorner = CornerPosition.bottomLeft;
      } else if (vx > 0 && vy > 0) {
        targetCorner = CornerPosition.bottomRight;
      }
    }

    if (targetCorner != null) {
      HapticFeedback.mediumImpact();
      widget.onProximityChanged(targetCorner);

      final endOffset = Offset(
        targetCorner == CornerPosition.topLeft ||
                targetCorner == CornerPosition.bottomLeft
            ? -550.0
            : 550.0,
        targetCorner == CornerPosition.topLeft ||
                targetCorner == CornerPosition.topRight
            ? -650.0
            : 650.0,
      );

      _springAnimation = Tween<Offset>(
        begin: _dragOffset,
        end: endOffset,
      ).animate(
        CurvedAnimation(parent: _springController, curve: Curves.easeInCubic),
      );

      _springController.duration = const Duration(milliseconds: 180);
      _springController.forward(from: 0.0).then((_) {
        widget.onProximityChanged(null);
        widget.onCategorized(targetCorner!);
      });
    } else {
      widget.onProximityChanged(null);
      _springAnimation = Tween<Offset>(
        begin: _dragOffset,
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _springController,
          curve: Curves.elasticOut,
        ),
      );
      _springController.duration = const Duration(milliseconds: 400);
      _springController.forward(from: 0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat('#,##0.00', 'th_TH');
    final dateFormatter = DateFormat('dd MMM yyyy, HH:mm น.', 'th_TH');

    final double rotation = (_dragOffset.dx / 300) * 0.18;

    return widget.isTopCard
        ? GestureDetector(
            onPanStart: _onPanStart,
            onPanUpdate: _onPanUpdate,
            onPanEnd: _onPanEnd,
            child: Transform.translate(
              offset: _dragOffset,
              child: Transform.rotate(
                angle: rotation,
                child: _buildSlipContent(currencyFormatter, dateFormatter),
              ),
            ),
          )
        : _buildSlipContent(currencyFormatter, dateFormatter);
  }

  Widget _buildSlipContent(
    NumberFormat currencyFormatter,
    DateFormat dateFormatter,
  ) {
    ExpenseCategory? activeCat;
    if (_activeCorner != null) {
      activeCat = ExpenseCategory.defaultCorners.firstWhere(
        (c) => c.corner == _activeCorner,
      );
    }

    if (widget.item.imagePath != null && widget.item.imagePath!.isNotEmpty) {
      return _buildActualSlipImageCard(activeCat, currencyFormatter);
    }

    return _buildSyntheticFallbackCard(currencyFormatter, dateFormatter, activeCat);
  }

  Widget _buildActualSlipImageCard(
    ExpenseCategory? activeCat,
    NumberFormat currencyFormatter,
  ) {
    return Container(
      width: 322,
      height: 490,
      decoration: BoxDecoration(
        color: const Color(0xFF131720),
        borderRadius: BorderRadius.circular(22),
        border: activeCat != null
            ? Border.all(color: activeCat.color, width: 3.0)
            : Border.all(color: const Color(0xFF2E3846), width: 1.5),
        boxShadow: [
          if (activeCat != null) ...[
            BoxShadow(
              color: activeCat.color.withValues(alpha: 0.55),
              blurRadius: 28,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: AppColors.gold.withValues(alpha: 0.25),
              blurRadius: 14,
            ),
          ] else ...[
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 22,
              offset: const Offset(0, 12),
            ),
          ],
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // 1. The Actual Slip Image (Rendered directly)
            Positioned.fill(
              child: Container(
                color: const Color(0xFF0F1218),
                child: Center(
                  child: _buildSlipImage(widget.item.imagePath!),
                ),
              ),
            ),

            // 2. Floating Amount Pill (Top Right)
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.7),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Text(
                  '฿ ${currencyFormatter.format(widget.item.amount)}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: AppColors.gold,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),

            // 3. Floating Bank Chip (Top Left)
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: widget.item.bankColor.withValues(alpha: 0.6),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: widget.item.bankColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      widget.item.bankName,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: widget.item.bankColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 4. Real note chip if present
            if (widget.item.note != null && widget.item.note!.isNotEmpty)
              Positioned(
                bottom: 12,
                left: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.78),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.15),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.edit_note_rounded,
                        size: 14,
                        color: Color(0xFFD4AF37),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          widget.item.note!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.white70,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // 5. Active Vault Overlay Badge (When Dragging near Vault)
            if (activeCat != null)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: activeCat.color.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: activeCat.color, width: 2.5),
                  ),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: AppColors.gold, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: activeCat.color.withValues(alpha: 0.7),
                            blurRadius: 22,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(activeCat.icon, color: AppColors.gold, size: 22),
                          const SizedBox(width: 10),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'VAULT ${activeCat.romanNumeral} • ${activeCat.latinTitle}',
                                style: const TextStyle(
                                  color: AppColors.gold,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              Text(
                                activeCat.thaiTitle,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlipImage(String path) {
    final isAsset = path.startsWith('assets/');
    if (isAsset) {
      return Image.asset(
        path,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.medium,
        errorBuilder: (ctx, err, stack) => _buildImageError(),
      );
    }
    return Image.file(
      File(path),
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      errorBuilder: (ctx, err, stack) => _buildImageError(),
    );
  }

  Widget _buildImageError() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.broken_image_rounded, size: 40, color: Colors.white38),
          SizedBox(height: 8),
          Text(
            'ไม่สามารถแสดงรูปสลิปได้',
            style: TextStyle(color: Colors.white54, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildSyntheticFallbackCard(
    NumberFormat currencyFormatter,
    DateFormat dateFormatter,
    ExpenseCategory? activeCat,
  ) {
    return Container(
      width: 322,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
        // Carrara Marble background with warm parchment hue
        color: const Color(0xFFFDFBF7),
        borderRadius: BorderRadius.circular(24),
        border: activeCat != null
            ? Border.all(color: activeCat.color, width: 2.5)
            : Border.all(color: const Color(0xFFE7E1D3), width: 1.5),
        boxShadow: [
          if (activeCat != null) ...[
            BoxShadow(
              color: activeCat.color.withValues(alpha: 0.4),
              blurRadius: 28,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: AppColors.gold.withValues(alpha: 0.25),
              blurRadius: 12,
            ),
          ] else
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.45),
              blurRadius: 22,
              offset: const Offset(0, 12),
            ),
        ],
      ),
      child: Stack(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Roman Seal Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: widget.item.bankColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: widget.item.bankColor.withValues(alpha: 0.35),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: widget.item.bankColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              widget.item.bankName,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: widget.item.bankColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Wax Seal / Approved Medallion
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3.5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.waxSealRed,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.waxSealRed.withValues(alpha: 0.35),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(
                          Icons.check_circle_rounded,
                          color: Colors.white,
                          size: 13,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'สำเร็จ',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Amount Section
              Center(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Text(
                          'ยอดชำระ',
                          style: TextStyle(
                            fontSize: 11,
                            letterSpacing: 0.5,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '฿ ${currencyFormatter.format(widget.item.amount)}',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1E293B),
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),
              // Golden Meander line / divider
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 1,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            Color(0xFFD4AF37),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Receiver Info
              _buildMetaRow(
                label: 'โอนไปยัง',
                value: widget.item.receiverName,
                isHighlight: true,
              ),

              if (widget.item.note != null && widget.item.note!.isNotEmpty) ...[
                const SizedBox(height: 7),
                _buildMetaRow(
                  label: 'บันทึกช่วยจำ',
                  value: widget.item.note!,
                  isMuted: true,
                ),
              ],

              const SizedBox(height: 7),
              _buildMetaRow(
                label: 'วัน-เวลา',
                value: dateFormatter.format(widget.item.dateTime),
              ),

              const SizedBox(height: 7),
              _buildMetaRow(
                label: 'เลขที่อ้างอิง',
                value: widget.item.referenceNo,
                isSmall: true,
              ),

              if (widget.item.imagePath != null) ...[
                const SizedBox(height: 9),
                Center(
                  child: GestureDetector(
                    onTap: () => _viewOriginalSlip(context, widget.item.imagePath!),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: widget.item.bankColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: widget.item.bankColor.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.image_search_rounded,
                            size: 13,
                            color: widget.item.bankColor,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'ดูรูปสลิปต้นฉบับ',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: widget.item.bankColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 12),

              // Interaction Hint
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1ECE1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFDDD5C3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(
                      Icons.swipe_rounded,
                      size: 14,
                      color: Color(0xFF786C58),
                    ),
                    SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'ปัดสลิปไปยัง 4 มุมเพื่อจัดหมวดหมู่',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF786C58),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Active Category Overlay Badge (When Dragging near Vault)
          if (activeCat != null)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: activeCat.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.gold, width: 2),
                ),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: AppColors.gold, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: activeCat.color.withValues(alpha: 0.6),
                          blurRadius: 18,
                          offset: const Offset(0, 4),
                        ),
                        BoxShadow(
                          color: AppColors.gold.withValues(alpha: 0.3),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(activeCat.icon, color: AppColors.gold, size: 20),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'VAULT ${activeCat.romanNumeral} • ${activeCat.latinTitle}',
                                style: const TextStyle(
                                  color: AppColors.gold,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              Text(
                                activeCat.thaiTitle,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMetaRow({
    required String label,
    required String value,
    bool isHighlight = false,
    bool isMuted = false,
    bool isSmall = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 75,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF786C58),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: isSmall ? 10 : 11.5,
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.w600,
              color: isHighlight
                  ? const Color(0xFF0F172A)
                  : (isMuted
                      ? const Color(0xFF64748B)
                      : const Color(0xFF334155)),
            ),
          ),
        ),
      ],
    );
  }

  void _viewOriginalSlip(BuildContext context, String path) {
    HapticFeedback.lightImpact();
    final bool isFileOnDisk = File(path).existsSync();

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton.filled(
                  onPressed: () => Navigator.of(ctx).pop(),
                  icon: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                  style: IconButton.styleFrom(backgroundColor: Colors.black87),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Flexible(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: isFileOnDisk
                    ? Image.file(File(path), fit: BoxFit.contain)
                    : Image.asset(path, fit: BoxFit.contain),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
