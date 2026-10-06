import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/constants/categories.dart';
import '../core/theme/app_theme.dart';
import '../models/expense_card_item.dart';
import '../widgets/arcade_button.dart';
import '../widgets/arcade_card.dart';
import '../widgets/arcade_badge.dart';
import '../widgets/arcade_progress_bar.dart';

class DashboardScreen extends StatelessWidget {
  final List<ExpenseCardItem> pendingCards;
  final List<ExpenseCardItem> categorizedCards;
  final double monthlyBudget;
  final int streakDays;
  final VoidCallback onStartSwiping;
  final VoidCallback onScanGallery;
  final VoidCallback onQuickAdd;
  final Function(ExpenseCategory) onSelectVault;
  final Function(ExpenseCardItem) onViewSlip;

  const DashboardScreen({
    super.key,
    required this.pendingCards,
    required this.categorizedCards,
    required this.monthlyBudget,
    required this.streakDays,
    required this.onStartSwiping,
    required this.onScanGallery,
    required this.onQuickAdd,
    required this.onSelectVault,
    required this.onViewSlip,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat('#,##0.00', 'th_TH');
    final shortFormatter = NumberFormat('#,##0', 'th_TH');
    final now = DateTime.now();
    final monthFormatter = DateFormat('MMMM yyyy', 'th_TH');

    // Calculate totals
    final double totalSpent = categorizedCards.fold(
      0.0,
      (sum, item) => sum + item.amount,
    );
    final double remainingBudget = (monthlyBudget - totalSpent).clamp(
      0.0,
      monthlyBudget,
    );
    final double budgetPercent = monthlyBudget > 0
        ? (totalSpent / monthlyBudget).clamp(0.0, 1.0)
        : 0.0;

    final Map<String, double> categoryTotals = {
      'food': 0.0,
      'transport': 0.0,
      'shopping': 0.0,
      'bills': 0.0,
    };
    final Map<String, int> categoryCounts = {
      'food': 0,
      'transport': 0,
      'shopping': 0,
      'bills': 0,
    };

    for (final item in categorizedCards) {
      if (item.assignedCategory != null) {
        final id = item.assignedCategory!.id;
        categoryTotals[id] = (categoryTotals[id] ?? 0.0) + item.amount;
        categoryCounts[id] = (categoryCounts[id] ?? 0) + 1;
      }
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Imperial App Bar Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.gold.withValues(alpha: 0.4),
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.gold.withValues(alpha: 0.15),
                                blurRadius: 12,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.account_balance_rounded,
                            color: AppColors.gold,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'MONETA',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2.0,
                                color: AppColors.gold,
                              ),
                            ),
                            Text(
                              monthFormatter.format(now),
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Streak Badge
                    ArcadeBadge(
                      label: '$streakDays วัน',
                      leading: const Text('🔥', style: TextStyle(fontSize: 14)),
                      color: AppColors.vaultTributumBg,
                      borderColor: AppColors.vaultTributumShadow.withValues(
                        alpha: 0.4,
                      ),
                      textColor: AppColors.vaultTributumShadow,
                      fontSize: 12,
                      depth: 0,
                    ),
                  ],
                ),
              ),
            ),

            // Budget Overview Card
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: ArcadeCard(
                  borderColor: AppColors.gold.withValues(alpha: 0.35),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'งบประมาณประจำเดือน',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          ArcadeBadge(
                            label:
                                'งบ ฿ ${shortFormatter.format(monthlyBudget)}',
                            color: AppColors.gold.withValues(alpha: 0.15),
                            borderColor: AppColors.gold.withValues(alpha: 0.5),
                            textColor: AppColors.gold,
                            depth: 0,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '฿ ${currencyFormatter.format(totalSpent)}',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: AppColors.marbleWhite,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ArcadeProgressBar(value: budgetPercent, height: 9),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'ใช้ไปแล้ว ${(budgetPercent * 100).toStringAsFixed(1)}%',
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            'คงเหลือ ฿ ${currencyFormatter.format(remainingBudget)}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF059669),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Hero Pending Triage Card (Call to Action to start swiping)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: ArcadeCard(
                  borderColor: pendingCards.isNotEmpty
                      ? AppColors.gold
                      : AppColors.borderDark,
                  borderWidth: 2.0,
                  shadowColor: pendingCards.isNotEmpty
                      ? AppColors.goldShadow
                      : AppColors.shadowDefault,
                  depth: 4.0,
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: pendingCards.isNotEmpty
                              ? AppColors.gold
                              : AppColors.surfaceLight,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: pendingCards.isNotEmpty
                                ? AppColors.goldShadow
                                : AppColors.borderDark,
                            width: 1.5,
                          ),
                        ),
                        child: Icon(
                          pendingCards.isNotEmpty
                              ? Icons.view_carousel_rounded
                              : Icons.check_circle_rounded,
                          color: pendingCards.isNotEmpty
                              ? Colors.black87
                              : AppColors.textSecondary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              pendingCards.isNotEmpty
                                  ? 'มีสลิป ${pendingCards.length} ใบ รอปัดแยกหมวด'
                                  : 'จัดหมวดหมู่สลิปครบแล้ว!',
                              style: const TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.bold,
                                color: AppColors.marbleWhite,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              pendingCards.isNotEmpty
                                  ? 'ปัดเข้า 4 มุมเพื่อบันทึกหมวดหมู่'
                                  : 'ยอดเยี่ยมมาก! ไม่มีสลิปค้างในสำรับ',
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      ArcadeButton(
                        onPressed: onStartSwiping,
                        color: pendingCards.isNotEmpty
                            ? AppColors.gold
                            : AppColors.surfaceLight,
                        shadowColor: pendingCards.isNotEmpty
                            ? AppColors.goldShadow
                            : AppColors.shadowDefault,
                        borderColor: pendingCards.isNotEmpty
                            ? AppColors.goldShadow
                            : AppColors.borderDark,
                        depth: 3.5,
                        borderRadius: BorderRadius.circular(14),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 9,
                        ),
                        child: Text(
                          pendingCards.isNotEmpty ? 'เริ่มปัด ⚡' : 'ดูสำรับ',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w900,
                            color: pendingCards.isNotEmpty
                                ? Colors.black87
                                : AppColors.marbleWhite,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Quick Actions Bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: ArcadeButton(
                        onPressed: onScanGallery,
                        color: AppColors.surface,
                        shadowColor: AppColors.shadowDefault,
                        borderColor: AppColors.borderDark,
                        depth: 3.5,
                        borderRadius: BorderRadius.circular(14),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(
                              Icons.document_scanner_rounded,
                              size: 18,
                              color: AppColors.vaultQuadriga,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'กวาดสลิป',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ArcadeButton(
                        onPressed: onQuickAdd,
                        color: AppColors.surface,
                        shadowColor: AppColors.shadowDefault,
                        borderColor: AppColors.borderDark,
                        depth: 3.5,
                        borderRadius: BorderRadius.circular(14),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(
                              Icons.flash_on_rounded,
                              size: 18,
                              color: AppColors.goldShadow,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'บันทึกด่วน',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 4 Categories Section Header
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 18, 20, 10),
                child: Text(
                  '4 หมวดหมู่ค่าใช้จ่าย',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                    color: AppColors.marbleWhite,
                  ),
                ),
              ),
            ),

            // 4 Vaults 2x2 Grid (Filled Vibrant Cartoon Tiles)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.28,
                ),
                delegate: SliverChildBuilderDelegate((context, index) {
                  final cat = ExpenseCategory.defaultCorners[index];
                  final amount = categoryTotals[cat.id] ?? 0.0;
                  final count = categoryCounts[cat.id] ?? 0;

                  return ArcadeCard(
                    onTap: () => onSelectVault(cat),
                    color: cat.color,
                    borderColor: cat.shadowColor,
                    borderWidth: 2.0,
                    shadowColor: cat.shadowColor,
                    depth: 3.5,
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                cat.icon,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              cat.thaiTitle,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '฿ ${shortFormatter.format(amount)} ($count ใบ)',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w900,
                                color: Colors.white.withValues(alpha: 0.95),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }, childCount: ExpenseCategory.defaultCorners.length),
              ),
            ),

            // Recent Transactions Section Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'รายการที่เพิ่งคัดแยก (Recent Items)',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.marbleWhite,
                      ),
                    ),
                    Text(
                      '${categorizedCards.length} รายการ',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Recent Transactions List
            if (categorizedCards.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  child: ArcadeCard(
                    color: AppColors.surfaceLight,
                    borderColor: AppColors.border,
                    depth: 2.0,
                    padding: const EdgeInsets.all(20),
                    child: const Center(
                      child: Text(
                        'ยังไม่มีรายการที่คัดแยกในเดือนนี้ ปัดสลิปเพื่อเริ่มต้น!',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = categorizedCards.reversed.toList()[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 4,
                      ),
                      child: ArcadeCard(
                        onTap: () => onViewSlip(item),
                        depth: 2.5,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color:
                                    item.assignedCategory?.color ??
                                    item.bankColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.receiverName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.marbleWhite,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${item.bankName} • ${DateFormat('dd MMM, HH:mm', 'th_TH').format(item.dateTime)}',
                                    style: const TextStyle(
                                      fontSize: 10.5,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '฿ ${currencyFormatter.format(item.amount)}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.gold,
                                  ),
                                ),
                                if (item.assignedCategory != null)
                                  Text(
                                    item.assignedCategory!.thaiTitle,
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w600,
                                      color: item.assignedCategory!.color,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  childCount: categorizedCards.length > 5
                      ? 5
                      : categorizedCards.length,
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }
}
