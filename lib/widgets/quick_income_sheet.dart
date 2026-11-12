import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../core/theme/app_theme.dart';
import '../models/expense_card_item.dart';

class QuickIncomeSheet extends StatefulWidget {
  final Function(ExpenseCardItem item) onIncomeCreated;
  final DateTime? initialDate;

  const QuickIncomeSheet({
    super.key,
    required this.onIncomeCreated,
    this.initialDate,
  });

  static Future<void> show({
    required BuildContext context,
    required Function(ExpenseCardItem item) onIncomeCreated,
    DateTime? initialDate,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => QuickIncomeSheet(
        onIncomeCreated: onIncomeCreated,
        initialDate: initialDate,
      ),
    );
  }

  @override
  State<QuickIncomeSheet> createState() => _QuickIncomeSheetState();
}

class _QuickIncomeSheetState extends State<QuickIncomeSheet> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  late DateTime _selectedDate;

  String _selectedSource = 'เงินเดือน';
  final List<String> _incomeSources = [
    'เงินเดือน',
    'คืนเงิน/โอนคืน',
    'รายได้พิเศษ',
    'ปันผล/ดอกเบี้ย',
    'อื่นๆ',
  ];

  final List<double> _presetAmounts = [
    500,
    1000,
    3000,
    5000,
    15000,
    30000,
  ];

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate ?? DateTime.now();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _submit() {
    final amountText = _amountController.text.replaceAll(',', '').trim();
    final amount = double.tryParse(amountText);

    if (amount == null || amount <= 0) {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.mintioCardElevated,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: AppColors.expenseRed, width: 1.2),
          ),
          content: const Text(
            'กรุณากรอกจำนวนเงินให้ถูกต้อง',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.mintioTextPrimary,
            ),
          ),
        ),
      );
      return;
    }

    HapticFeedback.mediumImpact();

    final note = _noteController.text.trim();
    final item = ExpenseCardItem(
      id: 'income-${DateTime.now().millisecondsSinceEpoch}',
      receiverName: _selectedSource,
      amount: amount,
      dateTime: _selectedDate,
      bankName: 'รายรับ',
      bankColor: AppColors.mintioMint,
      referenceNo: 'INC-${DateTime.now().millisecondsSinceEpoch}',
      note: note.isNotEmpty ? note : _selectedSource,
      isIncome: true,
      assignedCategory: null,
    );

    widget.onIncomeCreated(item);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final dateFormatter = DateFormat('dd MMM yyyy', 'th_TH');

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.mintioCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: AppColors.mintioBorder, width: 1.5),
          left: BorderSide(color: AppColors.mintioBorder, width: 1.5),
          right: BorderSide(color: AppColors.mintioBorder, width: 1.5),
        ),
      ),
      padding: EdgeInsets.fromLTRB(20, 14, 20, 24 + bottomInset),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
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

            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.mintioMint.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.mintioMint.withValues(alpha: 0.4),
                          width: 1.2,
                        ),
                      ),
                      child: const Text(
                        '🪙',
                        style: TextStyle(fontSize: 20),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'เพิ่มรายรับ',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: AppColors.mintioTextPrimary,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'บันทึกรายการเงินเข้ากระเป๋า',
                          style: TextStyle(
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
                  icon: const Icon(Icons.close_rounded, color: AppColors.mintioTextSecondary),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Amount Input Card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.mintioMidnight,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.mintioMint.withValues(alpha: 0.6), width: 1.5),
              ),
              child: Row(
                children: [
                  const Text(
                    '+฿',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: AppColors.mintioMint,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      autofocus: true,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: AppColors.mintioTextPrimary,
                      ),
                      cursorColor: AppColors.mintioMint,
                      decoration: const InputDecoration(
                        hintText: '0.00',
                        hintStyle: TextStyle(
                          color: AppColors.mintioTextMuted,
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                        ),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Preset Amount Pills
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _presetAmounts.map((amt) {
                final label = '+${NumberFormat('#,##0', 'th_TH').format(amt)}';
                return InkWell(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    _amountController.text = amt.toStringAsFixed(0);
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: AppColors.mintioCardElevated,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.mintioBorder, width: 1.2),
                    ),
                    child: Text(
                      label,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.mintioMint,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 18),

            // Source Selector
            const Text(
              'แหล่งที่มาของเงิน',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.mintioTextSecondary,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _incomeSources.map((source) {
                final isSelected = _selectedSource == source;
                return InkWell(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _selectedSource = source);
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.mintioMint.withValues(alpha: 0.2)
                          : AppColors.mintioCardElevated,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected ? AppColors.mintioMint : AppColors.mintioBorder,
                        width: isSelected ? 1.6 : 1.2,
                      ),
                    ),
                    child: Text(
                      source,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                        color: isSelected ? AppColors.mintioMint : AppColors.mintioTextSecondary,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 18),

            // Date & Note Row
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                        builder: (context, child) {
                          return Theme(
                            data: ThemeData.dark().copyWith(
                              colorScheme: const ColorScheme.dark(
                                primary: AppColors.mintioIndigo,
                                surface: AppColors.mintioCard,
                                onSurface: AppColors.mintioTextPrimary,
                              ),
                              dialogTheme: const DialogThemeData(
                                backgroundColor: AppColors.mintioCard,
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null) {
                        setState(() => _selectedDate = picked);
                      }
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.mintioMidnight,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.mintioBorder, width: 1.2),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_rounded,
                            size: 15,
                            color: AppColors.mintioIndigoLight,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              dateFormatter.format(_selectedDate),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.mintioTextPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.mintioMidnight,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.mintioBorder, width: 1.2),
                    ),
                    child: TextField(
                      controller: _noteController,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.mintioTextPrimary,
                      ),
                      cursorColor: AppColors.mintioIndigo,
                      decoration: const InputDecoration(
                        hintText: 'บันทึกช่วยจำ (เช่น คืนค่าข้าว)',
                        hintStyle: TextStyle(
                          fontSize: 12,
                          color: AppColors.mintioTextMuted,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Submit Capsule Button
            ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.mintioMint,
                foregroundColor: Colors.black,
                elevation: 0,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.check_circle_rounded, size: 20, color: Colors.black),
                  SizedBox(width: 8),
                  Text(
                    'บันทึกรายรับ',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
