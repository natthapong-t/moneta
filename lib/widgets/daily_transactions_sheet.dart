import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../core/theme/app_theme.dart';
import '../models/expense_card_item.dart';

class DailyTransactionsSheet extends StatefulWidget {
  final DateTime date;
  final List<ExpenseCardItem> transactions;
  final List<ExpenseCardItem> pendingSlipsOnDate;
  final Function(ExpenseCardItem item) onDeleteItem;
  final VoidCallback onAddIncome;
  final VoidCallback onAddExpense;
  final VoidCallback? onSwipePending;

  const DailyTransactionsSheet({
    super.key,
    required this.date,
    required this.transactions,
    required this.pendingSlipsOnDate,
    required this.onDeleteItem,
    required this.onAddIncome,
    required this.onAddExpense,
    this.onSwipePending,
  });

  static Future<void> show({
    required BuildContext context,
    required DateTime date,
    required List<ExpenseCardItem> allCategorized,
    required List<ExpenseCardItem> allPending,
    required Function(ExpenseCardItem item) onDeleteItem,
    required VoidCallback onAddIncome,
    required VoidCallback onAddExpense,
    VoidCallback? onSwipePending,
  }) {
    final dailyCategorized = allCategorized.where((c) {
      return c.dateTime.year == date.year &&
          c.dateTime.month == date.month &&
          c.dateTime.day == date.day;
    }).toList();

    final dailyPending = allPending.where((p) {
      return p.dateTime.year == date.year &&
          p.dateTime.month == date.month &&
          p.dateTime.day == date.day;
    }).toList();

    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DailyTransactionsSheet(
        date: date,
        transactions: dailyCategorized,
        pendingSlipsOnDate: dailyPending,
        onDeleteItem: onDeleteItem,
        onAddIncome: onAddIncome,
        onAddExpense: onAddExpense,
        onSwipePending: onSwipePending,
      ),
    );
  }

  @override
  State<DailyTransactionsSheet> createState() => _DailyTransactionsSheetState();
}

class _DailyTransactionsSheetState extends State<DailyTransactionsSheet> {
  int _activeFilter = 0; // 0 = ทั้งหมด, 1 = รายจ่าย, 2 = รายรับ

  @override
  Widget build(BuildContext context) {
    final dateFormatter = DateFormat('d MMMM yyyy', 'th_TH');
    final timeFormatter = DateFormat('HH:mm น.', 'th_TH');
    final currencyFormatter = NumberFormat('#,##0.00', 'th_TH');

    double totalIncome = 0;
    double totalExpense = 0;

    for (final item in widget.transactions) {
      if (item.isIncome) {
        totalIncome += item.amount;
      } else {
        totalExpense += item.amount;
      }
    }

    final displayedList = widget.transactions.where((item) {
      if (_activeFilter == 1) return !item.isIncome;
      if (_activeFilter == 2) return item.isIncome;
      return true;
    }).toList();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: AppColors.mintioCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: AppColors.mintioBorder, width: 1.5),
          left: BorderSide(color: AppColors.mintioBorder, width: 1.5),
          right: BorderSide(color: AppColors.mintioBorder, width: 1.5),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          const SizedBox(height: 14),
          Container(
            width: 42,
            height: 4.5,
            decoration: BoxDecoration(
              color: AppColors.mintioTextMuted.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 14),

          // Header Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dateFormatter.format(widget.date),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppColors.mintioTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'สรุปบันทึกการเงินประจำวัน',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.mintioTextSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, color: AppColors.mintioTextSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Income / Expense Summary Banner
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                // Income Badge
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                    decoration: BoxDecoration(
                      color: AppColors.mintioMint.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.mintioMint.withValues(alpha: 0.35),
                        width: 1.2,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'รายรับ',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.mintioMint,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '+฿${currencyFormatter.format(totalIncome)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: AppColors.mintioMint,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Expense Badge
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                    decoration: BoxDecoration(
                      color: AppColors.mintioMidnight,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.mintioBorder,
                        width: 1.2,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'รายจ่าย',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.mintioTextSecondary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '-฿${currencyFormatter.format(totalExpense)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: AppColors.mintioTextPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Filter Segmented Tabs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                _buildFilterTab(0, 'ทั้งหมด (${widget.transactions.length})'),
                const SizedBox(width: 8),
                _buildFilterTab(1, 'รายจ่าย (${widget.transactions.where((i) => !i.isIncome).length})'),
                const SizedBox(width: 8),
                _buildFilterTab(2, 'รายรับ (${widget.transactions.where((i) => i.isIncome).length})'),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Pending Slips Banner (if any)
          if (widget.pendingSlipsOnDate.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.mintioMidnight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.mintioIndigo.withValues(alpha: 0.5),
                    width: 1.2,
                  ),
                ),
                child: Row(
                  children: [
                    const Text('🎴', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'มีสลิปของวันนี้รอปัด ${widget.pendingSlipsOnDate.length} ใบ',
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.mintioTextPrimary,
                            ),
                          ),
                          const Text(
                            'แตะเพื่อเริ่มปัดเคลียร์ยอดของวันนี้',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.mintioTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (widget.onSwipePending != null)
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          widget.onSwipePending!();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.mintioIndigo,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'ปัดเลย',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

          // Transactions List
          Expanded(
            child: displayedList.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(
                          Icons.inbox_rounded,
                          size: 48,
                          color: AppColors.mintioTextMuted,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'ไม่มีรายการในวันนี้',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.mintioTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                    physics: const BouncingScrollPhysics(),
                    itemCount: displayedList.length,
                    separatorBuilder: (_, index) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = displayedList[index];
                      final isIncome = item.isIncome;
                      final cat = item.assignedCategory;
                      final person = item.targetPerson;

                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.mintioCardElevated,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.mintioBorder,
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          children: [
                            // Category Icon / Bank Circle
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: isIncome
                                    ? AppColors.mintioMint.withValues(alpha: 0.16)
                                    : (cat?.color.withValues(alpha: 0.16) ?? item.bankColor.withValues(alpha: 0.16)),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isIncome
                                      ? AppColors.mintioMint.withValues(alpha: 0.4)
                                      : (cat?.color.withValues(alpha: 0.4) ?? item.bankColor),
                                  width: 1.2,
                                ),
                              ),
                              child: Icon(
                                isIncome
                                    ? Icons.arrow_downward_rounded
                                    : (cat?.icon ?? Icons.receipt_long_rounded),
                                color: isIncome
                                    ? AppColors.mintioMint
                                    : (cat?.color ?? item.bankColor),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          item.receiverName.isNotEmpty
                                              ? item.receiverName
                                              : (isIncome ? 'รายรับ' : 'รายการใช้จ่าย'),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.mintioTextPrimary,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      // Target Person Pill Badge
                                      if (!isIncome)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: person.color.withValues(alpha: 0.16),
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(
                                              color: person.color.withValues(alpha: 0.35),
                                              width: 1,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(person.icon, size: 9, color: person.color),
                                              const SizedBox(width: 2.5),
                                              Text(
                                                person.label,
                                                style: TextStyle(
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.bold,
                                                  color: person.color,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Row(
                                    children: [
                                      if (item.note != null && item.note!.isNotEmpty) ...[
                                        Text(
                                          '${item.note!} • ',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 10.5,
                                            color: AppColors.mintioTextSecondary,
                                          ),
                                        ),
                                      ],
                                      Text(
                                        timeFormatter.format(item.dateTime),
                                        style: const TextStyle(
                                          fontSize: 10.5,
                                          color: AppColors.mintioTextMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Amount & Delete
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${isIncome ? '+' : '-'}฿${currencyFormatter.format(item.amount)}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                    color: isIncome
                                        ? AppColors.mintioMint
                                        : AppColors.mintioTextPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                InkWell(
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    widget.onDeleteItem(item);
                                    setState(() {});
                                  },
                                  borderRadius: BorderRadius.circular(8),
                                  child: const Padding(
                                    padding: EdgeInsets.all(3),
                                    child: Icon(
                                      Icons.delete_outline_rounded,
                                      size: 16,
                                      color: AppColors.mintioTextMuted,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),

          // Bottom Action Row
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            decoration: const BoxDecoration(
              color: AppColors.mintioCard,
              border: Border(
                top: BorderSide(color: AppColors.mintioBorder, width: 1.2),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      widget.onAddIncome();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.mintioMint,
                      foregroundColor: Colors.black,
                      elevation: 0,
                      minimumSize: const Size.fromHeight(46),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.add_circle_outline_rounded, size: 18, color: Colors.black),
                        SizedBox(width: 6),
                        Text(
                          '+ รายรับ',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      widget.onAddExpense();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.mintioCardElevated,
                      foregroundColor: AppColors.mintioTextPrimary,
                      elevation: 0,
                      side: const BorderSide(color: AppColors.mintioBorder, width: 1.2),
                      minimumSize: const Size.fromHeight(46),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.add_circle_outline_rounded, size: 18, color: AppColors.mintioCoral),
                        SizedBox(width: 6),
                        Text(
                          '+ รายจ่าย',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.mintioTextPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTab(int index, String label) {
    final isSelected = _activeFilter == index;
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _activeFilter = index);
      },
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.mintioIndigo : AppColors.mintioMidnight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.mintioIndigo : AppColors.mintioBorder,
            width: 1.2,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.mintioTextSecondary,
          ),
        ),
      ),
    );
  }
}
