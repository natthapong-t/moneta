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
  final String title;
  final IconData icon;
  final Color color;
  final CornerPosition corner;

  const ExpenseCategory({
    required this.id,
    required this.title,
    required this.icon,
    required this.color,
    required this.corner,
  });

  static const List<ExpenseCategory> defaultCorners = [
    ExpenseCategory(
      id: 'food',
      title: 'อาหาร & เครื่องดื่ม',
      icon: Icons.restaurant_rounded,
      color: AppColors.catFood,
      corner: CornerPosition.topLeft,
    ),
    ExpenseCategory(
      id: 'transport',
      title: 'เดินทาง & น้ำมัน',
      icon: Icons.directions_car_rounded,
      color: AppColors.catTransport,
      corner: CornerPosition.topRight,
    ),
    ExpenseCategory(
      id: 'shopping',
      title: 'ช้อปปิ้ง & สินค้า',
      icon: Icons.shopping_bag_rounded,
      color: AppColors.catShopping,
      corner: CornerPosition.bottomLeft,
    ),
    ExpenseCategory(
      id: 'bills',
      title: 'บิล & ค่าใช้จ่าย',
      icon: Icons.receipt_long_rounded,
      color: AppColors.catBills,
      corner: CornerPosition.bottomRight,
    ),
  ];
}
