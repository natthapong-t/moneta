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
    // Only classify as corner if there is clear vertical intent towards the vault corners
    if (offset.dy.abs() < 75.0 || offset.dx.abs() < 55.0) {
      return null;
    }

    if (offset.dx < 0 && offset.dy < 0) {
      return CornerPosition.topLeft;
    } else if (offset.dx > 0 && offset.dy < 0) {
      return CornerPosition.topRight;
    } else if (offset.dx < 0 && offset.dy > 0) {
      return CornerPosition.bottomLeft;
    } else if (offset.dx > 0 && offset.dy > 0) {
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

    // Detect velocity-based flick towards one of the 4 corners
    final velocity = details.velocity.pixelsPerSecond;
    final speed = velocity.distance;

    if (targetCorner == null && speed > 260) {
      final vx = velocity.dx;
      final vy = velocity.dy;

      if (vx < 0 && vy < -120) {
        targetCorner = CornerPosition.topLeft;
      } else if (vx > 0 && vy < -120) {
        targetCorner = CornerPosition.topRight;
      } else if (vx < 0 && vy > 120) {
        targetCorner = CornerPosition.bottomLeft;
      } else if (vx > 0 && vy > 120) {
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

      _springAnimation = Tween<Offset>(begin: _dragOffset, end: endOffset)
          .animate(
            CurvedAnimation(
              parent: _springController,
              curve: Curves.easeInCubic,
            ),
          );

      _springController.duration = const Duration(milliseconds: 180);
      _springController.forward(from: 0.0).then((_) {
        widget.onProximityChanged(null);
        widget.onCategorized(targetCorner!);
      });
    } else {
      widget.onProximityChanged(null);

      _springAnimation = Tween<Offset>(begin: _dragOffset, end: Offset.zero)
          .animate(
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

    return _buildSyntheticFallbackCard(
      currencyFormatter,
      dateFormatter,
      activeCat,
    );
  }

  Widget _buildActualSlipImageCard(
    ExpenseCategory? activeCat,
    NumberFormat currencyFormatter,
  ) {
    return Container(
      width: 245,
      height: 295,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: activeCat != null
            ? Border.all(color: activeCat.shadowColor, width: 3.0)
            : Border.all(color: AppColors.borderDark, width: 2.2),
        boxShadow: [
          BoxShadow(
            color: activeCat != null
                ? activeCat.shadowColor
                : AppColors.shadowDefault,
            offset: const Offset(0, 5),
            blurRadius: 0, // Flat 3D cartoon perspective
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          children: [
            // 1. The Actual Slip Image (Rendered directly)
            Positioned.fill(
              child: Container(
                color: const Color(0xFFF1F5F9),
                child: Center(child: _buildSlipImage(widget.item.imagePath!)),
              ),
            ),

            // 2. Floating Amount Pill (Top Right) - Arcade 3D Gold Badge
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.gold,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.goldShadow, width: 2.0),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.goldShadow,
                      offset: Offset(0, 2),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: Text(
                  '฿ ${currencyFormatter.format(widget.item.amount)}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1E293B),
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),

            // 3. Floating Bank Chip (Top Left) - Flat Cartoon Pill
            Positioned(
              top: 10,
              left: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: widget.item.bankColor, width: 1.8),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.shadowDefault,
                      offset: Offset(0, 2),
                      blurRadius: 0,
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
                    const SizedBox(width: 5),
                    Text(
                      widget.item.bankName,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
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
                bottom: 10,
                left: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderDark, width: 1.5),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.shadowDefault,
                        offset: Offset(0, 2),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.edit_note_rounded,
                        size: 15,
                        color: AppColors.goldShadow,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          widget.item.note!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
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
                    color: activeCat.bgColor.withValues(alpha: 0.88),
                    borderRadius: BorderRadius.circular(19),
                    border: Border.all(
                      color: activeCat.shadowColor,
                      width: 3.0,
                    ),
                  ),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: activeCat.shadowColor,
                          width: 2.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: activeCat.shadowColor,
                            offset: const Offset(0, 4),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: activeCat.color,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              activeCat.icon,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                activeCat.thaiTitle,
                                style: TextStyle(
                                  color: activeCat.shadowColor,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              Text(
                                'หมวดที่ ${activeCat.romanNumeral} • ${activeCat.latinTitle}',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
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
      width: 245,
      height: 295,
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: activeCat != null
            ? Border.all(color: activeCat.shadowColor, width: 3.0)
            : Border.all(color: AppColors.borderDark, width: 2.2),
        boxShadow: [
          BoxShadow(
            color: activeCat != null
                ? activeCat.shadowColor
                : AppColors.shadowDefault,
            offset: const Offset(0, 5),
            blurRadius: 0, // Zero-blur flat 3D shadow
            spreadRadius: 0,
          ),
        ],
      ),
      child: Stack(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header: Bank Chip & Success Pill
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
                            color: widget.item.bankColor.withValues(
                              alpha: 0.12,
                            ),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: widget.item.bankColor,
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
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
                                    fontWeight: FontWeight.w900,
                                    color: widget.item.bankColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Approved Medallion (Duolingo Lime Green 3D Pill)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3.5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.vaultTributum,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: const [
                            BoxShadow(
                              color: AppColors.vaultTributumShadow,
                              offset: Offset(0, 2),
                              blurRadius: 0,
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
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Amount Section
                  Center(
                    child: Column(
                      children: [
                        const Text(
                          'ยอดชำระ',
                          style: TextStyle(
                            fontSize: 10.5,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '฿ ${currencyFormatter.format(widget.item.amount)}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 6),
                  Container(height: 1.5, color: AppColors.border),
                  const SizedBox(height: 6),

                  // Receiver Info
                  _buildMetaRow(
                    label: 'โอนไปยัง',
                    value: widget.item.receiverName,
                    isHighlight: true,
                  ),

                  if (widget.item.note != null &&
                      widget.item.note!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    _buildMetaRow(
                      label: 'บันทึกช่วยจำ',
                      value: widget.item.note!,
                      isMuted: true,
                    ),
                  ],

                  const SizedBox(height: 4),
                  _buildMetaRow(
                    label: 'วัน-เวลา',
                    value: dateFormatter.format(widget.item.dateTime),
                  ),

                  const SizedBox(height: 4),
                  _buildMetaRow(
                    label: 'เลขที่อ้างอิง',
                    value: widget.item.referenceNo,
                    isSmall: true,
                  ),

                  if (widget.item.imagePath != null) ...[
                    const SizedBox(height: 6),
                    Center(
                      child: GestureDetector(
                        onTap: () =>
                            _viewOriginalSlip(context, widget.item.imagePath!),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceLight,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppColors.borderDark,
                              width: 1.2,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: AppColors.shadowDefault,
                                offset: Offset(0, 1.5),
                                blurRadius: 0,
                              ),
                            ],
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
                                  fontWeight: FontWeight.w900,
                                  color: widget.item.bankColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),

              // Interaction Hint - Arcade Bubble
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 6),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border, width: 1.2),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(
                      Icons.swipe_rounded,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                    SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'ปัดสลิปไปยัง 4 มุมเพื่อจัดหมวดหมู่',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
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
                  color: activeCat.bgColor.withValues(alpha: 0.90),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: activeCat.shadowColor, width: 3),
                ),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: activeCat.shadowColor,
                        width: 2.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: activeCat.shadowColor,
                          offset: const Offset(0, 4),
                          blurRadius: 0,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: activeCat.color,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            activeCat.icon,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                activeCat.thaiTitle,
                                style: TextStyle(
                                  color: activeCat.shadowColor,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              Text(
                                'หมวดที่ ${activeCat.romanNumeral} • ${activeCat.latinTitle}',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
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
          width: 68,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 10.5,
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
                  icon: const Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
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
