import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../core/theme/app_theme.dart';
import '../models/expense_card_item.dart';

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
    final Map<int, Set<Color>> dailyCategoryColors = {};

    for (final t in monthTransactions) {
      final day = t.dateTime.day;
      if (t.isIncome) {
        monthIncome += t.amount;
        dailyIncome[day] = (dailyIncome[day] ?? 0) + t.amount;
      } else {
        monthExpense += t.amount;
        dailyExpense[day] = (dailyExpense[day] ?? 0) + t.amount;
        if (t.assignedCategory != null) {
          dailyCategoryColors.putIfAbsent(day, () => <Color>{}).add(t.assignedCategory!.color);
        }
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
                icon: const Icon(
                  Icons.chevron_left_rounded,
                  color: AppColors.mintioTextSecondary,
                  size: 26,
                ),
              ),
              Row(
                children: [
                  const Icon(
                    Icons.calendar_month_rounded,
                    color: AppColors.mintioIndigo,
                    size: 19,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    monthFormatter.format(_currentMonth),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: AppColors.mintioTextPrimary,
                    ),
                  ),
                ],
              ),
              IconButton(
                onPressed: _nextMonth,
                icon: const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.mintioTextSecondary,
                  size: 26,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Monthly Summary Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.mintioCard,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.mintioBorder, width: 1.2),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem(
                  title: 'รายรับ',
                  amount: '+฿${shortFormatter.format(monthIncome)}',
                  color: AppColors.mintioMint,
                ),
                Container(width: 1, height: 28, color: AppColors.mintioBorder),
                _buildSummaryItem(
                  title: 'รายจ่าย',
                  amount: '-฿${shortFormatter.format(monthExpense)}',
                  color: AppColors.mintioTextPrimary,
                ),
                Container(width: 1, height: 28, color: AppColors.mintioBorder),
                _buildSummaryItem(
                  title: 'คงเหลือ',
                  amount: '฿${shortFormatter.format(netBalance)}',
                  color: netBalance >= 0 ? AppColors.mintioMint : AppColors.expenseRed,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Weekday Labels (จ. อ. พ. พฤ. ศ. ส. อา.)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.mintioCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.mintioBorder, width: 1.2),
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

          // Calendar Grid Container
          Container(
            decoration: BoxDecoration(
              color: AppColors.mintioCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.mintioBorder, width: 1.2),
            ),
            padding: const EdgeInsets.all(8),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: totalCells,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 5,
                crossAxisSpacing: 5,
                childAspectRatio: 0.82,
              ),
              itemBuilder: (context, index) {
                final dayNumber = index - weekdayOffset + 1;
                final bool isValidDay = dayNumber >= 1 && dayNumber <= daysInMonth;

                if (!isValidDay) {
                  return Container(
                    decoration: BoxDecoration(
                      color: AppColors.mintioMidnight.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(10),
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
                final categoryDots = dailyCategoryColors[dayNumber] ?? {};

                return InkWell(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _selectedDate = thisDate);
                    widget.onDateSelected(thisDate);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.mintioIndigo.withValues(alpha: 0.22)
                          : (isToday ? AppColors.mintioCardElevated : AppColors.mintioMidnight),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.mintioIndigo
                            : (isToday ? AppColors.mintioIndigoLight.withValues(alpha: 0.6) : AppColors.mintioBorder.withValues(alpha: 0.6)),
                        width: isSelected ? 2 : (isToday ? 1.5 : 1),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
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
                                fontSize: 11.5,
                                fontWeight: isToday || isSelected
                                    ? FontWeight.w900
                                    : FontWeight.w700,
                                color: isToday
                                    ? AppColors.mintioIndigoLight
                                    : AppColors.mintioTextPrimary,
                              ),
                            ),
                            if (pendingCount > 0) ...[
                              const SizedBox(width: 2),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                                decoration: BoxDecoration(
                                  color: AppColors.mintioIndigo,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '$pendingCount',
                                  style: const TextStyle(
                                    fontSize: 8,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),

                        // Category Dots
                        if (categoryDots.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: categoryDots.take(3).map((col) {
                                return Container(
                                  width: 4,
                                  height: 4,
                                  margin: const EdgeInsets.symmetric(horizontal: 1),
                                  decoration: BoxDecoration(
                                    color: col,
                                    shape: BoxShape.circle,
                                  ),
                                );
                              }).toList(),
                            ),
                          ),

                        const Spacer(),

                        // Income (Mint Green)
                        if (dayInc > 0)
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              shortFormatter.format(dayInc),
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                color: AppColors.mintioMint,
                                height: 1.1,
                              ),
                            ),
                          ),

                        // Expense (Crisp White/Coral)
                        if (dayExp > 0)
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              shortFormatter.format(dayExp),
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                color: AppColors.mintioTextSecondary,
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
          const SizedBox(height: 16),
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
            fontWeight: FontWeight.w600,
            color: AppColors.mintioTextSecondary,
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
            fontWeight: FontWeight.w700,
            color: isWeekend ? AppColors.mintioCoral : AppColors.mintioTextSecondary,
          ),
        ),
      ),
    );
  }
}
