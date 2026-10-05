import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../core/constants/categories.dart';
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
      width: 320,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: activeCat != null
            ? Border.all(color: activeCat.color, width: 2.5)
            : Border.all(color: Colors.grey.shade200, width: 1),
        boxShadow: [
          if (activeCat != null)
            BoxShadow(
              color: activeCat.color.withValues(alpha: 0.35),
              blurRadius: 24,
              offset: const Offset(0, 8),
            )
          else
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
        ],
      ),
      child: Stack(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Slip Header
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
                          color: widget.item.bankColor.withValues(alpha: 0.3),
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
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(
                        Icons.check_circle_rounded,
                        color: Color(0xFF10B981),
                        size: 15,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'โอนเงินสำเร็จ',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Amount Section
              Center(
                child: Column(
                  children: [
                    const Text(
                      'จำนวนเงินที่ชำระ',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '฿ ${currencyFormatter.format(widget.item.amount)}',
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),
              Divider(color: Colors.grey.shade200, height: 1),
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

              const SizedBox(height: 14),

              // Interaction Hint
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(
                      Icons.touch_app_rounded,
                      size: 14,
                      color: Color(0xFF64748B),
                    ),
                    SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'ลากหรือปัดเข้ามุม เพื่อแยกประเภท',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Active Category Overlay Badge
          if (activeCat != null)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: activeCat.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: activeCat.color,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: activeCat.color.withValues(alpha: 0.5),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(activeCat.icon, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            activeCat.title,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
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
              color: Color(0xFF94A3B8),
              fontWeight: FontWeight.w500,
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
