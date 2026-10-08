import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme/app_theme.dart';
import '../models/expense_card_item.dart';
import 'arcade_button.dart';

class QuickAddSheet extends StatefulWidget {
  final Function(ExpenseCardItem newItem) onCardCreated;

  const QuickAddSheet({super.key, required this.onCardCreated});

  @override
  State<QuickAddSheet> createState() => _QuickAddSheetState();
}

class _QuickAddSheetState extends State<QuickAddSheet> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  String _selectedSource = 'เงินสด';
  Color _sourceColor = AppColors.gold;

  final List<Map<String, dynamic>> _sources = [
    {
      'name': 'เงินสด',
      'color': AppColors.gold,
      'icon': Icons.payments_rounded,
    },
    {
      'name': 'PromptPay',
      'color': const Color(0xFF003D79),
      'icon': Icons.qr_code_rounded,
    },
    {
      'name': 'แอปธนาคาร',
      'color': AppColors.vaultQuadriga,
      'icon': Icons.account_balance_rounded,
    },
  ];

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
      return;
    }

    HapticFeedback.mediumImpact();

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
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: AppColors.borderDark, width: 2.5),
          left: BorderSide(color: AppColors.borderDark, width: 2.5),
          right: BorderSide(color: AppColors.borderDark, width: 2.5),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: AppColors.borderDark.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.goldShadow, width: 1.5),
                    ),
                    child: const Icon(
                      Icons.flash_on_rounded,
                      color: AppColors.goldShadow,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'บันทึกรายการด่วน',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'จดบันทึกรายจ่าย',
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
          const SizedBox(height: 16),

          // Amount Input (High Contrast)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.borderDark, width: 2.0),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.shadowDefault,
                  offset: Offset(0, 3),
                  blurRadius: 0,
                ),
              ],
            ),
            child: Row(
              children: [
                const Text(
                  '฿',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: AppColors.goldShadow,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _amountController,
                    autofocus: true,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary, // High contrast dark text!
                    ),
                    decoration: const InputDecoration(
                      hintText: '0.00',
                      hintStyle: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: AppColors.borderDark, // Visible clear hint
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Note Input (High Contrast)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderDark, width: 1.5),
            ),
            child: TextField(
              controller: _noteController,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              decoration: const InputDecoration(
                hintText: 'ชื่อร้านค้า หรือ รายการ (เช่น กาแฟ, ข้าวกลางวัน)',
                hintStyle: TextStyle(
                  color: AppColors.textSecondary, // Crisp and readable
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Channel / Source Selector Label
          const Text(
            'ช่องทางการชำระเงิน',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),

          // Source selector chips (เงินสด, PromptPay, แอปธนาคาร)
          Row(
            children: _sources.map((s) {
              final isSelected = _selectedSource == s['name'];
              final color = s['color'] as Color;
              final icon = s['icon'] as IconData;

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _selectedSource = s['name'] as String;
                        _sourceColor = color;
                      });
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? color : AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected ? color : AppColors.borderDark,
                          width: 2.0,
                        ),
                        boxShadow: [
                          if (isSelected)
                            BoxShadow(
                              color: color.withValues(alpha: 0.35),
                              offset: const Offset(0, 3),
                              blurRadius: 0,
                            ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            icon,
                            size: 16,
                            color: isSelected
                                ? (color == AppColors.gold ? Colors.black87 : Colors.white)
                                : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            s['name'] as String,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w900,
                              color: isSelected
                                  ? (color == AppColors.gold ? Colors.black87 : Colors.white)
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 22),

          // Submit Button (Arcade Button)
          ArcadeButton(
            onPressed: _submit,
            width: double.infinity,
            backgroundColor: AppColors.gold,
            shadowColor: AppColors.goldShadow,
            borderColor: AppColors.goldShadow,
            textColor: Colors.black87,
            icon: Icons.check_circle_rounded,
            label: 'บันทึกรายการด่วน',
            height: 48,
          ),
        ],
      ),
    );
  }
}
