import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../core/theme/app_theme.dart';
import '../models/expense_card_item.dart';
import 'arcade_button.dart';
import 'arcade_card.dart';

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
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: AppColors.borderDark, width: 2.5),
          left: BorderSide(color: AppColors.borderDark, width: 2.5),
          right: BorderSide(color: AppColors.borderDark, width: 2.5),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          const SizedBox(height: 12),
          Container(
            width: 48,
            height: 5,
            decoration: BoxDecoration(
              color: AppColors.borderDark.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 12),

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
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'สรุปบันทึกการเงินประจำวัน',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Income / Expense Summary Banner (Wallet Story style)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                // Income Badge
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.emerald.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.emerald, width: 1.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'รายรับ',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.emerald,
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
                            color: AppColors.emerald,
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
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.vaultTributum.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.vaultTributum, width: 1.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'รายจ่าย',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.vaultTributum,
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
                            color: AppColors.vaultTributum,
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
              child: ArcadeCard(
                backgroundColor: AppColors.gold.withValues(alpha: 0.15),
                borderColor: AppColors.gold,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                              fontWeight: FontWeight.w900,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const Text(
                            'แตะเพื่อเริ่มปัดเคลียร์ยอดของวันนี้นี้',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (widget.onSwipePending != null)
                      ArcadeButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          widget.onSwipePending!();
                        },
                        label: 'ปัดเลย',
                        backgroundColor: AppColors.gold,
                        textColor: Colors.black,
                        height: 34,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
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
                        Icon(Icons.inbox_rounded, size: 48, color: AppColors.textSecondary),
                        SizedBox(height: 8),
                        Text(
                          'ไม่มีรายการในวันนี้',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                    physics: const BouncingScrollPhysics(),
                    itemCount: displayedList.length,
                    separatorBuilder: (_, index) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = displayedList[index];
                      final isIncome = item.isIncome;
                      final cat = item.assignedCategory;

                      return ArcadeCard(
                        padding: const EdgeInsets.all(12),
                        borderColor: isIncome
                            ? AppColors.emerald.withValues(alpha: 0.5)
                            : (cat?.color.withValues(alpha: 0.5) ?? AppColors.borderDark),
                        child: Row(
                          children: [
                            // Category Icon / Bank Circle
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: isIncome
                                    ? AppColors.emerald.withValues(alpha: 0.15)
                                    : (cat?.bgColor ?? item.bankColor.withValues(alpha: 0.15)),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isIncome
                                      ? AppColors.emerald
                                      : (cat?.color ?? item.bankColor),
                                  width: 1.5,
                                ),
                              ),
                              child: Icon(
                                isIncome
                                    ? Icons.arrow_downward_rounded
                                    : (cat?.icon ?? Icons.receipt_long_rounded),
                                color: isIncome
                                    ? AppColors.emerald
                                    : (cat?.color ?? item.bankColor),
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.receiverName.isNotEmpty
                                        ? item.receiverName
                                        : (isIncome ? 'รายรับ' : 'รายการใช้จ่าย'),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      if (item.note != null && item.note!.isNotEmpty) ...[
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 7,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.background,
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(
                                              color: AppColors.borderDark,
                                              width: 1,
                                            ),
                                          ),
                                          child: Text(
                                            item.note!,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                      ],
                                      Text(
                                        timeFormatter.format(item.dateTime),
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // Amount & Delete
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${isIncome ? '+' : '-'}฿${currencyFormatter.format(item.amount)}',
                                  style: TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w900,
                                    color: isIncome
                                        ? AppColors.emerald
                                        : AppColors.vaultTributum,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                InkWell(
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    widget.onDeleteItem(item);
                                    setState(() {});
                                  },
                                  child: const Padding(
                                    padding: EdgeInsets.all(2),
                                    child: Icon(
                                      Icons.delete_outline_rounded,
                                      size: 17,
                                      color: AppColors.textSecondary,
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
              color: AppColors.surface,
              border: Border(
                top: BorderSide(color: AppColors.borderDark, width: 1.5),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: ArcadeButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      widget.onAddIncome();
                    },
                    label: '+ รายรับ',
                    icon: Icons.add_circle_outline_rounded,
                    backgroundColor: AppColors.emerald,
                    shadowColor: const Color(0xFF0D6832),
                    textColor: Colors.white,
                    height: 44,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ArcadeButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      widget.onAddExpense();
                    },
                    label: '+ รายจ่าย',
                    icon: Icons.remove_circle_outline_rounded,
                    backgroundColor: AppColors.vaultTributum,
                    shadowColor: AppColors.vaultTributumShadow,
                    textColor: Colors.white,
                    height: 44,
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
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.gold : AppColors.background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderDark, width: 1.5),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
            color: isSelected ? Colors.black : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
