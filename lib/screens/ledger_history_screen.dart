import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../core/constants/categories.dart';
import '../core/theme/app_theme.dart';
import '../models/expense_card_item.dart';
import '../widgets/arcade_button.dart';
import '../widgets/arcade_card.dart';

class LedgerHistoryScreen extends StatefulWidget {
  final List<ExpenseCardItem> transactions;
  final Function(ExpenseCardItem item) onDeleteTransaction;

  const LedgerHistoryScreen({
    super.key,
    required this.transactions,
    required this.onDeleteTransaction,
  });

  @override
  State<LedgerHistoryScreen> createState() => _LedgerHistoryScreenState();
}

class _LedgerHistoryScreenState extends State<LedgerHistoryScreen> {
  String _searchQuery = '';
  String? _selectedCategoryId; // null = all

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat('#,##0.00', 'th_TH');
    final dateFormatter = DateFormat('dd MMM yyyy, HH:mm น.', 'th_TH');

    final filteredList = widget.transactions.where((item) {
      if (_selectedCategoryId != null &&
          item.assignedCategory?.id != _selectedCategoryId) {
        return false;
      }
      if (_searchQuery.trim().isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchReceiver = item.receiverName.toLowerCase().contains(query);
        final matchNote = item.note?.toLowerCase().contains(query) ?? false;
        final matchBank = item.bankName.toLowerCase().contains(query);
        final matchAmount = item.amount.toString().contains(query);
        final matchRef = item.referenceNo.toLowerCase().contains(query);
        return matchReceiver || matchNote || matchBank || matchAmount || matchRef;
      }
      return true;
    }).toList();

    final double totalFilteredAmount = filteredList.fold(
      0.0,
      (sum, item) => sum + item.amount,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // App Bar Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'บันทึกคลังหลวง (Ledger)',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: AppColors.gold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      '${filteredList.length} รายการ',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.marbleWhite,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: TextField(
                onChanged: (val) => setState(() => _searchQuery = val),
                style: const TextStyle(color: Colors.white, fontSize: 13.5),
                decoration: InputDecoration(
                  hintText: 'ค้นหาชื่อร้าน, เลขที่อ้างอิง, หรือยอดเงิน...',
                  hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
                  prefixIcon: const Icon(Icons.search_rounded, color: AppColors.gold, size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () => setState(() => _searchQuery = ''),
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.surface,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.borderDark),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.gold, width: 1.5),
                  ),
                ),
              ),
            ),

            // Filter Chips (All + 4 Categories)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  _buildFilterChip(
                    label: 'ทั้งหมด',
                    isSelected: _selectedCategoryId == null,
                    color: AppColors.gold,
                    onTap: () => setState(() => _selectedCategoryId = null),
                  ),
                  const SizedBox(width: 8),
                  for (final cat in ExpenseCategory.defaultCorners) ...[
                    _buildFilterChip(
                      label: cat.thaiTitle,
                      icon: cat.icon,
                      isSelected: _selectedCategoryId == cat.id,
                      color: cat.color,
                      onTap: () => setState(() => _selectedCategoryId = cat.id),
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),

            // Total Summary Pill
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'ยอดรวมการกรอง:',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    Text(
                      '฿ ${currencyFormatter.format(totalFilteredAmount)}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.gold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Transactions List
            Expanded(
              child: filteredList.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.inventory_2_outlined, size: 48, color: AppColors.textMuted),
                          SizedBox(height: 12),
                          Text(
                            'ไม่พบรายการธุรกรรม',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                      itemCount: filteredList.length,
                      itemBuilder: (context, index) {
                        final item = filteredList[index];
                        final cat = item.assignedCategory;

                        return Dismissible(
                          key: Key(item.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            decoration: BoxDecoration(
                              color: AppColors.waxSealRed,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
                          ),
                          onDismissed: (_) => widget.onDeleteTransaction(item),
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: ArcadeCard(
                              onTap: () => _showSlipDetails(context, item),
                              borderColor: (cat?.color ?? AppColors.borderDark).withValues(alpha: 0.4),
                              shadowColor: (cat?.shadowColor ?? AppColors.shadowDefault).withValues(alpha: 0.35),
                              depth: 2.5,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: (cat?.color ?? AppColors.gold).withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      cat?.icon ?? Icons.receipt_long_rounded,
                                      color: cat?.color ?? AppColors.gold,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.receiverName,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.marbleWhite,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          dateFormatter.format(item.dateTime),
                                          style: const TextStyle(
                                            fontSize: 10.5,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                        if (item.note != null && item.note!.isNotEmpty)
                                          Text(
                                            'โน้ต: ${item.note!}',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 10.5,
                                              color: AppColors.gold,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        '฿ ${currencyFormatter.format(item.amount)}',
                                        style: const TextStyle(
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.w900,
                                          color: AppColors.gold,
                                        ),
                                      ),
                                      if (item.imagePath != null)
                                        const Icon(
                                          Icons.photo_rounded,
                                          size: 13,
                                          color: AppColors.textMuted,
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    IconData? icon,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    final fgColor = isSelected
        ? (color == AppColors.gold ? const Color(0xFF1E293B) : Colors.white)
        : AppColors.textPrimary;
    final iconColor = isSelected ? fgColor : AppColors.textSecondary;
    final shadowColor = isSelected
        ? (color == AppColors.gold ? AppColors.goldShadow : color.withValues(alpha: 0.8))
        : AppColors.shadowDefault;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ArcadeButton(
        onPressed: onTap,
        color: isSelected ? color : AppColors.surface,
        shadowColor: shadowColor,
        borderColor: isSelected ? color : AppColors.borderDark,
        borderWidth: 1.5,
        depth: 3.0,
        borderRadius: BorderRadius.circular(14),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: iconColor),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                color: fgColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSlipDetails(BuildContext context, ExpenseCardItem item) {
    HapticFeedback.lightImpact();
    final currencyFormatter = NumberFormat('#,##0.00', 'th_TH');
    final dateFormatter = DateFormat('dd MMMM yyyy, HH:mm น.', 'th_TH');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borderDark,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    item.bankName,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: item.bankColor,
                    ),
                  ),
                  Text(
                    '฿ ${currencyFormatter.format(item.amount)}',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: AppColors.gold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(color: AppColors.border),
              const SizedBox(height: 10),
              _buildDetailRow('โอนไปยัง:', item.receiverName),
              _buildDetailRow('วัน-เวลา:', dateFormatter.format(item.dateTime)),
              _buildDetailRow('เลขที่อ้างอิง:', item.referenceNo),
              if (item.note != null && item.note!.isNotEmpty)
                _buildDetailRow('บันทึกช่วยจำ:', item.note!),
              if (item.assignedCategory != null)
                _buildDetailRow('หมวดหมู่:', item.assignedCategory!.thaiTitle),

              if (item.imagePath != null) ...[
                const SizedBox(height: 16),
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: SizedBox(
                      height: 180,
                      child: Image.file(
                        File(item.imagePath!),
                        fit: BoxFit.contain,
                        errorBuilder: (ctx, err, stack) => const Icon(
                          Icons.broken_image_rounded,
                          size: 40,
                          color: Colors.white24,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppColors.marbleWhite,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
