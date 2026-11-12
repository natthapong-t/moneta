import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../core/constants/categories.dart';
import '../core/theme/app_theme.dart';
import '../models/expense_card_item.dart';
import '../services/expense_storage_service.dart';
import '../services/slip_parser_service.dart';
import '../widgets/living_creature_widget.dart';
import '../widgets/moneta_goddess_widget.dart';
import '../widgets/vault_details_sheet.dart';
import 'splash_screen.dart';

class SwipeFeedScreen extends StatefulWidget {
  final List<ExpenseCardItem>? pendingCards;
  final List<ExpenseCardItem>? categorizedCards;
  final Function(ExpenseCardItem item, CornerPosition corner)? onCategorized;
  final VoidCallback? onUndo;
  final Function(ExpenseCardItem item)? onQuickAdded;
  final Function(List<ExpenseCardItem> items)? onSlipsImported;
  final VoidCallback? onResetToSample;
  final Function(ExpenseCardItem item)? onRestoreItem;
  final VoidCallback? onStartBackgroundScan;
  final VoidCallback? onSkipLater;

  const SwipeFeedScreen({
    super.key,
    this.pendingCards,
    this.categorizedCards,
    this.onCategorized,
    this.onUndo,
    this.onQuickAdded,
    this.onSlipsImported,
    this.onResetToSample,
    this.onRestoreItem,
    this.onStartBackgroundScan,
    this.onSkipLater,
  });

  @override
  State<SwipeFeedScreen> createState() => _SwipeFeedScreenState();
}

class _SwipeFeedScreenState extends State<SwipeFeedScreen> {
  late List<ExpenseCardItem> _pendingCards;
  final List<ExpenseCardItem> _categorizedCards = [];
  CornerPosition? _hoveredCorner;
  bool _isCornersSwapped = false;

  final Map<String, double> _categoryTotals = {
    'food': 0.0,
    'transport': 0.0,
    'shopping': 0.0,
    'bills': 0.0,
  };

  final Map<String, int> _categoryCounts = {
    'food': 0,
    'transport': 0,
    'shopping': 0,
    'bills': 0,
  };

  final _slipParser = SlipParserService();
  bool _isScanningSlips = false;
  StateSetter? _progressDialogStateSetter;

  @override
  void initState() {
    super.initState();
    if (widget.pendingCards != null) {
      _pendingCards = List.from(widget.pendingCards!);
    } else {
      _pendingCards = List.from(ExpenseCardItem.sampleCards);
    }
    if (widget.categorizedCards != null) {
      _categorizedCards.clear();
      _categorizedCards.addAll(widget.categorizedCards!);
    }
    _recalculateTotals();
  }

  @override
  void didUpdateWidget(covariant SwipeFeedScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pendingCards != null) {
      setState(() {
        _pendingCards = List.from(widget.pendingCards!);
      });
    }
    if (widget.categorizedCards != null) {
      setState(() {
        _categorizedCards.clear();
        _categorizedCards.addAll(widget.categorizedCards!);
        _recalculateTotals();
      });
    }
  }

  void _recalculateTotals() {
    for (var key in _categoryTotals.keys) {
      _categoryTotals[key] = 0.0;
      _categoryCounts[key] = 0;
    }
    for (var item in _categorizedCards) {
      if (item.assignedCategory != null) {
        final id = item.assignedCategory!.id;
        _categoryTotals[id] = (_categoryTotals[id] ?? 0.0) + item.amount;
        _categoryCounts[id] = (_categoryCounts[id] ?? 0) + 1;
      }
    }
  }

  ExpenseCategory _getCategory(CornerPosition corner) {
    if (!_isCornersSwapped) {
      return ExpenseCategory.defaultCorners.firstWhere((c) => c.corner == corner);
    }
    // Swapped layout for convenience
    switch (corner) {
      case CornerPosition.topLeft:
        return ExpenseCategory.defaultCorners.firstWhere((c) => c.corner == CornerPosition.topRight);
      case CornerPosition.topRight:
        return ExpenseCategory.defaultCorners.firstWhere((c) => c.corner == CornerPosition.topLeft);
      case CornerPosition.bottomLeft:
        return ExpenseCategory.defaultCorners.firstWhere((c) => c.corner == CornerPosition.bottomRight);
      case CornerPosition.bottomRight:
        return ExpenseCategory.defaultCorners.firstWhere((c) => c.corner == CornerPosition.bottomLeft);
    }
  }

  void _toggleCornerSwap() {
    HapticFeedback.mediumImpact();
    setState(() {
      _isCornersSwapped = !_isCornersSwapped;
    });
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.mintioCard,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.mintioIndigo, width: 1.2),
        ),
        duration: const Duration(seconds: 1),
        content: Row(
          children: [
            const Icon(Icons.swap_horiz_rounded, color: AppColors.mintioIndigo, size: 20),
            const SizedBox(width: 8),
            Text(
              _isCornersSwapped ? 'สลับมุมซ้าย-ขวาแล้ว' : 'กลับสู่ตำแหน่งมุมมาตรฐานแล้ว',
              style: const TextStyle(
                color: AppColors.mintioTextPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onCardCategorized(ExpenseCardItem item, CornerPosition corner) {
    final cat = _getCategory(corner);

    setState(() {
      _pendingCards.removeWhere((c) => c.id == item.id);
      final updatedItem = item.copyWith(assignedCategory: cat);
      _categorizedCards.add(updatedItem);

      _categoryTotals[cat.id] = (_categoryTotals[cat.id] ?? 0.0) + item.amount;
      _categoryCounts[cat.id] = (_categoryCounts[cat.id] ?? 0) + 1;
      _hoveredCorner = null;
    });

    widget.onCategorized?.call(item, corner);
  }

  void _skipTopCardToLater() {
    if (_pendingCards.isEmpty) return;

    HapticFeedback.lightImpact();
    final skippedItem = _pendingCards.removeAt(0);
    setState(() {
      _pendingCards.add(skippedItem);
      _hoveredCorner = null;
    });

    widget.onSkipLater?.call();
  }

  void _undoLastAction() {
    if (_categorizedCards.isEmpty) return;

    final lastItem = _categorizedCards.removeLast();
    final cat = lastItem.assignedCategory;

    setState(() {
      _pendingCards.insert(0, lastItem);
      if (cat != null) {
        _categoryTotals[cat.id] =
            (_categoryTotals[cat.id] ?? 0.0) - lastItem.amount;
        _categoryCounts[cat.id] = (_categoryCounts[cat.id] ?? 1) - 1;
      }
    });

    HapticFeedback.lightImpact();
    widget.onUndo?.call();
  }

  void _resetToSample() {
    HapticFeedback.mediumImpact();
    setState(() {
      _pendingCards = List.from(ExpenseCardItem.sampleCards);
      _categorizedCards.clear();
      for (var key in _categoryTotals.keys) {
        _categoryTotals[key] = 0.0;
        _categoryCounts[key] = 0;
      }
      _hoveredCorner = null;
    });
    widget.onResetToSample?.call();

    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.refresh_rounded, color: AppColors.mintioIndigoLight, size: 18),
              SizedBox(width: 10),
              Text(
                'โหลดชุดสลิปตัวอย่างใหม่เรียบร้อยแล้ว',
                style: TextStyle(
                  color: AppColors.mintioTextPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.mintioCard,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: AppColors.mintioBorder, width: 1.2),
          ),
        ),
      );
    }
  }

  void _openInspectTopSlip() {
    if (_pendingCards.isEmpty) return;
    HapticFeedback.lightImpact();
    final item = _pendingCards.first;

    final currencyFormatter = NumberFormat('#,##0.00', 'th_TH');
    final dateFormatter = DateFormat('dd MMMM yyyy, HH:mm น.', 'th_TH');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SafeArea(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.mintioCard,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.mintioBorder, width: 1.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: const BoxDecoration(
                  color: AppColors.mintioMidnight,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
                  border: Border(
                    bottom: BorderSide(color: AppColors.mintioBorder, width: 1.2),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: item.bankColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          item.bankName,
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                            color: item.bankColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '฿ ${currencyFormatter.format(item.amount)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                            color: AppColors.mintioTextPrimary,
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(ctx).pop(),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.mintioCardElevated,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.mintioBorder, width: 1.2),
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          size: 16,
                          color: AppColors.mintioTextSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Slip Image viewer
              Padding(
                padding: const EdgeInsets.all(14),
                child: item.imagePath != null && item.imagePath!.isNotEmpty
                    ? Container(
                        constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(context).size.height * 0.45,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.mintioMidnight,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.mintioBorder, width: 1.2),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: InteractiveViewer(
                            panEnabled: true,
                            scaleEnabled: true,
                            minScale: 0.8,
                            maxScale: 3.5,
                            child: item.imagePath!.startsWith('assets/')
                                ? Image.asset(item.imagePath!, fit: BoxFit.contain)
                                : Image.file(File(item.imagePath!), fit: BoxFit.contain),
                          ),
                        ),
                      )
                    : Container(
                        height: 120,
                        alignment: Alignment.center,
                        child: const Text(
                          'สลิปนี้เป็นข้อมูลจำลอง (ไม่มีไฟล์ภาพ)',
                          style: TextStyle(
                            color: AppColors.mintioTextSecondary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12.5,
                          ),
                        ),
                      ),
              ),

              // Meta Details
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  children: [
                    _buildInspectRow('ผู้รับเงิน', item.receiverName),
                    const SizedBox(height: 6),
                    _buildInspectRow('วัน-เวลา', dateFormatter.format(item.dateTime)),
                    const SizedBox(height: 6),
                    _buildInspectRow('จ่ายให้ใคร', item.targetPerson.label),
                    if (item.note != null && item.note!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      _buildInspectRow('บันทึกช่วยจำ', item.note!),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInspectRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.mintioTextSecondary,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.bold,
            color: AppColors.mintioTextPrimary,
          ),
        ),
      ],
    );
  }

  void _openVaultDetails(ExpenseCategory cat) {
    HapticFeedback.lightImpact();
    final itemsInVault = _categorizedCards
        .where((c) => c.assignedCategory?.id == cat.id)
        .toList();

    VaultDetailsSheet.show(
      context: context,
      category: cat,
      items: itemsInVault,
      onRestoreItem: (item) {
        setState(() {
          _categorizedCards.removeWhere((c) => c.id == item.id);
          _pendingCards.insert(0, item.copyWith(assignedCategory: null));
          _categoryTotals[cat.id] =
              (_categoryTotals[cat.id] ?? 0.0) - item.amount;
          _categoryCounts[cat.id] = (_categoryCounts[cat.id] ?? 1) - 1;
        });
        widget.onRestoreItem?.call(item);
      },
    );
  }

  void _openScanOptionsSheet() async {
    HapticFeedback.lightImpact();
    int currentDays = await ExpenseStorageService.instance.getScanHistoryDays();
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          return SafeArea(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.mintioCard,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.mintioBorder, width: 1.5),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.mintioIndigo.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.document_scanner_rounded,
                          color: AppColors.mintioIndigo,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'นำเข้าสลิปธนาคาร',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              color: AppColors.mintioTextPrimary,
                            ),
                          ),
                          Text(
                            'ค้นหาเฉพาะสลิปธนาคาร ไม่สแกนภาพหน้าจอหรือรูปอื่น',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.mintioTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // History Window Scope Chips
                  const Text(
                    'กรอบเวลาย้อนหลัง',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.mintioTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildScopeChip(
                          label: '⚡ 7 วัน (แนะนำ)',
                          days: 7,
                          selectedDays: currentDays,
                          onTap: () {
                            setSheetState(() => currentDays = 7);
                            ExpenseStorageService.instance.setScanHistoryDays(7);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildScopeChip(
                          label: '🟢 วันนี้ (0d)',
                          days: 0,
                          selectedDays: currentDays,
                          onTap: () {
                            setSheetState(() => currentDays = 0);
                            ExpenseStorageService.instance.setScanHistoryDays(0);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildScopeChip(
                          label: '📅 30 วัน',
                          days: 30,
                          selectedDays: currentDays,
                          onTap: () {
                            setSheetState(() => currentDays = 30);
                            ExpenseStorageService.instance.setScanHistoryDays(30);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Option 1: Auto-scan device gallery
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: AppColors.mintioIndigo, width: 1.2),
                    ),
                    tileColor: AppColors.mintioIndigo.withValues(alpha: 0.1),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.mintioIndigo,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.auto_awesome_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    title: const Text(
                      'กวาดหาสลิปในเครื่องอัตโนมัติ',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.mintioTextPrimary,
                      ),
                    ),
                    subtitle: Text(
                      currentDays == 0
                          ? 'กวาดเฉพาะสลิปของวันนี้ รวดเร็วแบบเรียลไทม์'
                          : 'ค้นหาเฉพาะอัลบั้มธนาคารและสลิปย้อนหลัง $currentDays วัน',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.mintioTextSecondary,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      if (widget.onStartBackgroundScan != null) {
                        widget.onStartBackgroundScan!();
                      } else {
                        _autoScanDeviceGallery();
                      }
                    },
                  ),
                  const SizedBox(height: 12),

                  // Option 2: Manual Pick
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: AppColors.mintioBorder, width: 1.2),
                    ),
                    tileColor: AppColors.mintioMidnight,
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.mintioPurple.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.photo_library_rounded,
                        color: AppColors.mintioPurple,
                        size: 20,
                      ),
                    ),
                    title: const Text(
                      'เลือกรูปสลิปจากอัลบั้มด้วยตนเอง',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.mintioTextPrimary,
                      ),
                    ),
                    subtitle: const Text(
                      'เปิดหน้าเลือกรูปภาพเพื่อเลือกรูปสลิปที่ต้องการทีละหลายรูป',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.mintioTextSecondary,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      _importSlipsFromGallery();
                    },
                  ),
                  const SizedBox(height: 12),

                  // Option 3: Reset All Data (First Install Simulation)
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: AppColors.mintioRed.withValues(alpha: 0.35), width: 1.2),
                    ),
                    tileColor: AppColors.mintioRed.withValues(alpha: 0.08),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.mintioRed.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.restart_alt_rounded,
                        color: AppColors.mintioRed,
                        size: 20,
                      ),
                    ),
                    title: const Text(
                      'รีเซ็ตข้อมูลทั้งหมด (เหมือนเข้าครั้งแรก)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.mintioRed,
                      ),
                    ),
                    subtitle: const Text(
                      'ล้างรายการ ประวัติ และพาไปเริ่มหน้า Onboarding ใหม่',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.mintioTextSecondary,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      _confirmResetToFirstInstall();
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _confirmResetToFirstInstall() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.mintioCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.mintioBorder),
        ),
        title: const Text(
          'รีเซ็ตข้อมูลทั้งหมด?',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'ข้อมูลสลิป ประวัติการใช้งาน และการตั้งค่าทั้งหมดจะถูกล้าง เพื่อให้เหมือนเปิดแอปครั้งแรก',
          style: TextStyle(color: AppColors.mintioTextSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ยกเลิก', style: TextStyle(color: AppColors.mintioTextSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.mintioRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await ExpenseStorageService.instance.resetToFirstInstall();
              if (!mounted) return;
              Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const SplashScreen()),
                (route) => false,
              );
            },
            child: const Text('รีเซ็ตและเริ่มใหม่'),
          ),
        ],
      ),
    );
  }

  Widget _buildScopeChip({
    required String label,
    required int days,
    required int selectedDays,
    required VoidCallback onTap,
  }) {
    final isSelected = selectedDays == days;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.mintioIndigo.withValues(alpha: 0.25) : AppColors.mintioMidnight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.mintioIndigo : AppColors.mintioBorder,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.mintioTextSecondary,
          ),
        ),
      ),
    );
  }

  Future<void> _autoScanDeviceGallery() async {
    HapticFeedback.lightImpact();
    setState(() {
      _isScanningSlips = true;
    });

    int current = 0;
    int total = 0;
    int found = 0;

    // Show Progress Dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) {
          _progressDialogStateSetter = setDialogState;
          return Dialog(
            backgroundColor: AppColors.mintioCard,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: AppColors.mintioBorder, width: 1.2),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 44,
                    height: 44,
                    child: CircularProgressIndicator(
                      color: AppColors.mintioIndigo,
                      strokeWidth: 3,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'กำลังกวาดค้นหาสลิปในเครื่อง...',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.mintioTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    total > 0
                        ? 'วิเคราะห์รูปภาพ ($current/$total)\nพบสลิปธนาคารแล้ว $found ใบ'
                        : 'กำลังขอสิทธิ์และเข้าถึงคลังภาพล่าสุด...',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.mintioTextSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    try {
      final imagePaths = await _slipParser.scanDeviceGalleryImagePaths(
        limit: null,
      );
      total = imagePaths.length;
      if (mounted && _progressDialogStateSetter != null) {
        _progressDialogStateSetter!(() {});
      }

      if (imagePaths.isEmpty) {
        if (!mounted) return;
        Navigator.of(context, rootNavigator: true).pop();
        setState(() {
          _isScanningSlips = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.mintioCard,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: AppColors.mintioBorder),
            ),
            content: const Text(
              'ไม่พบรูปภาพใหม่หรือยังไม่ได้รับสิทธิ์เข้าถึงคลังภาพ',
              style: TextStyle(
                color: AppColors.mintioTextPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
        return;
      }

      final parsedItems = await _slipParser.parseSlipImages(
        imagePaths,
        onProgress: (c, t, f) {
          current = c;
          total = t;
          found = f;
          if (_progressDialogStateSetter != null) {
            _progressDialogStateSetter!(() {});
          }
        },
      );

      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();

      final uniqueItems = parsedItems.where((item) {
        final inPending = _pendingCards.any((p) => p.isDuplicateOf(item));
        final inCategorized = _categorizedCards.any(
          (c) => c.isDuplicateOf(item),
        );
        return !inPending && !inCategorized;
      }).toList();

      final int duplicatesSkipped = parsedItems.length - uniqueItems.length;

      setState(() {
        _isScanningSlips = false;
        if (uniqueItems.isNotEmpty) {
          _pendingCards.insertAll(0, uniqueItems);
          widget.onSlipsImported?.call(uniqueItems);
        }
      });

      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.mintioCard,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: AppColors.mintioIndigo),
          ),
          content: Text(
            uniqueItems.isNotEmpty
                ? (duplicatesSkipped > 0
                      ? 'กวาดพบสลิปใหม่ ${uniqueItems.length} ใบ (ข้ามสลิปซ้ำ $duplicatesSkipped ใบ)'
                      : 'กวาดพบสลิปใหม่ ${uniqueItems.length} ใบจากคลังภาพ พร้อมให้ปัดแล้ว!')
                : (duplicatesSkipped > 0
                      ? 'สลิปทั้ง $duplicatesSkipped ใบมีอยู่ในระบบแล้ว (ไม่เพิ่มซ้ำ)'
                      : 'กวาดตรวจแล้ว ${imagePaths.length} รูป แต่ไม่พบสลิปธนาคารใหม่'),
            style: const TextStyle(
              color: AppColors.mintioTextPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    } catch (e) {
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
      setState(() {
        _isScanningSlips = false;
      });
    }
  }

  Future<void> _importSlipsFromGallery() async {
    HapticFeedback.lightImpact();
    final imagePaths = await _slipParser.pickSlipImages();
    if (imagePaths.isEmpty) return;

    if (!mounted) return;
    setState(() {
      _isScanningSlips = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.mintioCard,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.mintioIndigo, width: 1.2),
        ),
        content: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.mintioIndigoLight,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'กำลังอ่านข้อมูลจาก ${imagePaths.length} สลิป...',
                style: const TextStyle(
                  color: AppColors.mintioTextPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 4),
      ),
    );

    final parsedItems = await _slipParser.parseSlipImages(imagePaths);

    if (!mounted) return;

    final uniqueItems = parsedItems.where((item) {
      final inPending = _pendingCards.any((p) => p.isDuplicateOf(item));
      final inCategorized = _categorizedCards.any((c) => c.isDuplicateOf(item));
      return !inPending && !inCategorized;
    }).toList();

    final int duplicatesSkipped = parsedItems.length - uniqueItems.length;

    setState(() {
      _isScanningSlips = false;
      if (uniqueItems.isNotEmpty) {
        _pendingCards.insertAll(0, uniqueItems);
        widget.onSlipsImported?.call(uniqueItems);
      }
    });

    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.mintioCard,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.mintioIndigo),
        ),
        content: Text(
          uniqueItems.isNotEmpty
              ? (duplicatesSkipped > 0
                    ? 'เพิ่มสลิปใหม่ ${uniqueItems.length} รายการ (ข้ามสลิปซ้ำ $duplicatesSkipped รายการ)'
                    : 'สแกนพบสลิป ${uniqueItems.length} รายการ พร้อมให้ปัดเข้าหมวดหมู่แล้ว!')
              : (duplicatesSkipped > 0
                    ? 'สลิปทั้ง $duplicatesSkipped รายการมีอยู่ในระบบแล้ว (ไม่เพิ่มซ้ำ)'
                    : 'ตรวจไม่พบข้อมูลสลิปที่สมบูรณ์ในรูปที่เลือก'),
          style: const TextStyle(
            color: AppColors.mintioTextPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tavernaCat = _getCategory(CornerPosition.topLeft);
    final quadrigaCat = _getCategory(CornerPosition.topRight);
    final forumCat = _getCategory(CornerPosition.bottomLeft);
    final tributumCat = _getCategory(CornerPosition.bottomRight);

    return Scaffold(
      backgroundColor: AppColors.mintioMidnight,
      body: SafeArea(
        child: Stack(
          children: [
            // Top HUD Bar
            Positioned(
              top: 8,
              left: 20,
              right: 20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Deck Queue Pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.mintioCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.mintioBorder, width: 1.2),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.style_rounded,
                          size: 15,
                          color: AppColors.mintioIndigoLight,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _pendingCards.isNotEmpty
                              ? 'คิวสลิป ${_pendingCards.length} ใบ'
                              : 'คัดแยกครบแล้ว',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppColors.mintioTextPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Conversational UX Hint & Swap Corner Action
                  InkWell(
                    onTap: _toggleCornerSwap,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: _isCornersSwapped
                            ? AppColors.mintioIndigo.withValues(alpha: 0.2)
                            : AppColors.mintioCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _isCornersSwapped ? AppColors.mintioIndigo : AppColors.mintioBorder,
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.swap_horiz_rounded,
                            size: 14,
                            color: _isCornersSwapped ? AppColors.mintioIndigo : AppColors.mintioTextSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'สลับมุม',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: _isCornersSwapped ? AppColors.mintioIndigo : AppColors.mintioTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Top-Left Vault
            Positioned(
              top: 48,
              left: 12,
              child: _MintioCornerTargetBox(
                category: tavernaCat,
                isHovered: _hoveredCorner == CornerPosition.topLeft,
                totalAmount: _categoryTotals[tavernaCat.id] ?? 0.0,
                itemCount: _categoryCounts[tavernaCat.id] ?? 0,
                onTap: () => _openVaultDetails(tavernaCat),
              ),
            ),

            // Top-Right Vault
            Positioned(
              top: 48,
              right: 12,
              child: _MintioCornerTargetBox(
                category: quadrigaCat,
                isHovered: _hoveredCorner == CornerPosition.topRight,
                totalAmount: _categoryTotals[quadrigaCat.id] ?? 0.0,
                itemCount: _categoryCounts[quadrigaCat.id] ?? 0,
                onTap: () => _openVaultDetails(quadrigaCat),
              ),
            ),

            // Bottom-Left Vault
            Positioned(
              bottom: 110,
              left: 12,
              child: _MintioCornerTargetBox(
                category: forumCat,
                isHovered: _hoveredCorner == CornerPosition.bottomLeft,
                totalAmount: _categoryTotals[forumCat.id] ?? 0.0,
                itemCount: _categoryCounts[forumCat.id] ?? 0,
                onTap: () => _openVaultDetails(forumCat),
              ),
            ),

            // Bottom-Right Vault
            Positioned(
              bottom: 110,
              right: 12,
              child: _MintioCornerTargetBox(
                category: tributumCat,
                isHovered: _hoveredCorner == CornerPosition.bottomRight,
                totalAmount: _categoryTotals[tributumCat.id] ?? 0.0,
                itemCount: _categoryCounts[tributumCat.id] ?? 0,
                onTap: () => _openVaultDetails(tributumCat),
              ),
            ),

            // Center Arena Card Stack
            Positioned.fill(
              top: 130,
              bottom: 190,
              child: Center(
                child: _pendingCards.isEmpty
                    ? _buildCompletionState()
                    : _buildCardStack(),
              ),
            ),

            // Action Controls Bar (Undo, Inspect, Skip "ข้าม")
            Positioned(
              bottom: 54,
              left: 20,
              right: 20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 1. Undo Button
                  Opacity(
                    opacity: _categorizedCards.isEmpty ? 0.35 : 1.0,
                    child: _buildActionPill(
                      icon: Icons.undo_rounded,
                      label: 'ย้อนกลับ',
                      onTap: _categorizedCards.isEmpty ? null : _undoLastAction,
                    ),
                  ),
                  const SizedBox(width: 14),

                  // 2. Inspect Button
                  Opacity(
                    opacity: _pendingCards.isEmpty ? 0.35 : 1.0,
                    child: _buildActionPill(
                      icon: Icons.image_search_rounded,
                      label: 'ดูสลิป',
                      accentColor: AppColors.mintioIndigoLight,
                      onTap: _pendingCards.isEmpty ? null : _openInspectTopSlip,
                    ),
                  ),
                  const SizedBox(width: 14),

                  // 3. Skip Button ("ข้าม")
                  Opacity(
                    opacity: _pendingCards.isEmpty ? 0.35 : 1.0,
                    child: _buildActionPill(
                      icon: Icons.skip_next_rounded,
                      label: 'ข้าม',
                      accentColor: AppColors.mintioIndigo,
                      onTap: _pendingCards.isEmpty ? null : _skipTopCardToLater,
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

  Widget _buildActionPill({
    required IconData icon,
    required String label,
    Color? accentColor,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.mintioCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.mintioBorder, width: 1.2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: accentColor ?? AppColors.mintioTextSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: accentColor ?? AppColors.mintioTextPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardStack() {
    return Stack(
      alignment: Alignment.center,
      children: [
        for (
          int i = (_pendingCards.length > 3 ? 2 : _pendingCards.length - 1);
          i >= 0;
          i--
        )
          _buildStackedCard(i),
      ],
    );
  }

  Widget _buildStackedCard(int index) {
    final item = _pendingCards[index];
    final isTop = index == 0;

    final double scale = 1.0 - (index * 0.05);
    final double yOffset = index * 8.0;

    return Transform.translate(
      offset: Offset(0, yOffset),
      child: Transform.scale(
        scale: scale,
        child: _MintioSwipeableCard(
          key: ValueKey(item.id),
          item: item,
          isTopCard: isTop,
          onProximityChanged: (corner) {
            setState(() {
              _hoveredCorner = corner;
            });
          },
          onCategorized: (corner) {
            _onCardCategorized(item, corner);
          },
          onTargetPersonChanged: (person) {
            setState(() {
              _pendingCards[index] = item.copyWith(targetPerson: person);
            });
          },
        ),
      ),
    );
  }

  Widget _buildCompletionState() {
    double grandTotal = 0;
    for (var val in _categoryTotals.values) {
      grandTotal += val;
    }

    final currencyFormatter = NumberFormat('#,##0.00', 'th_TH');

    return Container(
      width: 300,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.mintioCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.mintioBorder, width: 1.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Moneta Goddess + Sacred Goose empty state
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
            'จัดหมวดหมู่ครบแล้ว! 🎉',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w900,
              color: AppColors.mintioTextPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'คุณได้จัดหมวดหมู่สลิป ${_categorizedCards.length} รายการเรียบร้อยแล้ว',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: AppColors.mintioTextSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.mintioMidnight,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.mintioBorder, width: 1.2),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'ยอดรวมทั้งหมด',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.mintioTextSecondary,
                  ),
                ),
                Text(
                  '฿ ${currencyFormatter.format(grandTotal)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: AppColors.mintioMint,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Primary Scan Button
          ElevatedButton(
            onPressed: _isScanningSlips ? null : _openScanOptionsSheet,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.mintioIndigo,
              foregroundColor: Colors.white,
              elevation: 0,
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _isScanningSlips
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons.document_scanner_rounded,
                        size: 20,
                        color: Colors.white,
                      ),
                const SizedBox(width: 8),
                const Text(
                  'นำเข้าและสแกนสลิปใหม่',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Secondary Reload Sample Button
          OutlinedButton(
            onPressed: _resetToSample,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.mintioTextSecondary,
              side: const BorderSide(color: AppColors.mintioBorder, width: 1.2),
              minimumSize: const Size.fromHeight(44),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(
                  Icons.refresh_rounded,
                  size: 18,
                  color: AppColors.mintioTextSecondary,
                ),
                SizedBox(width: 6),
                Text(
                  'โหลดชุดสลิปตัวอย่างใหม่',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.mintioTextSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Sleek Dark Mintio Corner Target Box
class _MintioCornerTargetBox extends StatelessWidget {
  final ExpenseCategory category;
  final bool isHovered;
  final double totalAmount;
  final int itemCount;
  final VoidCallback? onTap;

  const _MintioCornerTargetBox({
    required this.category,
    required this.isHovered,
    required this.totalAmount,
    required this.itemCount,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat('#,##0', 'th_TH');

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: isHovered ? 1.05 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutBack,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 138,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.mintioCard,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isHovered
                  ? category.color
                  : category.color.withValues(alpha: 0.35),
              width: isHovered ? 2.0 : 1.2,
            ),
            boxShadow: isHovered
                ? [
                    BoxShadow(
                      color: category.color.withValues(alpha: 0.3),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                  ]
                : const [],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Icon + Eyes + Count
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: category.color.withValues(alpha: 0.18),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          category.icon,
                          size: 14,
                          color: category.color,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '#${category.romanNumeral}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: category.color,
                        ),
                      ),
                    ],
                  ),
                  if (itemCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: category.color.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$itemCount ใบ',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          color: category.color,
                        ),
                      ),
                    )
                  else
                    BlinkingCreatureEyes(
                      width: 28,
                      height: 16,
                      pupilColor: category.color,
                    ),
                ],
              ),
              const SizedBox(height: 5),

              // Thai Title
              Text(
                category.thaiTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w900,
                  color: AppColors.mintioTextPrimary,
                ),
              ),

              // Latin Subtitle
              Text(
                category.latinTitle,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: AppColors.mintioTextSecondary,
                ),
              ),
              const SizedBox(height: 3),

              // Running Total
              Text(
                '฿ ${currencyFormatter.format(totalAmount)}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: category.color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Mintio Dark Theme Swipeable Slip Card
class _MintioSwipeableCard extends StatefulWidget {
  final ExpenseCardItem item;
  final bool isTopCard;
  final Function(CornerPosition corner) onCategorized;
  final Function(CornerPosition? corner) onProximityChanged;
  final Function(TargetPerson person) onTargetPersonChanged;

  const _MintioSwipeableCard({
    super.key,
    required this.item,
    required this.isTopCard,
    required this.onCategorized,
    required this.onProximityChanged,
    required this.onTargetPersonChanged,
  });

  @override
  State<_MintioSwipeableCard> createState() => _MintioSwipeableCardState();
}

class _MintioSwipeableCardState extends State<_MintioSwipeableCard>
    with SingleTickerProviderStateMixin {
  Offset _dragOffset = Offset.zero;
  CornerPosition? _activeCorner;

  late AnimationController _springController;
  late Animation<Offset> _springAnimation;

  @override
  void initState() {
    super.initState();
    _springController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );

    _springController.addListener(() {
      setState(() {
        _dragOffset = _springAnimation.value;
      });
    });
  }

  @override
  void dispose() {
    _springController.dispose();
    super.dispose();
  }

  CornerPosition? _calculateHoverCorner(Offset offset) {
    if (offset.dy.abs() < 65.0 || offset.dx.abs() < 45.0) {
      return null;
    }
    if (offset.dx < 0 && offset.dy < 0) {
      return CornerPosition.topLeft;
    } else if (offset.dx > 0 && offset.dy < 0) {
      return CornerPosition.topRight;
    } else if (offset.dx < 0 && offset.dy > 0) {
      return CornerPosition.bottomLeft;
    } else if (offset.dx > 0 && offset.dy > 0) {
      return CornerPosition.bottomRight;
    }
    return null;
  }

  void _onPanStart(DragStartDetails details) {
    if (!widget.isTopCard) return;
    _springController.stop();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!widget.isTopCard) return;

    setState(() {
      _dragOffset += details.delta;
    });

    final newCorner = _calculateHoverCorner(_dragOffset);
    if (newCorner != _activeCorner) {
      if (newCorner != null) {
        HapticFeedback.selectionClick();
      }
      _activeCorner = newCorner;
      widget.onProximityChanged(_activeCorner);
    }
  }

  void _onPanEnd(DragEndDetails details) {
    if (!widget.isTopCard) return;

    CornerPosition? targetCorner = _activeCorner;
    final velocity = details.velocity.pixelsPerSecond;
    final speed = velocity.distance;

    if (targetCorner == null && speed > 240) {
      final vx = velocity.dx;
      final vy = velocity.dy;

      if (vx < 0 && vy < -100) {
        targetCorner = CornerPosition.topLeft;
      } else if (vx > 0 && vy < -100) {
        targetCorner = CornerPosition.topRight;
      } else if (vx < 0 && vy > 100) {
        targetCorner = CornerPosition.bottomLeft;
      } else if (vx > 0 && vy > 100) {
        targetCorner = CornerPosition.bottomRight;
      }
    }

    if (targetCorner != null) {
      HapticFeedback.mediumImpact();
      widget.onProximityChanged(targetCorner);

      final endOffset = Offset(
        targetCorner == CornerPosition.topLeft ||
                targetCorner == CornerPosition.bottomLeft
            ? -550.0
            : 550.0,
        targetCorner == CornerPosition.topLeft ||
                targetCorner == CornerPosition.topRight
            ? -650.0
            : 650.0,
      );

      _springAnimation = Tween<Offset>(begin: _dragOffset, end: endOffset).animate(
        CurvedAnimation(parent: _springController, curve: Curves.easeInCubic),
      );

      _springController.duration = const Duration(milliseconds: 160);
      _springController.forward(from: 0.0).then((_) {
        widget.onProximityChanged(null);
        widget.onCategorized(targetCorner!);
      });
    } else {
      widget.onProximityChanged(null);
      _activeCorner = null;

      _springAnimation = Tween<Offset>(begin: _dragOffset, end: Offset.zero).animate(
        CurvedAnimation(parent: _springController, curve: Curves.easeOutBack),
      );

      _springController.duration = const Duration(milliseconds: 320);
      _springController.forward(from: 0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat('#,##0.00', 'th_TH');
    final dateFormatter = DateFormat('dd MMM yyyy, HH:mm น.', 'th_TH');

    ExpenseCategory? activeCat;
    if (_activeCorner != null) {
      activeCat = ExpenseCategory.defaultCorners.firstWhere(
        (c) => c.corner == _activeCorner,
      );
    }

    final double rotation = (_dragOffset.dx / 1200).clamp(-0.25, 0.25);

    return GestureDetector(
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: Transform.translate(
        offset: _dragOffset,
        child: Transform.rotate(
          angle: rotation,
          child: Container(
            width: 275,
            decoration: BoxDecoration(
              color: AppColors.mintioCard,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: activeCat != null
                    ? activeCat.color
                    : AppColors.mintioBorder,
                width: activeCat != null ? 2.5 : 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: activeCat != null
                      ? activeCat.color.withValues(alpha: 0.3)
                      : Colors.black.withValues(alpha: 0.45),
                  offset: const Offset(0, 8),
                  blurRadius: 18,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: widget.item.imagePath != null && widget.item.imagePath!.isNotEmpty
                  ? _buildSlipWithActualImage(currencyFormatter, activeCat)
                  : _buildSyntheticSlipContent(currencyFormatter, dateFormatter, activeCat),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSlipWithActualImage(
    NumberFormat currencyFormatter,
    ExpenseCategory? activeCat,
  ) {
    final person = widget.item.targetPerson;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Image View with overlaid chips
        SizedBox(
          height: 220,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Container(
                color: AppColors.mintioMidnight,
                child: widget.item.imagePath!.startsWith('assets/')
                    ? Image.asset(widget.item.imagePath!, fit: BoxFit.cover)
                    : Image.file(File(widget.item.imagePath!), fit: BoxFit.cover),
              ),
              // Floating Bank Chip
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.mintioCard.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: widget.item.bankColor, width: 1.2),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: widget.item.bankColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        widget.item.bankName,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: widget.item.bankColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Floating Amount Pill
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.mintioMidnight.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.mintioBorder, width: 1.2),
                  ),
                  child: Text(
                    '฿ ${currencyFormatter.format(widget.item.amount)}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: AppColors.mintioTextPrimary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Target Person Selector & Receiver row
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.item.receiverName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                  color: AppColors.mintioTextPrimary,
                ),
              ),
              const SizedBox(height: 8),
              _buildTargetPersonSelector(person),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSyntheticSlipContent(
    NumberFormat currencyFormatter,
    DateFormat dateFormatter,
    ExpenseCategory? activeCat,
  ) {
    final person = widget.item.targetPerson;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Clean Bank Badge & Time
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: widget.item.bankColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: widget.item.bankColor.withValues(alpha: 0.5),
                    width: 1.2,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: widget.item.bankColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      widget.item.bankName,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: widget.item.bankColor,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                DateFormat('HH:mm น.').format(widget.item.dateTime),
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.mintioTextMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Receiver Name in Crisp White
          Text(
            widget.item.receiverName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 16.5,
              fontWeight: FontWeight.w800,
              color: AppColors.mintioTextPrimary,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 2),

          // Date Subtitle
          Text(
            dateFormatter.format(widget.item.dateTime),
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.mintioTextSecondary,
            ),
          ),
          const SizedBox(height: 12),

          // Formatted Amount in Bold White ฿XXX
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              const Text(
                '฿',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.mintioTextSecondary,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  currencyFormatter.format(widget.item.amount),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: AppColors.mintioTextPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Note Field Container
          if (widget.item.note != null && widget.item.note!.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.mintioMidnight,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.mintioBorder, width: 1),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.edit_note_rounded,
                    size: 15,
                    color: AppColors.mintioIndigoLight,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      widget.item.note!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.mintioTextSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),

          // Divider
          Container(
            height: 1,
            color: AppColors.mintioBorder.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 10),

          // Compact "จ่ายให้ใครนะ" selector
          _buildTargetPersonSelector(person),
          const SizedBox(height: 8),

          // Hint Footer
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(
                  Icons.open_with_rounded,
                  size: 11,
                  color: AppColors.mintioTextMuted,
                ),
                SizedBox(width: 4),
                Text(
                  'ปัดเข้า 4 มุมเพื่อแยกหมวด',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.mintioTextMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTargetPersonSelector(TargetPerson currentPerson) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'จ่ายให้ใครนะ',
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            color: AppColors.mintioTextSecondary,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: TargetPerson.values.map((p) {
            final isSelected = currentPerson == p;
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  widget.onTargetPersonChanged(p);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.symmetric(horizontal: 2.5),
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? p.color.withValues(alpha: 0.22)
                        : AppColors.mintioMidnight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? p.color : AppColors.mintioBorder,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(p.icon, size: 12, color: isSelected ? p.color : AppColors.mintioTextMuted),
                      const SizedBox(width: 3.5),
                      Text(
                        p.label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                          color: isSelected ? p.color : AppColors.mintioTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
