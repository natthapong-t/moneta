import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../core/constants/categories.dart';
import '../core/theme/app_theme.dart';
import '../models/expense_card_item.dart';
import '../widgets/corner_target_box.dart';
import '../widgets/quick_add_sheet.dart';
import '../widgets/swipeable_slip_card.dart';

class SwipeFeedScreen extends StatefulWidget {
  const SwipeFeedScreen({super.key});

  @override
  State<SwipeFeedScreen> createState() => _SwipeFeedScreenState();
}

class _SwipeFeedScreenState extends State<SwipeFeedScreen> {
  late List<ExpenseCardItem> _pendingCards;
  final List<ExpenseCardItem> _categorizedCards = [];
  CornerPosition? _hoveredCorner;

  final Map<String, double> _categoryTotals = {
    'food': 0.0,
    'transport': 0.0,
    'shopping': 0.0,
    'bills': 0.0,
  };

  final Map<String, int> _categoryCounts = {
    'food': 0,
    'transport': 0,
    'shopping': 0,
    'bills': 0,
  };

  @override
  void initState() {
    super.initState();
    _resetToSample();
  }

  void _resetToSample() {
    setState(() {
      _pendingCards = List.from(ExpenseCardItem.sampleCards);
      _categorizedCards.clear();
      for (var key in _categoryTotals.keys) {
        _categoryTotals[key] = 0.0;
        _categoryCounts[key] = 0;
      }
      _hoveredCorner = null;
    });
  }

  void _onCardCategorized(ExpenseCardItem item, CornerPosition corner) {
    final cat = ExpenseCategory.defaultCorners.firstWhere(
      (c) => c.corner == corner,
    );

    setState(() {
      _pendingCards.removeWhere((c) => c.id == item.id);
      final updatedItem = item.copyWith(assignedCategory: cat);
      _categorizedCards.add(updatedItem);

      _categoryTotals[cat.id] = (_categoryTotals[cat.id] ?? 0.0) + item.amount;
      _categoryCounts[cat.id] = (_categoryCounts[cat.id] ?? 0) + 1;
      _hoveredCorner = null;
    });

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.surfaceLight,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Row(
          children: [
            Icon(cat.icon, color: cat.color, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'บันทึกเข้า "${cat.title}" ฿${NumberFormat('#,##0.00').format(item.amount)}',
                style: const TextStyle(fontSize: 13, color: Colors.white),
              ),
            ),
          ],
        ),
        action: SnackBarAction(
          label: 'เลิกทำ (Undo)',
          textColor: AppColors.primary,
          onPressed: _undoLastAction,
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _undoLastAction() {
    if (_categorizedCards.isEmpty) return;

    final lastItem = _categorizedCards.removeLast();
    final cat = lastItem.assignedCategory;

    setState(() {
      _pendingCards.insert(0, lastItem);
      if (cat != null) {
        _categoryTotals[cat.id] =
            (_categoryTotals[cat.id] ?? 0.0) - lastItem.amount;
        _categoryCounts[cat.id] =
            (_categoryCounts[cat.id] ?? 1) - 1;
      }
    });

    HapticFeedback.lightImpact();
  }

  void _openQuickAdd() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => QuickAddSheet(
        onCardCreated: (newItem) {
          setState(() {
            _pendingCards.insert(0, newItem);
          });
          HapticFeedback.lightImpact();
        },
      ),
    );
  }

  ExpenseCategory _getCategory(CornerPosition corner) {
    return ExpenseCategory.defaultCorners.firstWhere((c) => c.corner == corner);
  }

  @override
  Widget build(BuildContext context) {
    final foodCat = _getCategory(CornerPosition.topLeft);
    final transportCat = _getCategory(CornerPosition.topRight);
    final shoppingCat = _getCategory(CornerPosition.bottomLeft);
    final billsCat = _getCategory(CornerPosition.bottomRight);

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // Top Navigation Bar
            Positioned(
              top: 8,
              left: 16,
              right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.3),
                          ),
                        ),
                        child: const Icon(
                          Icons.monetization_on_rounded,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'MONETA',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            'Swipe & Categorize',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      if (_categorizedCards.isNotEmpty)
                        IconButton(
                          tooltip: 'เลิกทำ (Undo)',
                          onPressed: _undoLastAction,
                          icon: const Icon(
                            Icons.undo_rounded,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.surfaceLight),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.style_rounded,
                              size: 14,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'เหลือ ${_pendingCards.length} ใบ',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Top-Left Corner Box (Food)
            Positioned(
              top: 68,
              left: 14,
              child: CornerTargetBox(
                category: foodCat,
                isHovered: _hoveredCorner == CornerPosition.topLeft,
                totalAmount: _categoryTotals[foodCat.id] ?? 0.0,
                itemCount: _categoryCounts[foodCat.id] ?? 0,
              ),
            ),

            // Top-Right Corner Box (Transport)
            Positioned(
              top: 68,
              right: 14,
              child: CornerTargetBox(
                category: transportCat,
                isHovered: _hoveredCorner == CornerPosition.topRight,
                totalAmount: _categoryTotals[transportCat.id] ?? 0.0,
                itemCount: _categoryCounts[transportCat.id] ?? 0,
              ),
            ),

            // Bottom-Left Corner Box (Shopping)
            Positioned(
              bottom: 84,
              left: 14,
              child: CornerTargetBox(
                category: shoppingCat,
                isHovered: _hoveredCorner == CornerPosition.bottomLeft,
                totalAmount: _categoryTotals[shoppingCat.id] ?? 0.0,
                itemCount: _categoryCounts[shoppingCat.id] ?? 0,
              ),
            ),

            // Bottom-Right Corner Box (Bills)
            Positioned(
              bottom: 84,
              right: 14,
              child: CornerTargetBox(
                category: billsCat,
                isHovered: _hoveredCorner == CornerPosition.bottomRight,
                totalAmount: _categoryTotals[billsCat.id] ?? 0.0,
                itemCount: _categoryCounts[billsCat.id] ?? 0,
              ),
            ),

            // Center Card Stack or Empty State
            Center(
              child: _pendingCards.isEmpty
                  ? _buildEmptyState()
                  : _buildCardStack(),
            ),

            // Bottom Floating Controls
            Positioned(
              bottom: 16,
              left: 20,
              right: 20,
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _openQuickAdd,
                      icon: const Icon(Icons.flash_on_rounded, size: 18),
                      label: const Text(
                        'บันทึกด่วน (Quick Add)',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.surface,
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary, width: 1.2),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton.filled(
                    tooltip: 'รีเซ็ตข้อมูลตัวอย่าง',
                    onPressed: _resetToSample,
                    icon: const Icon(Icons.refresh_rounded),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.surfaceLight,
                      foregroundColor: AppColors.textPrimary,
                      padding: const EdgeInsets.all(14),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardStack() {
    return Stack(
      alignment: Alignment.center,
      children: [
        for (int i = (_pendingCards.length > 3 ? 2 : _pendingCards.length - 1);
            i >= 0;
            i--)
          _buildStackedCard(i),
      ],
    );
  }

  Widget _buildStackedCard(int index) {
    final item = _pendingCards[index];
    final isTop = index == 0;

    final double scale = 1.0 - (index * 0.05);
    final double yOffset = index * 12.0;

    return Transform.translate(
      offset: Offset(0, yOffset),
      child: Transform.scale(
        scale: scale,
        child: SwipeableSlipCard(
          key: ValueKey(item.id),
          item: item,
          isTopCard: isTop,
          onProximityChanged: (corner) {
            setState(() {
              _hoveredCorner = corner;
            });
          },
          onCategorized: (corner) {
            _onCardCategorized(item, corner);
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    double grandTotal = 0;
    for (var val in _categoryTotals.values) {
      grandTotal += val;
    }

    final currencyFormatter = NumberFormat('#,##0.00', 'th_TH');

    return Container(
      width: 320,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.surfaceLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_outline_rounded,
              color: AppColors.primary,
              size: 48,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'เคลียร์สลิปทั้งหมดแล้ว! 🎉',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'คุณจัดระเบียบรายจ่ายครบ ${_categorizedCards.length} รายการ',
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'ยอดรวมที่บันทึก',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
                Text(
                  '฿ ${currencyFormatter.format(grandTotal)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _resetToSample,
              icon: const Icon(Icons.replay_rounded, size: 18),
              label: const Text('ทดสอบใหม่ (โหลดสลิปตัวอย่าง)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
