import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/constants/categories.dart';
import '../core/theme/app_theme.dart';

class CornerTargetBox extends StatelessWidget {
  final ExpenseCategory category;
  final bool isHovered;
  final double totalAmount;
  final int itemCount;
  final VoidCallback? onTap;

  const CornerTargetBox({
    super.key,
    required this.category,
    required this.isHovered,
    this.totalAmount = 0.0,
    this.itemCount = 0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat('#,##0', 'th_TH');

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: isHovered ? 1.05 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutBack,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutCubic,
          width: 148,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: isHovered ? category.bgColor : AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isHovered ? category.shadowColor : category.color,
              width: 2.2,
            ),
            boxShadow: [
              BoxShadow(
                color: category.shadowColor,
                offset: Offset(0, isHovered ? 5 : 4),
                blurRadius: 0, // Completely flat 3D arcade perspective
                spreadRadius: 0,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Cartoon Icon & Count Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: category.color,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: category.shadowColor,
                              offset: const Offset(0, 1.5),
                              blurRadius: 0,
                            ),
                          ],
                        ),
                        child: Icon(
                          category.icon,
                          size: 15,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '#${category.romanNumeral}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: category.shadowColor,
                        ),
                      ),
                    ],
                  ),
                  if (itemCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: category.color,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: category.shadowColor,
                            offset: const Offset(0, 1.5),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      child: Text(
                        '$itemCount ใบ',
                        style: const TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 5),

              // Latin Title in Chunky Comic Style
              Text(
                category.latinTitle,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                  color: AppColors.textPrimary,
                ),
              ),

              // Thai Subtitle
              Text(
                category.thaiTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 3),

              // Running Balance in Arcade 3D Style
              Text(
                '฿ ${currencyFormatter.format(totalAmount)}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: category.shadowColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
}
}
