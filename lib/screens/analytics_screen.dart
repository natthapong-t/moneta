import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/constants/categories.dart';
import '../core/theme/app_theme.dart';
import '../models/expense_card_item.dart';
import '../widgets/arcade_card.dart';
import '../widgets/arcade_progress_bar.dart';

class AnalyticsScreen extends StatelessWidget {
  final List<ExpenseCardItem> transactions;
  final double monthlyBudget;
  final Function(double newBudget) onUpdateBudget;

  const AnalyticsScreen({
    super.key,
    required this.transactions,
    required this.monthlyBudget,
    required this.onUpdateBudget,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat('#,##0.00', 'th_TH');
    final shortFormatter = NumberFormat('#,##0', 'th_TH');

    final double totalSpent = transactions.fold(
      0.0,
      (sum, item) => sum + item.amount,
    );

    final Map<String, double> categorySums = {
      'food': 0.0,
      'transport': 0.0,
      'shopping': 0.0,
      'bills': 0.0,
    };

    for (final item in transactions) {
      if (item.assignedCategory != null) {
        final id = item.assignedCategory!.id;
        categorySums[id] = (categorySums[id] ?? 0.0) + item.amount;
      }
    }

    final double budgetPercent = monthlyBudget > 0
        ? (totalSpent / monthlyBudget).clamp(0.0, 1.0)
        : 0.0;

    // Daily average (over past 30 days or active days)
    final double dailyAvg = transactions.isNotEmpty
        ? totalSpent / 30.0
        : 0.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'รายงานคลังสภา (Senate Treasury)',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: AppColors.gold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.tune_rounded, color: AppColors.gold, size: 20),
                    tooltip: 'ตั้งค่างบประมาณ',
                    onPressed: () => _showBudgetDialog(context),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Total Spent Card
              ArcadeCard(
                borderColor: AppColors.gold.withValues(alpha: 0.35),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ยอดใช้จ่ายรวมทั้งสิ้น',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '฿ ${currencyFormatter.format(totalSpent)}',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: AppColors.gold,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricPill(
                            label: 'เฉลี่ยต่อวัน (30 วัน)',
                            value: '฿ ${shortFormatter.format(dailyAvg)}/วัน',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildMetricPill(
                            label: 'สัดส่วนต่องบ',
                            value: '${(budgetPercent * 100).toStringAsFixed(1)}%',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              // Senate Proclamation / Health Advice
              ArcadeCard(
                color: budgetPercent > 0.85
                    ? AppColors.waxSealRed.withValues(alpha: 0.1)
                    : const Color(0xFF10B981).withValues(alpha: 0.1),
                borderColor: budgetPercent > 0.85
                    ? AppColors.waxSealRed.withValues(alpha: 0.4)
                    : const Color(0xFF10B981).withValues(alpha: 0.4),
                shadowColor: budgetPercent > 0.85
                    ? AppColors.waxSealRed.withValues(alpha: 0.2)
                    : const Color(0xFF10B981).withValues(alpha: 0.2),
                depth: 2.5,
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      budgetPercent > 0.85
                          ? Icons.warning_amber_rounded
                          : Icons.verified_rounded,
                      color: budgetPercent > 0.85
                          ? AppColors.waxSealRed
                          : const Color(0xFF10B981),
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            budgetPercent > 0.85
                                ? 'แจ้งเตือน: ใกล้เต็มเพดานงบประมาณ!'
                                : 'สภาโรมัน: สถานะคลังหลวงแข็งแกร่ง',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: budgetPercent > 0.85
                                  ? AppColors.waxSealRed
                                  : const Color(0xFF047857),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            budgetPercent > 0.85
                                ? 'คุณใช้จ่ายไปแล้ว ${(budgetPercent * 100).toStringAsFixed(0)}% แนะนำลดค่าใช้จ่ายไม่จำเป็น'
                                : 'การควบคุมรายจ่ายอยู่ในเกณฑ์ยอดเยี่ยม มีเงินเหลือตามเป้าหมาย',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Category Breakdown Title
              const Text(
                'สัดส่วนรายจ่าย 4 เสาหลัก (Category Share)',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.marbleWhite,
                ),
              ),
              const SizedBox(height: 12),

              // Category Bars
              for (final cat in ExpenseCategory.defaultCorners) ...[
                _buildCategoryBar(
                  category: cat,
                  spent: categorySums[cat.id] ?? 0.0,
                  total: totalSpent > 0 ? totalSpent : 1.0,
                  currencyFormatter: currencyFormatter,
                ),
                const SizedBox(height: 12),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricPill({required String label, required String value}) {
    return ArcadeCard(
      color: AppColors.surfaceLight,
      borderColor: AppColors.border,
      depth: 2.0,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.marbleWhite,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBar({
    required ExpenseCategory category,
    required double spent,
    required double total,
    required NumberFormat currencyFormatter,
  }) {
    final double pct = (spent / total).clamp(0.0, 1.0);

    return ArcadeCard(
      padding: const EdgeInsets.all(14),
      borderColor: category.color.withValues(alpha: 0.35),
      shadowColor: category.shadowColor.withValues(alpha: 0.3),
      depth: 2.5,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(category.icon, size: 16, color: category.color),
                  const SizedBox(width: 8),
                  Text(
                    category.thaiTitle,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.marbleWhite,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Text(
                    '฿ ${currencyFormatter.format(spent)} ',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: category.color,
                    ),
                  ),
                  Text(
                    '(${(pct * 100).toStringAsFixed(1)}%)',
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          ArcadeProgressBar(
            value: pct,
            progressColor: category.color,
            height: 7,
          ),
        ],
      ),
    );
  }

  void _showBudgetDialog(BuildContext context) {
    final budgets = [10000.0, 15000.0, 20000.0, 30000.0, 50000.0];
    final shortFormatter = NumberFormat('#,##0', 'th_TH');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.gold),
        ),
        title: const Text(
          'ตั้งค่างบประมาณประจำเดือน',
          style: TextStyle(color: AppColors.gold, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: budgets.map((b) {
            final isSelected = (b - monthlyBudget).abs() < 1.0;
            return ListTile(
              title: Text(
                '฿ ${shortFormatter.format(b)} / เดือน',
                style: TextStyle(
                  color: isSelected ? AppColors.gold : AppColors.textPrimary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              trailing: isSelected
                  ? const Icon(Icons.check_circle_rounded, color: AppColors.gold)
                  : null,
              onTap: () {
                onUpdateBudget(b);
                Navigator.pop(ctx);
              },
            );
          }).toList(),
        ),
      ),
    );
  }
}
