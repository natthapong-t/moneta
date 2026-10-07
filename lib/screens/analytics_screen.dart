import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../core/constants/categories.dart';
import '../core/theme/app_theme.dart';
import '../models/expense_card_item.dart';
import '../widgets/arcade_button.dart';
import '../widgets/arcade_card.dart';
import '../widgets/arcade_progress_bar.dart';

class AnalyticsScreen extends StatefulWidget {
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
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  int _selectedPeriod = 0; // 0 = เดือนนี้, 1 = ทั้งหมด
  late DateTime _currentMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _currentMonth = DateTime(now.year, now.month, 1);
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat('#,##0.00', 'th_TH');
    final shortFormatter = NumberFormat('#,##0', 'th_TH');
    final monthFormatter = DateFormat('MMMM yyyy', 'th_TH');

    // Filter by period
    final filtered = widget.transactions.where((item) {
      if (_selectedPeriod == 0) {
        return item.dateTime.year == _currentMonth.year &&
            item.dateTime.month == _currentMonth.month;
      }
      return true;
    }).toList();

    double totalIncome = 0;
    double totalExpense = 0;
    int incomeCount = 0;
    int expenseCount = 0;

    final Map<String, double> categorySums = {
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

    for (final item in filtered) {
      if (item.isIncome) {
        totalIncome += item.amount;
        incomeCount++;
      } else {
        totalExpense += item.amount;
        expenseCount++;
        if (item.assignedCategory != null) {
          final id = item.assignedCategory!.id;
          categorySums[id] = (categorySums[id] ?? 0.0) + item.amount;
          categoryCounts[id] = (categoryCounts[id] ?? 0) + 1;
        }
      }
    }

    final double netSavings = totalIncome - totalExpense;
    final double totalCashFlow = totalIncome + totalExpense;
    final double incomePercent = totalCashFlow > 0 ? (totalIncome / totalCashFlow) : 0.0;
    final double expensePercent = totalCashFlow > 0 ? (totalExpense / totalCashFlow) : 0.0;

    final double budgetPercent = widget.monthlyBudget > 0
        ? (totalExpense / widget.monthlyBudget).clamp(0.0, 1.0)
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
              // Top Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'สรุปและสถิติ',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Financial Analytics & Ratios',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.tune_rounded,
                      color: AppColors.gold,
                      size: 22,
                    ),
                    tooltip: 'ตั้งค่างบประมาณ',
                    onPressed: () => _showBudgetDialog(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Period Switcher Pills
              Row(
                children: [
                  _buildPeriodPill(0, monthFormatter.format(_currentMonth)),
                  const SizedBox(width: 8),
                  _buildPeriodPill(1, 'ข้อมูลทั้งหมด'),
                ],
              ),
              const SizedBox(height: 16),

              // Ratio Donut Chart Card (Wallet Story Style)
              ArcadeCard(
                borderColor: AppColors.borderDark,
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'สัดส่วนรายรับ vs รายจ่าย',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          '${incomeCount + expenseCount} รายการ',
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Donut Chart Graphic & Center Percentage
                    SizedBox(
                      height: 160,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CustomPaint(
                            size: const Size(160, 160),
                            painter: _DonutChartPainter(
                              incomePercent: incomePercent,
                              expensePercent: expensePercent,
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${(expensePercent * 100).toStringAsFixed(1)}%',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.vaultTributum,
                                ),
                              ),
                              const Text(
                                'สัดส่วนรายจ่าย',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Ratio Legends
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildLegendItem(
                          color: AppColors.emerald,
                          title: 'รายรับ',
                          percent: '${(incomePercent * 100).toStringAsFixed(1)}%',
                        ),
                        _buildLegendItem(
                          color: AppColors.vaultTributum,
                          title: 'รายจ่าย',
                          percent: '${(expensePercent * 100).toStringAsFixed(1)}%',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Income & Expense Breakdown Cards (Wallet Story Screenshot 4-5)
              Row(
                children: [
                  // Income Card
                  Expanded(
                    child: ArcadeCard(
                      borderColor: AppColors.emerald.withValues(alpha: 0.6),
                      shadowColor: AppColors.emeraldShadow.withValues(alpha: 0.3),
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.arrow_downward_rounded, size: 16, color: AppColors.emerald),
                              SizedBox(width: 4),
                              Text(
                                'รายรับ',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.emerald,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$incomeCount รายการ',
                            style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 6),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              '+฿${shortFormatter.format(totalIncome)}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: AppColors.emerald,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Expense Card
                  Expanded(
                    child: ArcadeCard(
                      borderColor: AppColors.vaultTributum.withValues(alpha: 0.6),
                      shadowColor: AppColors.vaultTributumShadow.withValues(alpha: 0.3),
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.arrow_upward_rounded, size: 16, color: AppColors.vaultTributum),
                              SizedBox(width: 4),
                              Text(
                                'รายจ่าย',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.vaultTributum,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$expenseCount รายการ',
                            style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 6),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              '-฿${shortFormatter.format(totalExpense)}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: AppColors.vaultTributum,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Net Balance Card
              ArcadeCard(
                borderColor: AppColors.gold,
                shadowColor: AppColors.goldShadow.withValues(alpha: 0.35),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: const [
                        Text('🪙', style: TextStyle(fontSize: 18)),
                        SizedBox(width: 8),
                        Text(
                          'เงินคงเหลือสุทธิ',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '฿ ${currencyFormatter.format(netSavings)}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: netSavings >= 0 ? AppColors.gold : AppColors.vaultTributum,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Budget Progress Card
              ArcadeCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'เพดานงบประมาณเดือนนี้',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          'งบ ฿ ${shortFormatter.format(widget.monthlyBudget)}',
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ArcadeProgressBar(value: budgetPercent, height: 9),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'ใช้ไป ${(budgetPercent * 100).toStringAsFixed(1)}%',
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                        Text(
                          'เหลือใช้ได้ ฿ ${shortFormatter.format(math.max(0.0, widget.monthlyBudget - totalExpense))}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.emerald,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),

              // Category Breakdown Title
              const Text(
                'สัดส่วนรายจ่ายตามหมวดหมู่ (Category Share)',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),

              // Category Bars
              for (final cat in ExpenseCategory.defaultCorners) ...[
                _buildCategoryBar(
                  category: cat,
                  spent: categorySums[cat.id] ?? 0.0,
                  count: categoryCounts[cat.id] ?? 0,
                  total: totalExpense > 0 ? totalExpense : 1.0,
                  currencyFormatter: currencyFormatter,
                ),
                const SizedBox(height: 10),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodPill(int index, String label) {
    final isSelected = _selectedPeriod == index;
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedPeriod = index);
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.gold : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.goldShadow : AppColors.borderDark,
            width: 1.5,
          ),
          boxShadow: [
            if (isSelected)
              const BoxShadow(
                color: AppColors.goldShadow,
                offset: Offset(0, 2),
                blurRadius: 0,
              ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: isSelected ? Colors.black87 : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildLegendItem({
    required Color color,
    required String title,
    required String percent,
  }) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.borderDark, width: 1.2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          percent,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryBar({
    required ExpenseCategory category,
    required double spent,
    required int count,
    required double total,
    required NumberFormat currencyFormatter,
  }) {
    final double fraction = total > 0 ? (spent / total).clamp(0.0, 1.0) : 0.0;
    final int percent = (fraction * 100).round();

    return ArcadeCard(
      padding: const EdgeInsets.all(14),
      borderColor: category.color.withValues(alpha: 0.35),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: category.bgColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: category.color, width: 1.2),
                ),
                child: Icon(category.icon, color: category.color, size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.thaiTitle,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '$count รายการ',
                      style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '฿ ${currencyFormatter.format(spent)}',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w900,
                      color: category.color,
                    ),
                  ),
                  Text(
                    '$percent%',
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 7,
              backgroundColor: AppColors.surfaceLight,
              valueColor: AlwaysStoppedAnimation<Color>(category.color),
            ),
          ),
        ],
      ),
    );
  }

  void _showBudgetDialog(BuildContext context) {
    final controller = TextEditingController(
      text: widget.monthlyBudget.toStringAsFixed(0),
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppColors.borderDark, width: 2),
        ),
        title: const Text(
          'ตั้งค่างบประมาณรายเดือน',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17),
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          decoration: const InputDecoration(
            prefixText: '฿ ',
            border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(14))),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('ยกเลิก', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ArcadeButton(
            onPressed: () {
              final val = double.tryParse(controller.text.replaceAll(',', ''));
              if (val != null && val > 0) {
                widget.onUpdateBudget(val);
                Navigator.of(ctx).pop();
              }
            },
            backgroundColor: AppColors.gold,
            textColor: Colors.black87,
            label: 'บันทึก',
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 16),
          ),
        ],
      ),
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  final double incomePercent;
  final double expensePercent;

  _DonutChartPainter({
    required this.incomePercent,
    required this.expensePercent,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const strokeWidth = 24.0;

    final bgPaint = Paint()
      ..color = AppColors.surfaceLight
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius - strokeWidth / 2, bgPaint);

    if (incomePercent <= 0 && expensePercent <= 0) return;

    final rect = Rect.fromCircle(center: center, radius: radius - strokeWidth / 2);

    final incomePaint = Paint()
      ..color = AppColors.emerald
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final expensePaint = Paint()
      ..color = AppColors.vaultTributum
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Start from -pi / 2 (top)
    double startAngle = -math.pi / 2;

    // Draw Expense Arc
    final sweepExpense = expensePercent * 2 * math.pi;
    if (sweepExpense > 0.01) {
      canvas.drawArc(rect, startAngle, sweepExpense, false, expensePaint);
      startAngle += sweepExpense;
    }

    // Draw Income Arc
    final sweepIncome = incomePercent * 2 * math.pi;
    if (sweepIncome > 0.01) {
      canvas.drawArc(rect, startAngle, sweepIncome, false, incomePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) {
    return oldDelegate.incomePercent != incomePercent ||
        oldDelegate.expensePercent != expensePercent;
  }
}
