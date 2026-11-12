import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../core/constants/categories.dart';
import '../core/theme/app_theme.dart';
import '../models/expense_card_item.dart';
import '../services/expense_storage_service.dart';
import '../widgets/arcade_button.dart';
import '../widgets/arcade_card.dart';
import '../widgets/living_creature_widget.dart';
import '../widgets/moneta_goddess_widget.dart';
import '../widgets/no_spend_banner.dart';

class DashboardScreen extends StatefulWidget {
  final List<ExpenseCardItem> pendingCards;
  final List<ExpenseCardItem> categorizedCards;
  final double monthlyBudget;
  final int streakDays;
  final VoidCallback onStartSwiping;
  final VoidCallback onScanGallery;
  final VoidCallback onQuickAdd;
  final VoidCallback? onQuickIncome;
  final VoidCallback? onOpenCalendar;
  final Function(ExpenseCategory) onSelectVault;
  final Function(ExpenseCardItem) onViewSlip;
  final VoidCallback? onResetToSample;
  final VoidCallback? onClearAllData;

  const DashboardScreen({
    super.key,
    required this.pendingCards,
    required this.categorizedCards,
    required this.monthlyBudget,
    required this.streakDays,
    required this.onStartSwiping,
    required this.onScanGallery,
    required this.onQuickAdd,
    this.onQuickIncome,
    this.onOpenCalendar,
    required this.onSelectVault,
    required this.onViewSlip,
    this.onResetToSample,
    this.onClearAllData,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isTodayNoSpendDay = false;

  double get _monthlyBudget => widget.monthlyBudget;
  int get _streakDays => widget.streakDays;

  void _openQuickAddSheet() {
    widget.onQuickAdd();
  }

  @override
  void initState() {
    super.initState();
    _checkNoSpend();
  }

  Future<void> _checkNoSpend() async {
    final checked = await ExpenseStorageService.instance.isTodayNoSpendDay();
    if (mounted) {
      setState(() {
        _isTodayNoSpendDay = checked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat('#,##0.00', 'th_TH');
    final shortFormatter = NumberFormat('#,##0', 'th_TH');
    final now = DateTime.now();
    final thaiDateFormatter = DateFormat('EEEEที่ d MMM', 'th_TH');

    // Totals
    double totalSpent = 0;
    double todaySpent = 0;
    int todayEntries = 0;

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

    // 7-day filter
    final sevenDaysAgo = now.subtract(const Duration(days: 7));
    double sevenDaysSpent = 0;
    final Map<String, double> sevenDaysCategoryTotals = {
      'food': 0.0,
      'transport': 0.0,
      'shopping': 0.0,
      'bills': 0.0,
    };

    double spentForMyself = 0;
    double spentForSweetheart = 0;
    double spentForFriends = 0;

    for (final item in widget.categorizedCards) {
      if (!item.isIncome) {
        totalSpent += item.amount;
        if (item.assignedCategory != null) {
          final id = item.assignedCategory!.id;
          categoryTotals[id] = (categoryTotals[id] ?? 0.0) + item.amount;
          categoryCounts[id] = (categoryCounts[id] ?? 0) + 1;
        }

        // Today
        if (item.dateTime.year == now.year &&
            item.dateTime.month == now.month &&
            item.dateTime.day == now.day) {
          todaySpent += item.amount;
          todayEntries++;
        }

        // Past 7 days
        if (item.dateTime.isAfter(sevenDaysAgo)) {
          sevenDaysSpent += item.amount;
          if (item.assignedCategory != null) {
            final id = item.assignedCategory!.id;
            sevenDaysCategoryTotals[id] =
                (sevenDaysCategoryTotals[id] ?? 0.0) + item.amount;
          }

          // Person
          switch (item.targetPerson) {
            case TargetPerson.myself:
              spentForMyself += item.amount;
              break;
            case TargetPerson.sweetheart:
              spentForSweetheart += item.amount;
              break;
            case TargetPerson.friends:
              spentForFriends += item.amount;
              break;
          }
        }
      }
    }

    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final dailyAverageThisMonth = now.day > 0 ? (totalSpent / now.day) : 0.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Header (Thai date + Flame streak + Reset)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Clean Thai date in confident white typography
                    Expanded(
                      child: Text(
                        thaiDateFormatter.format(now),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: AppColors.marbleWhite,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Row(
                      children: [
                        // Clean streak flame pill
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.border,
                              width: 1.0,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('🔥', style: TextStyle(fontSize: 13)),
                              const SizedBox(width: 4),
                              Text(
                                '${widget.streakDays}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.mintioStreakFlame,
                                ).withTabularFigures(),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Reset button
                        ArcadeButton(
                          onPressed: () => _showResetDialog(context),
                          color: AppColors.surface,
                          shadowColor: AppColors.shadowDefault,
                          borderColor: AppColors.borderDark,
                          borderWidth: 1.5,
                          depth: 2.0,
                          borderRadius: BorderRadius.circular(12),
                          padding: EdgeInsets.zero,
                          width: 34,
                          height: 32,
                          child: const Icon(
                            Icons.restart_alt_rounded,
                            size: 18,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Moneta Sanctum Hero
            SliverToBoxAdapter(
              child: MonetaSanctumHero(
                monthlyBudget: _monthlyBudget,
                totalSpent: totalSpent,
                todaySpent: todaySpent,
                streakDays: _streakDays,
                isTodayNoSpend: _isTodayNoSpendDay || (todaySpent == 0),
                pendingSlipsCount: widget.pendingCards.length,
                onAddExpensePressed: _openQuickAddSheet,
              ),
            ),

            // No-Spend Day Streak Protection Banner
            SliverToBoxAdapter(
              child: NoSpendBanner(
                onStreakUpdated: () {
                  _checkNoSpend();
                  setState(() {});
                },
              ),
            ),

            // Modern 2-Col Metric Section: เฉลี่ยต่อวัน + รายการวันนี้
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.border,
                      width: 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Column 1: เฉลี่ยต่อวัน
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  'เฉลี่ยต่อวัน',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '(${now.day}/$daysInMonth)',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textMuted,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Text(
                              totalSpent > 0
                                  ? '฿${shortFormatter.format(dailyAverageThisMonth)}'
                                  : '฿0',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: AppColors.marbleWhite,
                              ).withTabularFigures(),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 38,
                        color: AppColors.border,
                      ),
                      const SizedBox(width: 18),
                      // Column 2: รายการวันนี้
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'รายการวันนี้',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              todayEntries > 0 ? '$todayEntries รายการ' : '0 รายการ',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: AppColors.marbleWhite,
                              ).withTabularFigures(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Pending Slips Call to Action (Swipe Triage CTA)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: widget.pendingCards.isNotEmpty
                        ? AppColors.surfaceElevated
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: widget.pendingCards.isNotEmpty
                          ? AppColors.indigoPrimary.withValues(alpha: 0.6)
                          : AppColors.border,
                      width: widget.pendingCards.isNotEmpty ? 1.5 : 1.0,
                    ),
                    boxShadow: widget.pendingCards.isNotEmpty
                        ? [
                            BoxShadow(
                              color: AppColors.indigoPrimary.withValues(alpha: 0.15),
                              blurRadius: 12,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: widget.pendingCards.isNotEmpty
                              ? AppColors.indigoPrimary.withValues(alpha: 0.18)
                              : AppColors.surfaceLight,
                          borderRadius: AppTheme.innerBorderRadius(20, 12),
                        ),
                        child: Icon(
                          widget.pendingCards.isNotEmpty
                              ? Icons.view_carousel_rounded
                              : Icons.check_circle_rounded,
                          color: widget.pendingCards.isNotEmpty
                              ? AppColors.indigoPrimary
                              : AppColors.mintSuccess,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.pendingCards.isNotEmpty
                                  ? 'มีสลิป ${widget.pendingCards.length} ใบ รอปัดแยกหมวด'
                                  : 'จัดหมวดหมู่สลิปครบแล้ว!',
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: AppColors.marbleWhite,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.pendingCards.isNotEmpty
                                  ? 'ปัดเข้า 4 มุมเพื่อบันทึกหมวด'
                                  : 'ไม่มีสลิปค้างรอคัดแยก',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      ArcadeButton(
                        onPressed: widget.onStartSwiping,
                        color: widget.pendingCards.isNotEmpty
                            ? AppColors.indigoPrimary
                            : AppColors.surfaceLight,
                        shadowColor: widget.pendingCards.isNotEmpty
                            ? AppColors.goldShadow
                            : AppColors.shadowDefault,
                        borderColor: widget.pendingCards.isNotEmpty
                            ? AppColors.goldShadow
                            : AppColors.borderDark,
                        depth: 2.5,
                        borderRadius: AppTheme.innerBorderRadius(20, 14),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        child: Text(
                          widget.pendingCards.isNotEmpty ? 'ปัดเลย' : 'ดูรายการ',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w900,
                            color: widget.pendingCards.isNotEmpty
                                ? Colors.white
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
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: ArcadeButton(
                        onPressed: widget.onScanGallery,
                        color: AppColors.surface,
                        shadowColor: AppColors.shadowDefault,
                        borderColor: AppColors.borderDark,
                        depth: 3.0,
                        borderRadius: BorderRadius.circular(14),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.document_scanner_rounded,
                                size: 16, color: AppColors.vaultQuadriga),
                            SizedBox(width: 4),
                            Text(
                              'กวาดสลิป',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (widget.onQuickIncome != null) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: ArcadeButton(
                          onPressed: widget.onQuickIncome!,
                          color: AppColors.emerald,
                          shadowColor: AppColors.emeraldShadow,
                          borderColor: AppColors.emeraldShadow,
                          depth: 3.0,
                          borderRadius: BorderRadius.circular(14),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('🪙', style: TextStyle(fontSize: 14)),
                              SizedBox(width: 4),
                              Text(
                                '+ รับเงิน',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(width: 8),
                    Expanded(
                      child: ArcadeButton(
                        onPressed: widget.onQuickAdd,
                        color: AppColors.surface,
                        shadowColor: AppColors.shadowDefault,
                        borderColor: AppColors.borderDark,
                        depth: 3.0,
                        borderRadius: BorderRadius.circular(14),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_rounded,
                                size: 16, color: AppColors.vaultTaverna),
                            SizedBox(width: 4),
                            Text(
                              '+ จ่ายเงิน',
                              style: TextStyle(
                                fontSize: 12,
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

            // Mintio Section 1: "7 วันนี้ เงินไปไหนนะ"
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '7 วันนี้ เงินไปไหนนะ',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: AppColors.marbleWhite,
                      ),
                    ),
                    Text(
                      'รวม ฿${shortFormatter.format(sevenDaysSpent)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.bold,
                      ).withTabularFigures(),
                    ),
                  ],
                ),
              ),
            ),

            // 7 Days Spending by Category List
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ArcadeCard(
                  borderColor: AppColors.borderDark,
                  borderRadius: BorderRadius.circular(20),
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: ExpenseCategory.defaultCorners.map((cat) {
                      final amount = sevenDaysCategoryTotals[cat.id] ?? 0.0;
                      final percent = sevenDaysSpent > 0 ? (amount / sevenDaysSpent) : 0.0;

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: cat.color.withValues(alpha: 0.15),
                                borderRadius: AppTheme.innerBorderRadius(20, 14),
                              ),
                              child: Icon(cat.icon, color: cat.color, size: 18),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '${cat.thaiTitle} ${(percent * 100).toStringAsFixed(0)}%',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      Text(
                                        '฿${currencyFormatter.format(amount)}',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w900,
                                          color: AppColors.marbleWhite,
                                        ).withTabularFigures(),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: LinearProgressIndicator(
                                      value: percent,
                                      minHeight: 5,
                                      backgroundColor: AppColors.surfaceLight,
                                      valueColor:
                                          AlwaysStoppedAnimation<Color>(cat.color),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),

            // Mintio Section 2: "7 วันนี้ จ่ายให้ใครนะ"
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: const Text(
                  '7 วันนี้ จ่ายให้ใครนะ',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: AppColors.marbleWhite,
                  ),
                ),
              ),
            ),

            // 7 Days Spending by Person
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ArcadeCard(
                  borderColor: AppColors.borderDark,
                  borderRadius: BorderRadius.circular(20),
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      _buildPersonRow(
                        TargetPerson.myself,
                        spentForMyself,
                        sevenDaysSpent > 0 ? (spentForMyself / sevenDaysSpent) : 0.0,
                        currencyFormatter,
                      ),
                      const Divider(height: 16, color: AppColors.border),
                      _buildPersonRow(
                        TargetPerson.sweetheart,
                        spentForSweetheart,
                        sevenDaysSpent > 0 ? (spentForSweetheart / sevenDaysSpent) : 0.0,
                        currencyFormatter,
                      ),
                      const Divider(height: 16, color: AppColors.border),
                      _buildPersonRow(
                        TargetPerson.friends,
                        spentForFriends,
                        sevenDaysSpent > 0 ? (spentForFriends / sevenDaysSpent) : 0.0,
                        currencyFormatter,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 4 Vaults Header & 2x2 Grid
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 22, 20, 10),
                child: Text(
                  '4 คลังเก็บเงิน (Vaults)',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                    color: AppColors.marbleWhite,
                  ),
                ),
              ),
            ),

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
                    onTap: () => widget.onSelectVault(cat),
                    color: cat.color,
                    borderColor: cat.shadowColor,
                    borderWidth: 2.0,
                    shadowColor: cat.shadowColor,
                    depth: 3.5,
                    borderRadius: BorderRadius.circular(18),
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
                                borderRadius: AppTheme.innerBorderRadius(18, 12),
                              ),
                              child: Icon(cat.icon, color: Colors.white, size: 18),
                            ),
                            // Small mascot eyes on vault!
                            const BlinkingCreatureEyes(
                              width: 32,
                              height: 20,
                              pupilColor: Colors.black87,
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
                              ).withTabularFigures(),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }, childCount: ExpenseCategory.defaultCorners.length),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonRow(TargetPerson person, double amount, double percent,
      NumberFormat formatter) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: person.color.withValues(alpha: 0.15),
            borderRadius: AppTheme.innerBorderRadius(20, 14),
          ),
          child: Icon(person.icon, color: person.color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${person.label} ${(percent * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    '฿${formatter.format(amount)}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: AppColors.marbleWhite,
                    ).withTabularFigures(),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: LinearProgressIndicator(
                  value: percent,
                  minHeight: 4.5,
                  backgroundColor: AppColors.surfaceLight,
                  valueColor: AlwaysStoppedAnimation<Color>(person.color),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showResetDialog(BuildContext context) {
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: AppColors.borderDark, width: 2.2),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: AppTheme.innerBorderRadius(22, 16),
                border: Border.all(color: AppColors.borderDark, width: 1.5),
              ),
              child: const Icon(
                Icons.restart_alt_rounded,
                color: AppColors.mintioIndigo,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'รีเซ็ตข้อมูล',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        content: const Text(
          'ต้องการล้างข้อมูลเพื่อเริ่มทดสอบใหม่แบบใด?\n\n• สลิปตัวอย่าง: ดึงสลิปจำลอง 6 ใบมาให้ลองปัดใหม่\n• ล้างเกลี้ยง: ล้างสลิปและประวัติทั้งหมดเป็น 0',
          style: TextStyle(
            fontSize: 12.5,
            color: AppColors.textSecondary,
            height: 1.45,
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          Row(
            children: [
              Expanded(
                child: ArcadeButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    widget.onResetToSample?.call();
                  },
                  color: AppColors.surfaceLight,
                  shadowColor: AppColors.shadowDefault,
                  borderColor: AppColors.borderDark,
                  borderWidth: 1.8,
                  depth: 3.0,
                  borderRadius: AppTheme.innerBorderRadius(22, 14),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: const Text(
                    'สลิปตัวอย่าง',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ArcadeButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    widget.onClearAllData?.call();
                  },
                  color: const Color(0xFF241C20),
                  shadowColor: AppColors.shadowDefault,
                  borderColor: AppColors.expenseRedShadow.withValues(alpha: 0.6),
                  borderWidth: 1.8,
                  depth: 3.0,
                  borderRadius: AppTheme.innerBorderRadius(22, 14),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: const Text(
                    'ล้างเกลี้ยง (0 ใบ)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: AppColors.expenseRed,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
