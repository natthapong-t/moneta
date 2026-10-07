import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../core/constants/categories.dart';
import '../core/theme/app_theme.dart';
import '../models/expense_card_item.dart';
import '../widgets/arcade_button.dart';
import '../widgets/arcade_card.dart';
import '../widgets/arcade_calendar_view.dart';
import '../widgets/daily_transactions_sheet.dart';

class LedgerHistoryScreen extends StatefulWidget {
  final List<ExpenseCardItem> transactions;
  final List<ExpenseCardItem> pendingCards;
  final Function(ExpenseCardItem item) onDeleteTransaction;
  final VoidCallback onAddIncome;
  final VoidCallback onAddExpense;
  final VoidCallback onStartSwiping;

  const LedgerHistoryScreen({
    super.key,
    required this.transactions,
    this.pendingCards = const [],
    required this.onDeleteTransaction,
    required this.onAddIncome,
    required this.onAddExpense,
    required this.onStartSwiping,
  });

  @override
  State<LedgerHistoryScreen> createState() => _LedgerHistoryScreenState();
}

class _LedgerHistoryScreenState extends State<LedgerHistoryScreen> {
  String _searchQuery = '';
  String? _selectedCategoryId; // null = all, 'income' = income only, or vault id
  bool _isCalendarView = true; // Default to the interactive calendar view!

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat('#,##0.00', 'th_TH');
    final dateFormatter = DateFormat('dd MMM yyyy, HH:mm น.', 'th_TH');

    final filteredList = widget.transactions.where((item) {
      if (_selectedCategoryId != null) {
        if (_selectedCategoryId == 'income') {
          if (!item.isIncome) return false;
        } else {
          if (item.isIncome || item.assignedCategory?.id != _selectedCategoryId) {
            return false;
          }
        }
      }
      if (_searchQuery.trim().isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchReceiver = item.receiverName.toLowerCase().contains(query);
        final matchNote = item.note?.toLowerCase().contains(query) ?? false;
        final matchBank = item.bankName.toLowerCase().contains(query);
        final matchAmount = item.amount.toString().contains(query);
        final matchRef = item.referenceNo.toLowerCase().contains(query);
        return matchReceiver ||
            matchNote ||
            matchBank ||
            matchAmount ||
            matchRef;
      }
      return true;
    }).toList();

    double totalFilteredIncome = 0;
    double totalFilteredExpense = 0;
    for (final item in filteredList) {
      if (item.isIncome) {
        totalFilteredIncome += item.amount;
      } else {
        totalFilteredExpense += item.amount;
      }
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'บันทึกการเงิน',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Ledger & Calendar Overview',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),

                  // Quick Action Buttons (+ รายรับ, + รายจ่าย)
                  Row(
                    children: [
                      ArcadeButton(
                        onPressed: widget.onAddIncome,
                        color: AppColors.emerald,
                        borderColor: AppColors.emeraldShadow,
                        shadowColor: AppColors.emeraldShadow,
                        depth: 2.5,
                        borderRadius: BorderRadius.circular(12),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        child: Row(
                          children: const [
                            Text('🪙', style: TextStyle(fontSize: 13)),
                            SizedBox(width: 4),
                            Text(
                              '+ รับ',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      ArcadeButton(
                        onPressed: widget.onAddExpense,
                        color: AppColors.surface,
                        borderColor: AppColors.borderDark,
                        shadowColor: AppColors.shadowDefault,
                        depth: 2.5,
                        borderRadius: BorderRadius.circular(12),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        child: Row(
                          children: const [
                            Icon(Icons.add_rounded, size: 15, color: AppColors.vaultTaverna),
                            SizedBox(width: 2),
                            Text(
                              '+ จ่าย',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w900,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // View Switcher Tabs: [📅 ปฏิทิน]  [📋 รายการ]
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderDark, width: 1.5),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.shadowDefault,
                      offset: Offset(0, 2),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildViewTab(
                        title: 'ปฏิทินรายวัน',
                        icon: Icons.calendar_month_rounded,
                        isActive: _isCalendarView,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _isCalendarView = true);
                        },
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: _buildViewTab(
                        title: 'รายการทั้งหมด (${widget.transactions.length})',
                        icon: Icons.format_list_bulleted_rounded,
                        isActive: !_isCalendarView,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _isCalendarView = false);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Content Area (Calendar or List)
            Expanded(
              child: _isCalendarView
                  ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                      child: ArcadeCalendarView(
                        transactions: widget.transactions,
                        pendingCards: widget.pendingCards,
                        onDateSelected: (selectedDate) {
                          DailyTransactionsSheet.show(
                            context: context,
                            date: selectedDate,
                            allCategorized: widget.transactions,
                            allPending: widget.pendingCards,
                            onDeleteItem: widget.onDeleteTransaction,
                            onAddIncome: widget.onAddIncome,
                            onAddExpense: widget.onAddExpense,
                            onSwipePending: widget.onStartSwiping,
                          );
                        },
                      ),
                    )
                  : Column(
                      children: [
                        // Search Bar
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                          child: TextField(
                            onChanged: (val) => setState(() => _searchQuery = val),
                            style: const TextStyle(color: AppColors.textPrimary, fontSize: 13.5),
                            decoration: InputDecoration(
                              hintText: 'ค้นหาชื่อร้าน, แหล่งที่มา, โน้ต...',
                              hintStyle: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12.5,
                              ),
                              prefixIcon: const Icon(
                                Icons.search_rounded,
                                color: AppColors.gold,
                                size: 20,
                              ),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear_rounded, size: 18),
                                      onPressed: () => setState(() => _searchQuery = ''),
                                    )
                                  : null,
                              filled: true,
                              fillColor: AppColors.surface,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(color: AppColors.borderDark, width: 1.5),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(color: AppColors.borderDark, width: 1.5),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(
                                  color: AppColors.gold,
                                  width: 1.8,
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Filter Chips
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                          child: Row(
                            children: [
                              _buildFilterChip(
                                label: 'ทั้งหมด',
                                isSelected: _selectedCategoryId == null,
                                color: AppColors.gold,
                                onTap: () => setState(() => _selectedCategoryId = null),
                              ),
                              const SizedBox(width: 8),
                              _buildFilterChip(
                                label: '🪙 รายรับ',
                                isSelected: _selectedCategoryId == 'income',
                                color: AppColors.emerald,
                                onTap: () => setState(() => _selectedCategoryId = 'income'),
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

                        // Summary Pill
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.borderDark, width: 1.2),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Text(
                                      'ผลลัพธ์: ',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    Text(
                                      '${filteredList.length} รายการ',
                                      style: const TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    if (totalFilteredIncome > 0) ...[
                                      Text(
                                        '+฿${currencyFormatter.format(totalFilteredIncome)}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w900,
                                          color: AppColors.emerald,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                    ],
                                    Text(
                                      '-฿${currencyFormatter.format(totalFilteredExpense)}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w900,
                                        color: AppColors.vaultTributum,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),

                        // List of items
                        Expanded(
                          child: filteredList.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: const [
                                      Icon(
                                        Icons.receipt_long_outlined,
                                        size: 48,
                                        color: AppColors.textSecondary,
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        'ยังไม่มีรายการที่ตรงกับเงื่อนไข',
                                        style: TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : ListView.builder(
                                  physics: const BouncingScrollPhysics(),
                                  padding: const EdgeInsets.fromLTRB(20, 6, 20, 100),
                                  itemCount: filteredList.length,
                                  itemBuilder: (context, index) {
                                    final item = filteredList[index];
                                    final isIncome = item.isIncome;
                                    final cat = item.assignedCategory;

                                    return Dismissible(
                                      key: Key(item.id),
                                      direction: DismissDirection.endToStart,
                                      background: Container(
                                        alignment: Alignment.centerRight,
                                        padding: const EdgeInsets.only(right: 20),
                                        decoration: BoxDecoration(
                                          color: AppColors.expenseRed,
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        child: const Icon(
                                          Icons.delete_outline_rounded,
                                          color: Colors.white,
                                        ),
                                      ),
                                      onDismissed: (_) => widget.onDeleteTransaction(item),
                                      child: Padding(
                                        padding: const EdgeInsets.only(bottom: 8),
                                        child: ArcadeCard(
                                          onTap: () => _showSlipDetails(context, item),
                                          borderColor: isIncome
                                              ? AppColors.emerald.withValues(alpha: 0.5)
                                              : (cat?.color.withValues(alpha: 0.5) ?? AppColors.borderDark),
                                          shadowColor: isIncome
                                              ? AppColors.emeraldShadow.withValues(alpha: 0.35)
                                              : (cat?.shadowColor.withValues(alpha: 0.35) ?? AppColors.shadowDefault),
                                          depth: 2.5,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 14,
                                            vertical: 10,
                                          ),
                                          child: Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(10),
                                                decoration: BoxDecoration(
                                                  color: isIncome
                                                      ? AppColors.emerald.withValues(alpha: 0.15)
                                                      : (cat?.bgColor ?? item.bankColor.withValues(alpha: 0.15)),
                                                  borderRadius: BorderRadius.circular(12),
                                                  border: Border.all(
                                                    color: isIncome ? AppColors.emerald : (cat?.color ?? item.bankColor),
                                                    width: 1.2,
                                                  ),
                                                ),
                                                child: Icon(
                                                  isIncome
                                                      ? Icons.arrow_downward_rounded
                                                      : (cat?.icon ?? Icons.receipt_long_rounded),
                                                  color: isIncome
                                                      ? AppColors.emerald
                                                      : (cat?.color ?? item.bankColor),
                                                  size: 20,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      item.receiverName.isNotEmpty
                                                          ? item.receiverName
                                                          : (isIncome ? 'รายรับ' : 'รายการใช้จ่าย'),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                      style: const TextStyle(
                                                        fontSize: 13.5,
                                                        fontWeight: FontWeight.bold,
                                                        color: AppColors.textPrimary,
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
                                                        style: TextStyle(
                                                          fontSize: 10.5,
                                                          color: isIncome ? AppColors.emerald : AppColors.goldShadow,
                                                          fontWeight: FontWeight.w600,
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
                                                    '${isIncome ? '+' : '-'}฿ ${currencyFormatter.format(item.amount)}',
                                                    style: TextStyle(
                                                      fontSize: 14.5,
                                                      fontWeight: FontWeight.w900,
                                                      color: isIncome
                                                          ? AppColors.emerald
                                                          : AppColors.vaultTributum,
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
          ],
        ),
      ),
    );
  }

  Widget _buildViewTab({
    required String title,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.gold : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 17,
              color: isActive ? Colors.black87 : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w900,
                color: isActive ? Colors.black87 : AppColors.textSecondary,
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.15) : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? color : AppColors.borderDark,
            width: isSelected ? 1.8 : 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 14,
                color: isSelected ? color : AppColors.textSecondary,
              ),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                color: isSelected ? color : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSlipDetails(BuildContext context, ExpenseCardItem item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(
            top: BorderSide(color: AppColors.borderDark, width: 2.5),
            left: BorderSide(color: AppColors.borderDark, width: 2.5),
            right: BorderSide(color: AppColors.borderDark, width: 2.5),
          ),
        ),
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  item.isIncome ? '🪙 รายละเอียดรายรับ' : '📜 รายละเอียดสลิป',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildDetailRow('ผู้รับ/แหล่งเงิน:', item.receiverName),
            _buildDetailRow(
              'จำนวนเงิน:',
              '${item.isIncome ? '+' : '-'}฿ ${NumberFormat('#,##0.00').format(item.amount)}',
              valueColor: item.isIncome ? AppColors.emerald : AppColors.vaultTributum,
            ),
            _buildDetailRow('ธนาคาร/ช่องทาง:', item.bankName),
            _buildDetailRow(
              'วันและเวลา:',
              DateFormat('dd/MM/yyyy HH:mm น.').format(item.dateTime),
            ),
            if (item.referenceNo.isNotEmpty)
              _buildDetailRow('เลขที่อ้างอิง:', item.referenceNo),
            if (item.note != null && item.note!.isNotEmpty)
              _buildDetailRow('บันทึก:', item.note!),
            if (item.assignedCategory != null)
              _buildDetailRow('หมวดหมู่:', item.assignedCategory!.thaiTitle),

            if (item.imagePath != null && File(item.imagePath!).existsSync()) ...[
              const SizedBox(height: 14),
              const Text(
                'รูปสลิปต้นฉบับ:',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(
                  File(item.imagePath!),
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ],
            const SizedBox(height: 18),
            ArcadeButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                widget.onDeleteTransaction(item);
              },
              backgroundColor: AppColors.expenseRed,
              shadowColor: AppColors.expenseRedShadow,
              textColor: Colors.white,
              icon: Icons.delete_forever_rounded,
              label: 'ลบรายการนี้ออกจากบันทึก',
              height: 44,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: valueColor ?? AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
