import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../models/expense_card_item.dart';

class QuickAddSheet extends StatefulWidget {
  final Function(ExpenseCardItem newItem) onCardCreated;

  const QuickAddSheet({super.key, required this.onCardCreated});

  @override
  State<QuickAddSheet> createState() => _QuickAddSheetState();
}

class _QuickAddSheetState extends State<QuickAddSheet> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  String _selectedSource = 'เงินสด (Cash)';
  Color _sourceColor = AppColors.gold;

  final List<Map<String, dynamic>> _sources = [
    {'name': 'เงินสด (Cash)', 'color': AppColors.gold},
    {'name': 'PromptPay', 'color': const Color(0xFF003D79)},
    {'name': 'TrueMoney', 'color': const Color(0xFFFA5A00)},
    {'name': 'K PLUS', 'color': const Color(0xFF138F46)},
    {'name': 'SCB EASY', 'color': const Color(0xFF4E2A84)},
  ];

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _submit() {
    final amountText = _amountController.text.trim();
    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) return;

    final note = _noteController.text.trim().isEmpty
        ? 'รายการจ่ายด่วน'
        : _noteController.text.trim();

    final newItem = ExpenseCardItem(
      id: 'quick-${DateTime.now().millisecondsSinceEpoch}',
      receiverName: note,
      amount: amount,
      dateTime: DateTime.now(),
      bankName: _selectedSource,
      bankColor: _sourceColor,
      referenceNo: 'MANUAL-${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}',
      note: 'บันทึกด่วน',
    );

    widget.onCardCreated(newItem);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.35), width: 1.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.edit_note_rounded, color: AppColors.gold, size: 22),
                  SizedBox(width: 8),
                  Text(
                    'บันทึกรายการด่วน',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                      color: AppColors.gold,
                    ),
                  ),
                ],
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, color: AppColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Amount Input
          TextField(
            controller: _amountController,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppColors.goldBright,
            ),
            decoration: InputDecoration(
              prefixText: '฿ ',
              prefixStyle: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppColors.goldBright,
              ),
              hintText: '0.00',
              hintStyle: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppColors.textMuted.withValues(alpha: 0.4),
              ),
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: AppColors.gold.withValues(alpha: 0.3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: AppColors.gold.withValues(alpha: 0.3)),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Note Input
          TextField(
            controller: _noteController,
            style: const TextStyle(color: AppColors.marbleWhite),
            decoration: InputDecoration(
              hintText: 'ชื่อร้านค้า หรือ รายการ (เช่น กาแฟ, ข้าวกลางวัน)',
              hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Source selector chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _sources.map((s) {
                final isSelected = _selectedSource == s['name'];
                final color = s['color'] as Color;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(s['name'] as String),
                    selected: isSelected,
                    selectedColor: color.withValues(alpha: 0.3),
                    backgroundColor: AppColors.background,
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                    ),
                    side: BorderSide(
                      color: isSelected ? color : Colors.transparent,
                    ),
                    onSelected: (val) {
                      if (val) {
                        setState(() {
                          _selectedSource = s['name'] as String;
                          _sourceColor = color;
                        });
                      }
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),

          // Submit Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: const Color(0xFF0F172A),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: const Text(
                'บันทึกรายการ',
                style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
