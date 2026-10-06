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
  final String? imagePath;
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
    this.imagePath,
    this.assignedCategory,
  });

  ExpenseCardItem copyWith({
    ExpenseCategory? assignedCategory,
    String? imagePath,
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
      imagePath: imagePath ?? this.imagePath,
      assignedCategory: assignedCategory ?? this.assignedCategory,
    );
  }

  /// Checks whether this item is a duplicate of another item
  bool isDuplicateOf(ExpenseCardItem other) {
    if (referenceNo.isNotEmpty && other.referenceNo.isNotEmpty && referenceNo == other.referenceNo) {
      return true;
    }
    if (imagePath != null && other.imagePath != null && imagePath!.isNotEmpty && imagePath == other.imagePath) {
      return true;
    }
    if (id == other.id) {
      return true;
    }
    return false;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'receiverName': receiverName,
    'amount': amount,
    'dateTime': dateTime.toIso8601String(),
    'bankName': bankName,
    'bankColor': bankColor.toARGB32(),
    'referenceNo': referenceNo,
    'note': note,
    'imagePath': imagePath,
    'assignedCategoryId': assignedCategory?.id,
  };

  factory ExpenseCardItem.fromJson(Map<String, dynamic> json) {
    ExpenseCategory? category;
    if (json['assignedCategoryId'] != null) {
      final id = json['assignedCategoryId'] as String;
      for (final c in ExpenseCategory.defaultCorners) {
        if (c.id == id) {
          category = c;
          break;
        }
      }
    }

    final colorVal = json['bankColor'];
    final Color color = colorVal is int ? Color(colorVal) : const Color(0xFF003D79);

    return ExpenseCardItem(
      id: json['id'] as String? ?? 'id-${DateTime.now().millisecondsSinceEpoch}',
      receiverName: json['receiverName'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      dateTime: json['dateTime'] != null
          ? DateTime.tryParse(json['dateTime'] as String) ?? DateTime.now()
          : DateTime.now(),
      bankName: json['bankName'] as String? ?? 'ธนาคาร',
      bankColor: color,
      referenceNo: json['referenceNo'] as String? ?? '',
      note: json['note'] as String?,
      imagePath: json['imagePath'] as String?,
      assignedCategory: category,
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
