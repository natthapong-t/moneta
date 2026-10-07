import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../core/theme/app_theme.dart';
import '../models/expense_card_item.dart';
import 'arcade_button.dart';
import 'arcade_card.dart';

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
          backgroundColor: AppColors.vaultTributum,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: const Text(
            'กรุณากรอกจำนวนเงินให้ถูกต้อง',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
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
      bankColor: AppColors.emerald,
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
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: AppColors.borderDark, width: 2.5),
          left: BorderSide(color: AppColors.borderDark, width: 2.5),
          right: BorderSide(color: AppColors.borderDark, width: 2.5),
        ),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomInset),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.borderDark.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.emerald.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.emerald, width: 1.5),
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
                          'หยอดเหรียญรายรับ',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Insert Coin (เติมกระสุน / เงินเข้า)',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Amount Field
            ArcadeCard(
              borderColor: AppColors.emerald,
              shadowColor: AppColors.emerald.withValues(alpha: 0.3),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Text(
                    '+฿',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: AppColors.emerald,
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
                        color: AppColors.textPrimary,
                      ),
                      decoration: const InputDecoration(
                        hintText: '0.00',
                        hintStyle: TextStyle(
                          color: AppColors.textSecondary,
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
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.borderDark, width: 1.5),
                    ),
                    child: Text(
                      label,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.emerald,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Source Selector
            const Text(
              'แหล่งที่มาของเงิน',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _incomeSources.map((source) {
                final isSelected = _selectedSource == source;
                return ChoiceChip(
                  label: Text(source),
                  selected: isSelected,
                  selectedColor: AppColors.emerald.withValues(alpha: 0.2),
                  backgroundColor: AppColors.background,
                  labelStyle: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: isSelected ? AppColors.emerald : AppColors.textPrimary,
                  ),
                  side: BorderSide(
                    color: isSelected ? AppColors.emerald : AppColors.borderDark,
                    width: 1.5,
                  ),
                  onSelected: (val) {
                    if (val) {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedSource = source);
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 14),

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
                      );
                      if (picked != null) {
                        setState(() => _selectedDate = picked);
                      }
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.borderDark, width: 1.5),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.textSecondary),
                          const SizedBox(width: 8),
                          Text(
                            dateFormatter.format(_selectedDate),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
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
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.borderDark, width: 1.5),
                    ),
                    child: TextField(
                      controller: _noteController,
                      decoration: const InputDecoration(
                        hintText: 'บันทึกช่วยจำ (เช่น คืนค่าเทอม)',
                        hintStyle: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 10),
                      ),
                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Submit Button
            ArcadeButton(
              onPressed: _submit,
              backgroundColor: AppColors.emerald,
              shadowColor: const Color(0xFF0D6832),
              textColor: Colors.white,
              icon: Icons.check_circle_rounded,
              label: 'ยืนยันหยอดเหรียญรายรับ',
              height: 48,
            ),
          ],
        ),
      ),
    );
  }
}
