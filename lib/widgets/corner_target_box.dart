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
      scale: isHovered ? 1.08 : 1.0,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        width: 155,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isHovered
              ? category.color.withValues(alpha: 0.22)
              : AppColors.surface.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isHovered
                ? category.color
                : category.color.withValues(alpha: 0.35),
            width: isHovered ? 2.2 : 1.0,
          ),
          boxShadow: [
            if (isHovered)
              BoxShadow(
                color: category.color.withValues(alpha: 0.4),
                blurRadius: 18,
                spreadRadius: 2,
              )
            else
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: category.color.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    category.icon,
                    size: 16,
                    color: isHovered ? Colors.white : category.color,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    category.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isHovered ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '฿ ${currencyFormatter.format(totalAmount)}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isHovered ? category.color : AppColors.textSecondary,
                  ),
                ),
                if (itemCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: category.color.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$itemCount',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: category.color,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
