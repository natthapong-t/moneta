import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum CornerPosition {
  topLeft,
  topRight,
  bottomLeft,
  bottomRight,
}

class ExpenseCategory {
  final String id;
  final String latinTitle;
  final String thaiTitle;
  final IconData icon;
  final Color color;
  final Color shadowColor;
  final Color bgColor;
  final CornerPosition corner;
  final String romanNumeral;

  const ExpenseCategory({
    required this.id,
    required this.latinTitle,
    required this.thaiTitle,
    required this.icon,
    required this.color,
    required this.shadowColor,
    required this.bgColor,
    required this.corner,
    required this.romanNumeral,
  });

  static const List<ExpenseCategory> defaultCorners = [
    ExpenseCategory(
      id: 'food',
      latinTitle: 'Food',
      thaiTitle: 'อาหาร & เครื่องดื่ม',
      icon: Icons.restaurant_rounded,
      color: AppColors.vaultTaverna,
      shadowColor: AppColors.vaultTavernaShadow,
      bgColor: AppColors.vaultTavernaBg,
      corner: CornerPosition.topLeft,
      romanNumeral: '1',
    ),
    ExpenseCategory(
      id: 'transport',
      latinTitle: 'Transport',
      thaiTitle: 'การเดินทาง',
      icon: Icons.directions_subway_rounded,
      color: AppColors.vaultQuadriga,
      shadowColor: AppColors.vaultQuadrigaShadow,
      bgColor: AppColors.vaultQuadrigaBg,
      corner: CornerPosition.topRight,
      romanNumeral: '2',
    ),
    ExpenseCategory(
      id: 'shopping',
      latinTitle: 'Shopping',
      thaiTitle: 'ช้อปปิ้ง & สินค้า',
      icon: Icons.shopping_bag_rounded,
      color: AppColors.vaultForum,
      shadowColor: AppColors.vaultForumShadow,
      bgColor: AppColors.vaultForumBg,
      corner: CornerPosition.bottomLeft,
      romanNumeral: '3',
    ),
    ExpenseCategory(
      id: 'bills',
      latinTitle: 'Bills',
      thaiTitle: 'บิล & ค่าใช้จ่าย',
      icon: Icons.receipt_long_rounded,
      color: AppColors.vaultTributum,
      shadowColor: AppColors.vaultTributumShadow,
      bgColor: AppColors.vaultTributumBg,
      corner: CornerPosition.bottomRight,
      romanNumeral: '4',
    ),
  ];
}
