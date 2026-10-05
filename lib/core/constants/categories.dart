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
  final CornerPosition corner;
  final String romanNumeral;

  const ExpenseCategory({
    required this.id,
    required this.latinTitle,
    required this.thaiTitle,
    required this.icon,
    required this.color,
    required this.corner,
    required this.romanNumeral,
  });

  static const List<ExpenseCategory> defaultCorners = [
    ExpenseCategory(
      id: 'food',
      latinTitle: 'TAVERNA',
      thaiTitle: 'เสบียง & งานเลี้ยง',
      icon: Icons.wine_bar_rounded,
      color: AppColors.vaultTaverna,
      corner: CornerPosition.topLeft,
      romanNumeral: 'I',
    ),
    ExpenseCategory(
      id: 'transport',
      latinTitle: 'QUADRIGA',
      thaiTitle: 'รถม้า & การสัญจร',
      icon: Icons.directions_transit_filled_rounded,
      color: AppColors.vaultQuadriga,
      corner: CornerPosition.topRight,
      romanNumeral: 'II',
    ),
    ExpenseCategory(
      id: 'shopping',
      latinTitle: 'FORUM',
      thaiTitle: 'ตลาดการค้า & สินค้า',
      icon: Icons.storefront_rounded,
      color: AppColors.vaultForum,
      corner: CornerPosition.bottomLeft,
      romanNumeral: 'III',
    ),
    ExpenseCategory(
      id: 'bills',
      latinTitle: 'TRIBUTUM',
      thaiTitle: 'ส่วยหลวง & บิลประจำ',
      icon: Icons.account_balance_rounded,
      color: AppColors.vaultTributum,
      corner: CornerPosition.bottomRight,
      romanNumeral: 'IV',
    ),
  ];
}
