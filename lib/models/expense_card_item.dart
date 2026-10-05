import 'package:flutter/material.dart';
import '../core/constants/categories.dart';

class ExpenseCardItem {
  final String id;
  final String receiverName;
  final double amount;
  final DateTime dateTime;
  final String bankName;
  final Color bankColor;
  final String referenceNo;
  final String? note;
  ExpenseCategory? assignedCategory;

  ExpenseCardItem({
    required this.id,
    required this.receiverName,
    required this.amount,
    required this.dateTime,
    required this.bankName,
    required this.bankColor,
    required this.referenceNo,
    this.note,
    this.assignedCategory,
  });

  ExpenseCardItem copyWith({
    ExpenseCategory? assignedCategory,
  }) {
    return ExpenseCardItem(
      id: id,
      receiverName: receiverName,
      amount: amount,
      dateTime: dateTime,
      bankName: bankName,
      bankColor: bankColor,
      referenceNo: referenceNo,
      note: note,
      assignedCategory: assignedCategory ?? this.assignedCategory,
    );
  }

  static List<ExpenseCardItem> get sampleCards => [
    ExpenseCardItem(
      id: 'slip-001',
      receiverName: 'ก๋วยเตี๋ยวเรืออยุธยา ป้าสมศรี',
      amount: 65.00,
      dateTime: DateTime.now().subtract(const Duration(minutes: 15)),
      bankName: 'K PLUS',
      bankColor: const Color(0xFF138F46),
      referenceNo: '2026100578912445',
      note: 'มื้อกลางวัน พิเศษ 2 ชาม',
    ),
    ExpenseCardItem(
      id: 'slip-002',
      receiverName: 'บมจ. ระบบขนส่งมวลชนกรุงเทพ (BTS)',
      amount: 47.00,
      dateTime: DateTime.now().subtract(const Duration(hours: 1, minutes: 20)),
      bankName: 'SCB EASY',
      bankColor: const Color(0xFF4E2A84),
      referenceNo: '2026100566319802',
      note: 'เดินทางไปประชุม',
    ),
    ExpenseCardItem(
      id: 'slip-003',
      receiverName: 'Uniqlo สาขาเซ็นทรัลลาดพร้าว',
      amount: 990.00,
      dateTime: DateTime.now().subtract(const Duration(hours: 3)),
      bankName: 'K-Bank',
      bankColor: const Color(0xFF138F46),
      referenceNo: '2026100511223344',
      note: 'เสื้อเชิ้ตทำงาน AIRism',
    ),
    ExpenseCardItem(
      id: 'slip-004',
      receiverName: 'การไฟฟ้านครหลวง (MEA)',
      amount: 1450.50,
      dateTime: DateTime.now().subtract(const Duration(hours: 5)),
      bankName: 'PromptPay',
      bankColor: const Color(0xFF003D79),
      referenceNo: '2026100599887766',
      note: 'ค่าไฟฟ้าประจำเดือน กันยายน',
    ),
    ExpenseCardItem(
      id: 'slip-005',
      receiverName: 'GrabFood Thailand',
      amount: 235.00,
      dateTime: DateTime.now().subtract(const Duration(hours: 7)),
      bankName: 'TrueMoney',
      bankColor: const Color(0xFFFA5A00),
      referenceNo: '2026100544556677',
      note: 'ข้าวหน้าหมูทอดทงคัตสึ',
    ),
    ExpenseCardItem(
      id: 'slip-006',
      receiverName: 'PTT Station สาขาวิภาวดี',
      amount: 800.00,
      dateTime: DateTime.now().subtract(const Duration(days: 1)),
      bankName: 'Krungthai NEXT',
      bankColor: const Color(0xFF00A3E0),
      referenceNo: '2026100412345678',
      note: 'เติมน้ำมัน Gasohol 95',
    ),
  ];
}
