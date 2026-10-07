import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../core/theme/app_theme.dart';
import '../models/expense_card_item.dart';
import 'arcade_card.dart';

class ArcadeCalendarView extends StatefulWidget {
  final List<ExpenseCardItem> transactions;
  final List<ExpenseCardItem> pendingCards;
  final Function(DateTime date) onDateSelected;

  const ArcadeCalendarView({
    super.key,
    required this.transactions,
    required this.pendingCards,
    required this.onDateSelected,
  });

  @override
  State<ArcadeCalendarView> createState() => _ArcadeCalendarViewState();
}

class _ArcadeCalendarViewState extends State<ArcadeCalendarView> {
  late DateTime _currentMonth;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _currentMonth = DateTime(now.year, now.month, 1);
    _selectedDate = DateTime(now.year, now.month, now.day);
  }

  void _prevMonth() {
    HapticFeedback.selectionClick();
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    HapticFeedback.selectionClick();
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final monthFormatter = DateFormat('MMMM yyyy', 'th_TH');
    final shortFormatter = NumberFormat('#,##0', 'th_TH');

    // Filter transactions for this month
    final monthTransactions = widget.transactions.where((t) {
      return t.dateTime.year == _currentMonth.year &&
          t.dateTime.month == _currentMonth.month;
    }).toList();

    double monthIncome = 0;
    double monthExpense = 0;

    // Daily buckets for this month
    final Map<int, double> dailyIncome = {};
    final Map<int, double> dailyExpense = {};
    final Map<int, int> dailyPendingCount = {};

    for (final t in monthTransactions) {
      final day = t.dateTime.day;
      if (t.isIncome) {
        monthIncome += t.amount;
        dailyIncome[day] = (dailyIncome[day] ?? 0) + t.amount;
      } else {
        monthExpense += t.amount;
        dailyExpense[day] = (dailyExpense[day] ?? 0) + t.amount;
      }
    }

    for (final p in widget.pendingCards) {
      if (p.dateTime.year == _currentMonth.year &&
          p.dateTime.month == _currentMonth.month) {
        final day = p.dateTime.day;
        dailyPendingCount[day] = (dailyPendingCount[day] ?? 0) + 1;
      }
    }

    final double netBalance = monthIncome - monthExpense;

    // Calendar math:
    final firstDayOfMonth = _currentMonth;
    final daysInMonth = DateTime(
      _currentMonth.year,
      _currentMonth.month + 1,
      0,
    ).day;

    // Monday as first day of week (1 = Monday, 7 = Sunday)
    final int weekdayOffset = (firstDayOfMonth.weekday - 1) % 7;
    final int totalCells = ((weekdayOffset + daysInMonth + 6) ~/ 7) * 7;

    final now = DateTime.now();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Month Header Switcher
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: _prevMonth,
                icon: const Icon(Icons.chevron_left_rounded, color: AppColors.textPrimary, size: 28),
              ),
              Row(
                children: [
                  const Icon(Icons.calendar_month_rounded, color: AppColors.gold, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    monthFormatter.format(_currentMonth),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              IconButton(
                onPressed: _nextMonth,
                icon: const Icon(Icons.chevron_right_rounded, color: AppColors.textPrimary, size: 28),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Monthly Summary Banner (Wallet Story style)
          ArcadeCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem(
                  title: 'รายรับ',
                  amount: '+฿${shortFormatter.format(monthIncome)}',
                  color: AppColors.emerald,
                ),
                Container(width: 1.5, height: 32, color: AppColors.borderDark),
                _buildSummaryItem(
                  title: 'รายจ่าย',
                  amount: '-฿${shortFormatter.format(monthExpense)}',
                  color: AppColors.vaultTributum,
                ),
                Container(width: 1.5, height: 32, color: AppColors.borderDark),
                _buildSummaryItem(
                  title: 'คงเหลือ',
                  amount: '฿${shortFormatter.format(netBalance)}',
                  color: netBalance >= 0 ? AppColors.gold : AppColors.vaultTributum,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Weekday Labels (จ. อ. พ. พฤ. ศ. ส. อา.)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderDark, width: 1.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: const [
                _WeekdayLabel('จ.'),
                _WeekdayLabel('อ.'),
                _WeekdayLabel('พ.'),
                _WeekdayLabel('พฤ.'),
                _WeekdayLabel('ศ.'),
                _WeekdayLabel('ส.'),
                _WeekdayLabel('อา.', isWeekend: true),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Calendar Grid
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.borderDark, width: 2),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.shadowDefault,
                  offset: Offset(0, 4),
                  blurRadius: 0,
                ),
              ],
            ),
            padding: const EdgeInsets.all(6),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: totalCells,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
                childAspectRatio: 0.82,
              ),
              itemBuilder: (context, index) {
                final dayNumber = index - weekdayOffset + 1;
                final bool isValidDay = dayNumber >= 1 && dayNumber <= daysInMonth;

                if (!isValidDay) {
                  return Container(
                    decoration: BoxDecoration(
                      color: AppColors.background.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  );
                }

                final thisDate = DateTime(_currentMonth.year, _currentMonth.month, dayNumber);
                final bool isToday = now.year == thisDate.year &&
                    now.month == thisDate.month &&
                    now.day == thisDate.day;
                final bool isSelected = _selectedDate != null &&
                    _selectedDate!.year == thisDate.year &&
                    _selectedDate!.month == thisDate.month &&
                    _selectedDate!.day == thisDate.day;

                final dayInc = dailyIncome[dayNumber] ?? 0;
                final dayExp = dailyExpense[dayNumber] ?? 0;
                final pendingCount = dailyPendingCount[dayNumber] ?? 0;

                return InkWell(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _selectedDate = thisDate);
                    widget.onDateSelected(thisDate);
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.gold.withValues(alpha: 0.2)
                          : (isToday ? AppColors.surface : AppColors.background),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.gold
                            : (isToday ? AppColors.vaultQuadriga : AppColors.borderDark.withValues(alpha: 0.4)),
                        width: isSelected || isToday ? 2 : 1,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 3),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Day Number & Pending Badge
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '$dayNumber',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isToday || isSelected
                                    ? FontWeight.w900
                                    : FontWeight.w700,
                                color: isToday
                                    ? AppColors.vaultQuadriga
                                    : AppColors.textPrimary,
                              ),
                            ),
                            if (pendingCount > 0) ...[
                              const SizedBox(width: 2),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                                decoration: BoxDecoration(
                                  color: AppColors.gold,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '$pendingCount',
                                  style: const TextStyle(
                                    fontSize: 8,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const Spacer(),

                        // Income (Green)
                        if (dayInc > 0)
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              shortFormatter.format(dayInc),
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                color: AppColors.emerald,
                                height: 1.1,
                              ),
                            ),
                          ),

                        // Expense (Red)
                        if (dayExp > 0)
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              shortFormatter.format(dayExp),
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                color: AppColors.vaultTributum,
                                height: 1.1,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem({
    required String title,
    required String amount,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          amount,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _WeekdayLabel extends StatelessWidget {
  final String text;
  final bool isWeekend;

  const _WeekdayLabel(this.text, {this.isWeekend = false});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
            color: isWeekend ? AppColors.vaultTributum : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
