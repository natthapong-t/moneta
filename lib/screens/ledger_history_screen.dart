import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../core/constants/categories.dart';
import '../core/theme/app_theme.dart';
import '../models/expense_card_item.dart';
import '../widgets/arcade_calendar_view.dart';
import '../widgets/daily_transactions_sheet.dart';
import '../widgets/moneta_goddess_widget.dart';

sealed class _LedgerListItem {}

class _DateHeaderItem extends _LedgerListItem {
  final String dateText;
  _DateHeaderItem(this.dateText);
}

class _TransactionItem extends _LedgerListItem {
  final ExpenseCardItem item;
  _TransactionItem(this.item);
}

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
  bool _isCalendarView = true; // Default to calendar view

  List<_LedgerListItem> _buildGroupedList(List<ExpenseCardItem> items) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateFormatter = DateFormat('d MMMM yyyy', 'th_TH');

    final result = <_LedgerListItem>[];
    String? currentGroup;

    for (final item in items) {
      final itemDate = DateTime(
        item.dateTime.year,
        item.dateTime.month,
        item.dateTime.day,
      );

      String header;
      if (itemDate == today) {
        header = 'วันนี้';
      } else if (itemDate == yesterday) {
        header = 'เมื่อวานนี้';
      } else {
        header = dateFormatter.format(item.dateTime);
      }

      if (currentGroup != header) {
        currentGroup = header;
        result.add(_DateHeaderItem(header));
      }
      result.add(_TransactionItem(item));
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat('#,##0.00', 'th_TH');

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

    // Sort descending by date
    filteredList.sort((a, b) => b.dateTime.compareTo(a.dateTime));

    double totalFilteredIncome = 0;
    double totalFilteredExpense = 0;
    for (final item in filteredList) {
      if (item.isIncome) {
        totalFilteredIncome += item.amount;
      } else {
        totalFilteredExpense += item.amount;
      }
    }

    final groupedItems = _buildGroupedList(filteredList);

    return Scaffold(
      backgroundColor: AppColors.mintioMidnight,
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'บันทึกการเงิน',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: AppColors.mintioTextPrimary,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'ประวัติธุรกรรมและปฏิทินรายวัน',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.mintioTextSecondary,
                        ),
                      ),
                    ],
                  ),

                  // Quick Action Buttons (+ รายรับ, + รายจ่าย)
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: widget.onAddIncome,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.mintioMint,
                          foregroundColor: Colors.black,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Row(
                          children: const [
                            Text('🪙', style: TextStyle(fontSize: 13)),
                            SizedBox(width: 4),
                            Text(
                              '+ รับ',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: widget.onAddExpense,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.mintioCard,
                          foregroundColor: AppColors.mintioTextPrimary,
                          side: const BorderSide(color: AppColors.mintioBorder, width: 1.2),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Row(
                          children: const [
                            Icon(Icons.add_rounded, size: 15, color: AppColors.mintioCoral),
                            SizedBox(width: 2),
                            Text(
                              '+ จ่าย',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                color: AppColors.mintioTextPrimary,
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

            // View Switcher Tabs: [📅 ปฏิทินรายวัน]  [📋 รายการทั้งหมด]
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.mintioCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.mintioBorder, width: 1.2),
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
                            style: const TextStyle(
                              color: AppColors.mintioTextPrimary,
                              fontSize: 13.5,
                            ),
                            cursorColor: AppColors.mintioIndigo,
                            decoration: InputDecoration(
                              hintText: 'ค้นหาชื่อร้าน, แหล่งที่มา, โน้ต...',
                              hintStyle: const TextStyle(
                                color: AppColors.mintioTextMuted,
                                fontSize: 12.5,
                              ),
                              prefixIcon: const Icon(
                                Icons.search_rounded,
                                color: AppColors.mintioTextSecondary,
                                size: 20,
                              ),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(
                                        Icons.clear_rounded,
                                        size: 18,
                                        color: AppColors.mintioTextSecondary,
                                      ),
                                      onPressed: () => setState(() => _searchQuery = ''),
                                    )
                                  : null,
                              filled: true,
                              fillColor: AppColors.mintioCard,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(
                                  color: AppColors.mintioBorder,
                                  width: 1.2,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(
                                  color: AppColors.mintioBorder,
                                  width: 1.2,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(
                                  color: AppColors.mintioIndigo,
                                  width: 1.5,
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
                                activeColor: AppColors.mintioIndigo,
                                onTap: () => setState(() => _selectedCategoryId = null),
                              ),
                              const SizedBox(width: 8),
                              _buildFilterChip(
                                label: '🪙 รายรับ',
                                isSelected: _selectedCategoryId == 'income',
                                activeColor: AppColors.mintioMint,
                                onTap: () => setState(() => _selectedCategoryId = 'income'),
                              ),
                              const SizedBox(width: 8),
                              for (final cat in ExpenseCategory.defaultCorners) ...[
                                _buildFilterChip(
                                  label: cat.thaiTitle,
                                  icon: cat.icon,
                                  isSelected: _selectedCategoryId == cat.id,
                                  activeColor: cat.color,
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
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.mintioCard,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.mintioBorder, width: 1.2),
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
                                        color: AppColors.mintioTextSecondary,
                                      ),
                                    ),
                                    Text(
                                      '${filteredList.length} รายการ',
                                      style: const TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.mintioTextPrimary,
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
                                          color: AppColors.mintioMint,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                    ],
                                    Text(
                                      '-฿${currencyFormatter.format(totalFilteredExpense)}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w900,
                                        color: AppColors.mintioTextPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),

                        // List of items (grouped by date)
                        Expanded(
                          child: filteredList.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: const [
                                          SacredGoosePixelWidget(size: 54),
                                          SizedBox(width: 12),
                                          MonetaGoddessPixelWidget(size: 100, mood: GoddessMood.happy),
                                        ],
                                      ),
                                      const SizedBox(height: 14),
                                      const Text(
                                        'ยังไม่มีรายการที่ตรงกับเงื่อนไข',
                                        style: TextStyle(
                                          color: AppColors.mintioTextPrimary,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      const Text(
                                        'เริ่มต้นด้วยการปัดสลิปหรือเพิ่มรายการใหม่ได้เลยนะ',
                                        style: TextStyle(
                                          color: AppColors.mintioTextSecondary,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : ListView.builder(
                                  physics: const BouncingScrollPhysics(),
                                  padding: const EdgeInsets.fromLTRB(20, 6, 20, 100),
                                  itemCount: groupedItems.length,
                                  itemBuilder: (context, index) {
                                    final entry = groupedItems[index];

                                    if (entry is _DateHeaderItem) {
                                      return Padding(
                                        padding: const EdgeInsets.fromLTRB(4, 14, 4, 6),
                                        child: Text(
                                          entry.dateText,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.mintioTextSecondary,
                                            letterSpacing: 0.2,
                                          ),
                                        ),
                                      );
                                    }

                                    final item = (entry as _TransactionItem).item;
                                    final isIncome = item.isIncome;
                                    final cat = item.assignedCategory;
                                    final person = item.targetPerson;
                                    final timeStr = DateFormat('HH:mm น.').format(item.dateTime);

                                    return Dismissible(
                                      key: Key(item.id),
                                      direction: DismissDirection.endToStart,
                                      background: Container(
                                        alignment: Alignment.centerRight,
                                        padding: const EdgeInsets.only(right: 20),
                                        margin: const EdgeInsets.only(bottom: 8),
                                        decoration: BoxDecoration(
                                          color: AppColors.expenseRed,
                                          borderRadius: BorderRadius.circular(18),
                                        ),
                                        child: const Icon(
                                          Icons.delete_outline_rounded,
                                          color: Colors.white,
                                        ),
                                      ),
                                      onDismissed: (_) => widget.onDeleteTransaction(item),
                                      child: Padding(
                                        padding: const EdgeInsets.only(bottom: 8),
                                        child: InkWell(
                                          onTap: () => _showSlipDetails(context, item),
                                          borderRadius: BorderRadius.circular(18),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 14,
                                              vertical: 12,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.mintioCard,
                                              borderRadius: BorderRadius.circular(18),
                                              border: Border.all(
                                                color: isIncome
                                                    ? AppColors.mintioMint.withValues(alpha: 0.35)
                                                    : (cat?.color.withValues(alpha: 0.35) ?? AppColors.mintioBorder),
                                                width: 1.2,
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                // Category Icon
                                                Container(
                                                  width: 42,
                                                  height: 42,
                                                  decoration: BoxDecoration(
                                                    color: isIncome
                                                        ? AppColors.mintioMint.withValues(alpha: 0.16)
                                                        : (cat?.color.withValues(alpha: 0.16) ?? item.bankColor.withValues(alpha: 0.16)),
                                                    borderRadius: BorderRadius.circular(14),
                                                    border: Border.all(
                                                      color: isIncome
                                                          ? AppColors.mintioMint.withValues(alpha: 0.4)
                                                          : (cat?.color.withValues(alpha: 0.4) ?? item.bankColor),
                                                      width: 1.2,
                                                    ),
                                                  ),
                                                  child: Icon(
                                                    isIncome
                                                        ? Icons.arrow_downward_rounded
                                                        : (cat?.icon ?? Icons.receipt_long_rounded),
                                                    color: isIncome
                                                        ? AppColors.mintioMint
                                                        : (cat?.color ?? item.bankColor),
                                                    size: 20,
                                                  ),
                                                ),
                                                const SizedBox(width: 12),

                                                // Middle details
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Row(
                                                        children: [
                                                          Expanded(
                                                            child: Text(
                                                              item.receiverName.isNotEmpty
                                                                  ? item.receiverName
                                                                  : (isIncome ? 'รายรับ' : 'รายการใช้จ่าย'),
                                                              maxLines: 1,
                                                              overflow: TextOverflow.ellipsis,
                                                              style: const TextStyle(
                                                                fontSize: 13.5,
                                                                fontWeight: FontWeight.bold,
                                                                color: AppColors.mintioTextPrimary,
                                                              ),
                                                            ),
                                                          ),
                                                          const SizedBox(width: 6),
                                                          // Target Person Pill Badge
                                                          if (!isIncome)
                                                            Container(
                                                              padding: const EdgeInsets.symmetric(
                                                                horizontal: 6,
                                                                vertical: 2,
                                                              ),
                                                              decoration: BoxDecoration(
                                                                color: person.color.withValues(alpha: 0.16),
                                                                borderRadius: BorderRadius.circular(10),
                                                                border: Border.all(
                                                                  color: person.color.withValues(alpha: 0.35),
                                                                  width: 1,
                                                                ),
                                                              ),
                                                              child: Row(
                                                                mainAxisSize: MainAxisSize.min,
                                                                children: [
                                                                  Icon(person.icon, size: 9, color: person.color),
                                                                  const SizedBox(width: 2.5),
                                                                  Text(
                                                                    person.label,
                                                                    style: TextStyle(
                                                                      fontSize: 9,
                                                                      fontWeight: FontWeight.bold,
                                                                      color: person.color,
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                        ],
                                                      ),
                                                      const SizedBox(height: 3),
                                                      Row(
                                                        children: [
                                                          Text(
                                                            item.bankName,
                                                            style: TextStyle(
                                                              fontSize: 11,
                                                              fontWeight: FontWeight.bold,
                                                              color: item.bankColor,
                                                            ),
                                                          ),
                                                          const SizedBox(width: 6),
                                                          Text(
                                                            '• $timeStr',
                                                            style: const TextStyle(
                                                              fontSize: 10.5,
                                                              color: AppColors.mintioTextMuted,
                                                            ),
                                                          ),
                                                          if (item.note != null && item.note!.isNotEmpty) ...[
                                                            const SizedBox(width: 6),
                                                            Expanded(
                                                              child: Text(
                                                                '• ${item.note!}',
                                                                maxLines: 1,
                                                                overflow: TextOverflow.ellipsis,
                                                                style: const TextStyle(
                                                                  fontSize: 10.5,
                                                                  color: AppColors.mintioTextSecondary,
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(width: 10),

                                                // Amount
                                                Column(
                                                  crossAxisAlignment: CrossAxisAlignment.end,
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Text(
                                                      '${isIncome ? '+' : '-'}฿${currencyFormatter.format(item.amount)}',
                                                      style: TextStyle(
                                                        fontSize: 14.5,
                                                        fontWeight: FontWeight.w900,
                                                        color: isIncome
                                                            ? AppColors.mintioMint
                                                            : AppColors.mintioTextPrimary,
                                                      ),
                                                    ),
                                                    if (item.imagePath != null)
                                                      const Padding(
                                                        padding: EdgeInsets.only(top: 2),
                                                        child: Icon(
                                                          Icons.photo_rounded,
                                                          size: 13,
                                                          color: AppColors.mintioTextMuted,
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              ],
                                            ),
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
          color: isActive ? AppColors.mintioIndigo : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive ? Colors.white : AppColors.mintioTextSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isActive ? FontWeight.w900 : FontWeight.w600,
                color: isActive ? Colors.white : AppColors.mintioTextSecondary,
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
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withValues(alpha: 0.2) : AppColors.mintioCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? activeColor : AppColors.mintioBorder,
            width: isSelected ? 1.6 : 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 13,
                color: isSelected ? activeColor : AppColors.mintioTextSecondary,
              ),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                color: isSelected ? activeColor : AppColors.mintioTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSlipDetails(BuildContext context, ExpenseCardItem item) {
    final person = item.targetPerson;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: AppColors.mintioCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(
            top: BorderSide(color: AppColors.mintioBorder, width: 1.5),
            left: BorderSide(color: AppColors.mintioBorder, width: 1.5),
            right: BorderSide(color: AppColors.mintioBorder, width: 1.5),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(22, 14, 22, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  item.isIncome ? '🪙 รายละเอียดรายรับ' : '📜 รายละเอียดสลิป',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppColors.mintioTextPrimary,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  icon: const Icon(Icons.close_rounded, color: AppColors.mintioTextSecondary),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildDetailRow('ผู้รับ/แหล่งเงิน:', item.receiverName),
            _buildDetailRow(
              'จำนวนเงิน:',
              '${item.isIncome ? '+' : '-'}฿ ${NumberFormat('#,##0.00').format(item.amount)}',
              valueColor: item.isIncome ? AppColors.mintioMint : AppColors.mintioTextPrimary,
            ),
            _buildDetailRow('ธนาคาร/ช่องทาง:', item.bankName),
            _buildDetailRow(
              'วันและเวลา:',
              DateFormat('dd/MM/yyyy HH:mm น.').format(item.dateTime),
            ),
            if (!item.isIncome)
              _buildDetailRow('จ่ายให้ใคร:', '${person.label} (${person.name})', valueColor: person.color),
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
                  color: AppColors.mintioTextSecondary,
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
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                widget.onDeleteTransaction(item);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.mintioMidnight,
                foregroundColor: AppColors.expenseRed,
                side: const BorderSide(color: AppColors.expenseRed, width: 1.2),
                elevation: 0,
                minimumSize: const Size.fromHeight(46),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.delete_forever_rounded, size: 18, color: AppColors.expenseRed),
                  SizedBox(width: 6),
                  Text(
                    'ลบรายการนี้ออกจากบันทึก',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.expenseRed,
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

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12.5, color: AppColors.mintioTextSecondary),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: valueColor ?? AppColors.mintioTextPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
