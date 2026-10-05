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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.gold, width: 1),
        ),
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: cat.color.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(cat.icon, color: AppColors.gold, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'บรรจุเข้า ${cat.latinTitle} [${cat.thaiTitle}]',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.gold,
                    ),
                  ),
                  Text(
                    '฿${NumberFormat('#,##0.00').format(item.amount)}',
                    style: const TextStyle(fontSize: 12, color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        ),
        action: SnackBarAction(
          label: 'เพิกถอน (Undo)',
          textColor: AppColors.goldBright,
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
    final tavernaCat = _getCategory(CornerPosition.topLeft);
    final quadrigaCat = _getCategory(CornerPosition.topRight);
    final forumCat = _getCategory(CornerPosition.bottomLeft);
    final tributumCat = _getCategory(CornerPosition.bottomRight);

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // Top Navigation & Roman Emperor Header
            Positioned(
              top: 6,
              left: 14,
              right: 14,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppColors.gold.withValues(alpha: 0.5),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.gold.withValues(alpha: 0.15),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.account_balance_rounded,
                          color: AppColors.gold,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Text(
                                'MONETA',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.8,
                                  color: AppColors.gold,
                                ),
                              ),
                              SizedBox(width: 6),
                              Text(
                                '• TEMPLUM',
                                style: TextStyle(
                                  fontSize: 10,
                                  letterSpacing: 1.0,
                                  color: AppColors.textMuted,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const Text(
                            'ปัดสลิป คุมคลังหลวง',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      // Laurel Wreath Streak Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        margin: const EdgeInsets.only(right: 6),
                        decoration: BoxDecoration(
                          color: AppColors.vaultTributum.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.vaultTributum.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Text('🌿', style: TextStyle(fontSize: 12)),
                            SizedBox(width: 4),
                            Text(
                              '7 วัน',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF6EE7B7),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Pending Cards Pill
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 4.5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.gold.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.style_rounded,
                              size: 13,
                              color: AppColors.gold,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              '${_pendingCards.length} สลิป',
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: AppColors.marbleWhite,
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

            // Top-Left Vault (I. Taverna)
            Positioned(
              top: 66,
              left: 14,
              child: CornerTargetBox(
                category: tavernaCat,
                isHovered: _hoveredCorner == CornerPosition.topLeft,
                totalAmount: _categoryTotals[tavernaCat.id] ?? 0.0,
                itemCount: _categoryCounts[tavernaCat.id] ?? 0,
              ),
            ),

            // Top-Right Vault (II. Quadriga)
            Positioned(
              top: 66,
              right: 14,
              child: CornerTargetBox(
                category: quadrigaCat,
                isHovered: _hoveredCorner == CornerPosition.topRight,
                totalAmount: _categoryTotals[quadrigaCat.id] ?? 0.0,
                itemCount: _categoryCounts[quadrigaCat.id] ?? 0,
              ),
            ),

            // Bottom-Left Vault (III. Forum)
            Positioned(
              bottom: 84,
              left: 14,
              child: CornerTargetBox(
                category: forumCat,
                isHovered: _hoveredCorner == CornerPosition.bottomLeft,
                totalAmount: _categoryTotals[forumCat.id] ?? 0.0,
                itemCount: _categoryCounts[forumCat.id] ?? 0,
              ),
            ),

            // Bottom-Right Vault (IV. Tributum)
            Positioned(
              bottom: 84,
              right: 14,
              child: CornerTargetBox(
                category: tributumCat,
                isHovered: _hoveredCorner == CornerPosition.bottomRight,
                totalAmount: _categoryTotals[tributumCat.id] ?? 0.0,
                itemCount: _categoryCounts[tributumCat.id] ?? 0,
              ),
            ),

            // Center Card Stack or Roman Triumph Empty State
            Center(
              child: _pendingCards.isEmpty
                  ? _buildRomanTriumphState()
                  : _buildCardStack(),
            ),

            // Bottom Floating Controls
            Positioned(
              bottom: 16,
              left: 18,
              right: 18,
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _openQuickAdd,
                      icon: const Icon(Icons.flash_on_rounded, size: 18, color: AppColors.gold),
                      label: const Text(
                        'บันทึกด่วน (Quick Deposit)',
                        style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.gold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.surface,
                        side: const BorderSide(color: AppColors.gold, width: 1.2),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  if (_categorizedCards.isNotEmpty)
                    IconButton.filled(
                      tooltip: 'เพิกถอนการกระทำล่าสุด (Undo)',
                      onPressed: _undoLastAction,
                      icon: const Icon(Icons.undo_rounded),
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.surface,
                        foregroundColor: AppColors.gold,
                        side: BorderSide(color: AppColors.gold.withValues(alpha: 0.4)),
                        padding: const EdgeInsets.all(14),
                      ),
                    ),
                  IconButton.filled(
                    tooltip: 'รีเซ็ตข้อมูลตัวอย่าง',
                    onPressed: _resetToSample,
                    icon: const Icon(Icons.refresh_rounded),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.surfaceLight,
                      foregroundColor: AppColors.textSecondary,
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

  Widget _buildRomanTriumphState() {
    double grandTotal = 0;
    for (var val in _categoryTotals.values) {
      grandTotal += val;
    }

    final currencyFormatter = NumberFormat('#,##0.00', 'th_TH');

    return Container(
      width: 324,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.gold, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.gold.withValues(alpha: 0.2),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Roman Laurel & Victory Medallion
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.gold, width: 2),
            ),
            child: const Icon(
              Icons.workspace_premium_rounded,
              color: AppColors.gold,
              size: 46,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'TRIUMPH! ฉลองชัยชนะ 🏆',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
              color: AppColors.gold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'ท่านได้จัดเก็บสลิป ${_categorizedCards.length} รายการเข้าสู่คลังหลวงอย่างสง่างาม ไร้หนี้สินตกค้าง',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12.5,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.surfaceLight),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'ทรัพย์ที่จัดสรรในคลัง',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
                Text(
                  '฿ ${currencyFormatter.format(grandTotal)}',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppColors.goldBright,
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
              label: const Text('เสกสลิปใหม่มาทดสอบ (Reset Deck)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: const Color(0xFF0F172A),
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
