import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/constants/categories.dart';
import '../core/theme/app_theme.dart';

class CornerTargetBox extends StatelessWidget {
  final ExpenseCategory category;
  final bool isHovered;
  final double totalAmount;
  final int itemCount;

  const CornerTargetBox({
    super.key,
    required this.category,
    required this.isHovered,
    this.totalAmount = 0.0,
    this.itemCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat('#,##0', 'th_TH');

    return AnimatedScale(
      scale: isHovered ? 1.09 : 1.0,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutBack,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        width: 158,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          // Roman Temple Vault styling (Arch rounded top)
          color: isHovered
              ? category.color.withValues(alpha: 0.25)
              : AppColors.surface.withValues(alpha: 0.90),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomLeft: Radius.circular(12),
            bottomRight: Radius.circular(12),
          ),
          border: Border.all(
            color: isHovered
                ? AppColors.gold
                : category.color.withValues(alpha: 0.45),
            width: isHovered ? 2.0 : 1.2,
          ),
          boxShadow: [
            if (isHovered) ...[
              BoxShadow(
                color: category.color.withValues(alpha: 0.45),
                blurRadius: 20,
                spreadRadius: 2,
              ),
              BoxShadow(
                color: AppColors.gold.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 0),
              ),
            ] else
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Roman Numeral & Icon
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: category.color.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isHovered ? AppColors.gold : category.color.withValues(alpha: 0.4),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        category.icon,
                        size: 15,
                        color: isHovered ? AppColors.gold : category.color,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      category.romanNumeral,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                        color: isHovered ? AppColors.gold : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
                if (itemCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: category.color.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: category.color.withValues(alpha: 0.5),
                        width: 0.8,
                      ),
                    ),
                    child: Text(
                      '$itemCount ใบ',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                        color: category.color,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),

            // Latin Title in Roman Capitals
            Text(
              category.latinTitle,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
                color: isHovered ? AppColors.gold : AppColors.marbleWhite,
              ),
            ),

            // Thai Subtitle
            Text(
              category.thaiTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary.withValues(alpha: 0.85),
              ),
            ),
            const SizedBox(height: 4),

            // Running Balance
            Text(
              '฿ ${currencyFormatter.format(totalAmount)}',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: isHovered ? AppColors.goldBright : category.color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
