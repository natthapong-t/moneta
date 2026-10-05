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

    final targetCorner = _activeCorner;

    if (targetCorner != null) {
      HapticFeedback.mediumImpact();

      final endOffset = Offset(
        targetCorner == CornerPosition.topLeft ||
                targetCorner == CornerPosition.bottomLeft
            ? -500.0
            : 500.0,
        targetCorner == CornerPosition.topLeft ||
                targetCorner == CornerPosition.topRight
            ? -600.0
            : 600.0,
      );

      _springAnimation = Tween<Offset>(
        begin: _dragOffset,
        end: endOffset,
      ).animate(
        CurvedAnimation(parent: _springController, curve: Curves.easeInCubic),
      );

      _springController.duration = const Duration(milliseconds: 200);
      _springController.forward(from: 0.0).then((_) {
        widget.onProximityChanged(null);
        widget.onCategorized(targetCorner);
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
                          Icons.verified_rounded,
                          color: Colors.white,
                          size: 13,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'MINTED • สำเร็จ',
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
                        Icon(Icons.shield_outlined, size: 12, color: Color(0xFF94A3B8)),
                        SizedBox(width: 4),
                        Text(
                          'DENARII • ยอดชำระ',
                          style: TextStyle(
                            fontSize: 11,
                            letterSpacing: 1.0,
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
                  label: 'บันทึกสลัก',
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
                label: 'ตราสารเลขที่',
                value: widget.item.referenceNo,
                isSmall: true,
              ),

              const SizedBox(height: 14),

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
                      Icons.account_balance_outlined,
                      size: 13,
                      color: Color(0xFF786C58),
                    ),
                    SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'ปัดสลิปเพื่อบรรจุเข้าคลังหลวงทั้ง 4',
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
}
