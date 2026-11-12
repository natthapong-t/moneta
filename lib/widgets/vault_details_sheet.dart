import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../core/constants/categories.dart';
import '../core/theme/app_theme.dart';
import '../models/expense_card_item.dart';

class VaultDetailsSheet extends StatelessWidget {
  final ExpenseCategory category;
  final List<ExpenseCardItem> items;
  final Function(ExpenseCardItem item) onRestoreItem;

  const VaultDetailsSheet({
    super.key,
    required this.category,
    required this.items,
    required this.onRestoreItem,
  });

  static void show({
    required BuildContext context,
    required ExpenseCategory category,
    required List<ExpenseCardItem> items,
    required Function(ExpenseCardItem item) onRestoreItem,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => VaultDetailsSheet(
        category: category,
        items: items,
        onRestoreItem: onRestoreItem,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat('#,##0.00', 'th_TH');
    final dateFormatter = DateFormat('dd MMM yyyy, HH:mm น.', 'th_TH');

    double totalAmount = 0;
    for (final item in items) {
      totalAmount += item.amount;
    }

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.80,
      ),
      padding: const EdgeInsets.only(top: 14, left: 20, right: 20, bottom: 28),
      decoration: BoxDecoration(
        color: AppColors.mintioCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(
          color: category.color.withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 42,
              height: 4.5,
              decoration: BoxDecoration(
                color: AppColors.mintioTextMuted.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header: Category info & Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: category.color.withValues(alpha: 0.18),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: category.color.withValues(alpha: 0.4),
                        width: 1.2,
                      ),
                    ),
                    child: Icon(category.icon, color: category.color, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            category.thaiTitle,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.3,
                              color: AppColors.mintioTextPrimary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: category.color.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: category.color.withValues(alpha: 0.4),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              '${items.length} รายการ',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: category.color,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        category.latinTitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.mintioTextSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(
                  Icons.close_rounded,
                  color: AppColors.mintioTextSecondary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Total spent card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.mintioMidnight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: category.color.withValues(alpha: 0.35), width: 1.2),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'ยอดรวมในหมวดนี้',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.mintioTextSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '฿ ${currencyFormatter.format(totalAmount)}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: category.color,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // List of Slips or Empty State
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inbox_rounded,
                          size: 48,
                          color: AppColors.mintioTextMuted.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'ยังไม่มีสลิปในหมวดนี้',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.mintioTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'ปัดหรือสะบัดสลิปมาที่มุมนี้เพื่อจัดหมวดหมู่',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.mintioTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = items[index];
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
                            // Bank Indicator
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: item.bankColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 10),

                            // Item details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          item.receiverName,
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
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: person.color.withValues(alpha: 0.16),
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(
                                            color: person.color.withValues(alpha: 0.4),
                                            width: 1,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(person.icon, size: 10, color: person.color),
                                            const SizedBox(width: 3),
                                            Text(
                                              person.label,
                                              style: TextStyle(
                                                fontSize: 9.5,
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
                                      Text(
                                        item.bankName,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: item.bankColor,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        '• ${dateFormatter.format(item.dateTime)}',
                                        style: const TextStyle(
                                          fontSize: 10.5,
                                          color: AppColors.mintioTextMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (item.note != null &&
                                      item.note!.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      item.note!,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.mintioTextSecondary,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Amount & Restore Action
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '฿ ${currencyFormatter.format(item.amount)}',
                                  style: const TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.mintioTextPrimary,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                InkWell(
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    onRestoreItem(item);
                                    Navigator.of(context).pop();
                                  },
                                  borderRadius: BorderRadius.circular(10),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.mintioMidnight,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: AppColors.mintioBorder,
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: const [
                                        Icon(
                                          Icons.replay_rounded,
                                          size: 12,
                                          color: AppColors.mintioIndigoLight,
                                        ),
                                        SizedBox(width: 3),
                                        Text(
                                          'ปัดใหม่',
                                          style: TextStyle(
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.mintioIndigoLight,
                                          ),
                                        ),
                                      ],
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
        ],
      ),
    );
  }
}
