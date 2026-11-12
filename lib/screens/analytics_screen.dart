import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../core/constants/categories.dart';
import '../core/theme/app_theme.dart';
import '../models/expense_card_item.dart';
import '../widgets/arcade_button.dart';
import '../widgets/arcade_card.dart';
import '../widgets/arcade_progress_bar.dart';
import '../widgets/living_creature_widget.dart';

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
    final now = DateTime.now();

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

    final double totalCashFlow = totalIncome + totalExpense;
    final double incomePercent = totalCashFlow > 0 ? (totalIncome / totalCashFlow) : 0.0;
    final double expensePercent = totalCashFlow > 0 ? (totalExpense / totalCashFlow) : 0.0;

    final double budgetPercent = widget.monthlyBudget > 0
        ? (totalExpense / widget.monthlyBudget).clamp(0.0, 1.0)
        : 0.0;

    // Mintio 7-day Spline Data Calculation (Current 7 days vs Previous 7 days)
    final List<double> currentWeekDays = List.filled(7, 0.0);
    final List<double> prevWeekDays = List.filled(7, 0.0);
    final mondayThisWeek = now.subtract(Duration(days: now.weekday - 1));
    final mondayPrevWeek = mondayThisWeek.subtract(const Duration(days: 7));

    double past7DaysTotal = 0;

    for (final item in widget.transactions) {
      if (item.isIncome) continue;
      final diffDays = now.difference(item.dateTime).inDays;
      if (diffDays >= 0 && diffDays < 7) {
        past7DaysTotal += item.amount;
      }

      // Current week index (0=Mon .. 6=Sun)
      final diffCurrent = item.dateTime.difference(mondayThisWeek).inDays;
      if (diffCurrent >= 0 && diffCurrent < 7) {
        currentWeekDays[diffCurrent] += item.amount;
      }

      // Previous week index
      final diffPrev = item.dateTime.difference(mondayPrevWeek).inDays;
      if (diffPrev >= 0 && diffPrev < 7) {
        prevWeekDays[diffPrev] += item.amount;
      }
    }

    // Days remaining in month
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0).day;
    final daysRemaining = math.max(0, lastDayOfMonth - now.day);
    final double sevenDaysAverage = past7DaysTotal / 7;
    final double monthlyAverage = now.day > 0 ? (totalExpense / now.day) * 30 : 0.0;

    // Top spending category
    ExpenseCategory? topCategory;
    double maxCatAmount = 0;
    categorySums.forEach((id, amount) {
      if (amount > maxCatAmount) {
        maxCatAmount = amount;
        topCategory = ExpenseCategory.defaultCorners.firstWhere((c) => c.id == id);
      }
    });

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
                        'ข้อมูลรายจ่าย',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: AppColors.marbleWhite,
                        ),
                      ),
                      Text(
                        'Interesting Insights & Analytics',
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
                      color: AppColors.mintioIndigo,
                      size: 22,
                    ),
                    tooltip: 'ตั้งค่างบประมาณ',
                    onPressed: () => _showBudgetDialog(context),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Mintio Card 1: ยอดรายจ่ายรายเดือนที่ตั้งไว้ (Monthly Budget Card)
              ArcadeCard(
                borderColor: AppColors.borderDark,
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'ยอดรายจ่ายรายเดือนที่ตั้งไว้',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        InkWell(
                          onTap: () => _showBudgetDialog(context),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            child: const Icon(
                              Icons.edit_rounded,
                              size: 17,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '฿${shortFormatter.format(widget.monthlyBudget)}',
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                            color: AppColors.marbleWhite,
                          ),
                        ),
                        Text(
                          'เหลืออีก $daysRemaining วัน',
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Mintio Card 2: Dual-Spline 7-Day Chart (Current Week vs Previous Week)
              ArcadeCard(
                borderColor: AppColors.borderDark,
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          past7DaysTotal > 0
                              ? 'Past 7 days: ฿${shortFormatter.format(past7DaysTotal)}'
                              : '7 วันที่ผ่านมา',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.mintioIndigo,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              'สัปดาห์นี้',
                              style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFF94A3B8),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              'ก่อนหน้า',
                              style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    if (past7DaysTotal == 0)
                      Container(
                        height: 140,
                        alignment: Alignment.center,
                        child: const Text(
                          'ยังไม่มีข้อมูลรายจ่าย',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    else
                      SizedBox(
                        height: 150,
                        child: CustomPaint(
                          size: const Size(double.infinity, 150),
                          painter: _SplineChartPainter(
                            currentWeek: currentWeekDays,
                            prevWeek: prevWeekDays,
                            selectedDayIndex: now.weekday - 1,
                            todayAmount: currentWeekDays[now.weekday - 1],
                          ),
                        ),
                      ),

                    const SizedBox(height: 8),
                    // Days of week row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text('จ.', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                        Text('อ.', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                        Text('พ.', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                        Text('พฤ.', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                        Text('ศ.', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                        Text('ส.', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                        Text('อา.', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Mintio Card 3 & 4: 4-Metric Grid
              Row(
                children: [
                  Expanded(
                    child: ArcadeCard(
                      borderColor: AppColors.borderDark,
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '7 วันใช้ไป',
                            style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            past7DaysTotal > 0 ? '฿${shortFormatter.format(past7DaysTotal)}' : '-',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: AppColors.marbleWhite,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ArcadeCard(
                      borderColor: AppColors.borderDark,
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'เฉลี่ยรายจ่ายใน 7 วัน',
                            style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            past7DaysTotal > 0 ? '~฿${shortFormatter.format(sevenDaysAverage)}' : '-',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: AppColors.marbleWhite,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: ArcadeCard(
                      borderColor: AppColors.borderDark,
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'เดือนนี้ใช้ไป',
                            style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            totalExpense > 0 ? '฿${shortFormatter.format(totalExpense)}' : '-',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: AppColors.marbleWhite,
                            ),
                          ),
                          Text(
                            '${(budgetPercent * 100).toStringAsFixed(0)}% ของงบ',
                            style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ArcadeCard(
                      borderColor: AppColors.borderDark,
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'เฉลี่ยรายเดือน',
                            style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            monthlyAverage > 0 ? '฿${shortFormatter.format(monthlyAverage)}' : '-',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: AppColors.marbleWhite,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Mintio Top Spending Spotlight Card with Living Mascot
              if (topCategory != null)
                ArcadeCard(
                  borderColor: AppColors.borderDark,
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Top spending สัปดาห์นี้',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('แชร์ยอด ${topCategory!.thaiTitle} สำเร็จ!'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                            icon: const Icon(Icons.send_rounded, size: 18, color: AppColors.mintioIndigo),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                topCategory!.thaiTitle,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.marbleWhite,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${((maxCatAmount / (totalExpense > 0 ? totalExpense : 1.0)) * 100).toStringAsFixed(0)}% ของรายจ่ายทั้งหมด',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          LivingCreatureWidget(
                            shape: CreatureShape.creditCard,
                            size: 70,
                            primaryColor: topCategory!.color,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 14),

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

              // Category Breakdown Title
              const Text(
                'สัดส่วนรายจ่ายตามหมวดหมู่',
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
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedPeriod = index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.mintioIndigo : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF3B48D8) : AppColors.borderDark,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: isSelected ? Colors.white : AppColors.textSecondary,
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
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              percent,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
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
    final percent = (spent / total).clamp(0.0, 1.0);
    return ArcadeCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: category.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(category.icon, size: 16, color: category.color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  category.thaiTitle,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                '฿ ${currencyFormatter.format(spent)}',
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w900,
                  color: AppColors.marbleWhite,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ArcadeProgressBar(value: percent, height: 7, progressColor: category.color),
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
            backgroundColor: AppColors.mintioIndigo,
            shadowColor: const Color(0xFF3B48D8),
            borderColor: const Color(0xFF3B48D8),
            textColor: Colors.white,
            label: 'บันทึก',
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 16),
          ),
        ],
      ),
    );
  }
}

/// Dual-Spline Bezier Chart Painter (Current Week vs Previous Week)
class _SplineChartPainter extends CustomPainter {
  final List<double> currentWeek;
  final List<double> prevWeek;
  final int selectedDayIndex;
  final double todayAmount;

  _SplineChartPainter({
    required this.currentWeek,
    required this.prevWeek,
    required this.selectedDayIndex,
    required this.todayAmount,
  });

  @override
  void paint(Canvas canvas, Size size) {
    double maxVal = 100.0;
    for (final v in currentWeek) {
      if (v > maxVal) maxVal = v;
    }
    for (final v in prevWeek) {
      if (v > maxVal) maxVal = v;
    }
    maxVal *= 1.2; // Headroom

    final stepX = size.width / 6;

    // Draw Previous Week (Muted Grey line)
    final prevPoints = <Offset>[];
    for (int i = 0; i < 7; i++) {
      final x = i * stepX;
      final y = size.height - (prevWeek[i] / maxVal) * (size.height - 24) - 12;
      prevPoints.add(Offset(x, y));
    }

    final prevPath = _createSplinePath(prevPoints);
    final prevPaint = Paint()
      ..color = const Color(0xFF64748B).withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(prevPath, prevPaint);

    // Draw Current Week (Glowing Electric Indigo line)
    final currentPoints = <Offset>[];
    for (int i = 0; i < 7; i++) {
      final x = i * stepX;
      final y = size.height - (currentWeek[i] / maxVal) * (size.height - 24) - 12;
      currentPoints.add(Offset(x, y));
    }

    final currentPath = _createSplinePath(currentPoints);
    final currentPaint = Paint()
      ..color = AppColors.mintioIndigo
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(currentPath, currentPaint);

    // Highlight Selected Node (Today)
    if (selectedDayIndex >= 0 && selectedDayIndex < currentPoints.length) {
      final activePoint = currentPoints[selectedDayIndex];

      // Glow circle
      final glowPaint = Paint()
        ..color = AppColors.mintioIndigo.withValues(alpha: 0.35)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(activePoint, 10, glowPaint);

      // Core circle
      final corePaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(activePoint, 5, corePaint);

      final borderPaint = Paint()
        ..color = AppColors.mintioIndigo
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;
      canvas.drawCircle(activePoint, 5, borderPaint);

      // Tooltip above active node
      if (todayAmount > 0) {
        final textSpan = TextSpan(
          text: '฿${todayAmount.toStringAsFixed(0)}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w900,
          ),
        );
        final tp = TextPainter(text: textSpan, textDirection: ui.TextDirection.ltr);
        tp.layout();
        final tooltipOffset = Offset(
          (activePoint.dx - tp.width / 2).clamp(4.0, size.width - tp.width - 4.0),
          math.max(2.0, activePoint.dy - 24.0),
        );

        final bgRect = RRect.fromRectAndRadius(
          Rect.fromLTWH(
            tooltipOffset.dx - 6,
            tooltipOffset.dy - 3,
            tp.width + 12,
            tp.height + 6,
          ),
          const Radius.circular(8),
        );
        canvas.drawRRect(bgRect, Paint()..color = const Color(0xFF1E1F26));
        tp.paint(canvas, tooltipOffset);
      }
    }
  }

  Path _createSplinePath(List<Offset> points) {
    final path = Path();
    if (points.isEmpty) return path;
    path.moveTo(points[0].dx, points[0].dy);

    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final controlX = (p0.dx + p1.dx) / 2;
      path.cubicTo(controlX, p0.dy, controlX, p1.dy, p1.dx, p1.dy);
    }
    return path;
  }

  @override
  bool shouldRepaint(covariant _SplineChartPainter oldDelegate) => true;
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
