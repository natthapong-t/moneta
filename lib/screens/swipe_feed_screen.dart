import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../core/constants/categories.dart';
import '../core/theme/app_theme.dart';
import '../models/expense_card_item.dart';
import '../widgets/corner_target_box.dart';
import '../widgets/swipeable_slip_card.dart';
import '../widgets/vault_details_sheet.dart';
import '../widgets/arcade_button.dart';
import '../widgets/arcade_badge.dart';
import '../services/slip_parser_service.dart';

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
  });

  @override
  State<SwipeFeedScreen> createState() => _SwipeFeedScreenState();
}

class _SwipeFeedScreenState extends State<SwipeFeedScreen> {
  late List<ExpenseCardItem> _pendingCards;
  final List<ExpenseCardItem> _categorizedCards = [];
  CornerPosition? _hoveredCorner;
  int _laterHoverSide = 0; // -1 = left, 1 = right, 0 = none

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

  void _openScanOptionsSheet() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.document_scanner_rounded,
                      color: AppColors.gold,
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
                          fontWeight: FontWeight.bold,
                          color: AppColors.marbleWhite,
                        ),
                      ),
                      Text(
                        'วิเคราะห์สลิปและคัดกรองอัตโนมัติ On-Device',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Option 1: Auto-scan device gallery
              ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 4,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: AppColors.gold, width: 1.2),
                ),
                tileColor: AppColors.gold.withValues(alpha: 0.08),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.gold,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: Colors.black,
                    size: 20,
                  ),
                ),
                title: const Text(
                  'กวาดหาสลิปในเครื่องอัตโนมัติ (Auto-Scan)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.gold,
                  ),
                ),
                subtitle: const Text(
                  'ขอสิทธิ์คลังภาพ และค้นหาเฉพาะรูปที่เป็นสลิปเข้าสู่สำรับทันที',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
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
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 4,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: AppColors.surfaceLight),
                ),
                tileColor: AppColors.surfaceLight.withValues(alpha: 0.3),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFA855F7).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.photo_library_rounded,
                    color: Color(0xFFA855F7),
                    size: 20,
                  ),
                ),
                title: const Text(
                  'เลือกรูปสลิปจากอัลบั้มด้วยตนเอง (Manual Pick)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.marbleWhite,
                  ),
                ),
                subtitle: const Text(
                  'เปิดหน้าเลือกรูปภาพเพื่อเลือกรูปสลิปที่ต้องการทีละหลายรูป',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _importSlipsFromGallery();
                },
              ),
            ],
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
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: AppColors.gold, width: 1.2),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 48,
                    height: 48,
                    child: CircularProgressIndicator(
                      color: AppColors.gold,
                      strokeWidth: 3,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'กำลังกวาดค้นหาสลิปในเครื่อง...',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.marbleWhite,
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
                      color: AppColors.textSecondary,
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
            backgroundColor: AppColors.surface,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: AppColors.borderDark),
            ),
            content: const Text(
              'ไม่พบรูปภาพใหม่หรือยังไม่ได้รับสิทธิ์เข้าถึงคลังภาพ',
              style: TextStyle(
                color: AppColors.textPrimary,
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
          backgroundColor: AppColors.surface,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: AppColors.gold),
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
              color: AppColors.marbleWhite,
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
        backgroundColor: AppColors.surface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.gold, width: 1.5),
        ),
        content: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.goldShadow,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'กำลังอ่านข้อมูลจาก ${imagePaths.length} สลิป...',
                style: const TextStyle(
                  color: AppColors.textPrimary,
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
        backgroundColor: AppColors.surface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.gold),
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
            color: AppColors.marbleWhite,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

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
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.refresh_rounded,
                  color: AppColors.goldShadow,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'รีเซ็ตข้อมูลตัวอย่างและล้างยอดเรียบร้อยแล้ว',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.surface,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.gold, width: 2.0),
          ),
        ),
      );
    }
  }

  void _onCardCategorized(ExpenseCardItem item, CornerPosition corner) {
    final cat = ExpenseCategory.defaultCorners.firstWhere(
      (c) => c.corner == corner,
    );

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

    HapticFeedback.mediumImpact();
    final skippedItem = _pendingCards.removeAt(0);
    setState(() {
      _pendingCards.add(skippedItem);
      _laterHoverSide = 0;
      _hoveredCorner = null;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.surface,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFD97706), width: 2.0),
          ),
          content: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFD97706), width: 1.5),
                ),
                child: const Icon(
                  Icons.schedule_rounded,
                  color: Color(0xFFD97706),
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'พักสลิปนี้ไว้จัดการทีหลัง',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      '${skippedItem.receiverName} (${NumberFormat('#,##0.00', 'th_TH').format(skippedItem.amount)} ฿) ข้ามไปท้ายคิว',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.borderDark, width: 2.2),
            boxShadow: const [
              BoxShadow(
                color: AppColors.shadowDefault,
                offset: Offset(0, 6),
                blurRadius: 0,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
                  border: Border(
                    bottom: BorderSide(color: AppColors.border, width: 1.5),
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
                            fontSize: 14,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(ctx).pop(),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.border, width: 1.2),
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Slip Image viewer with InteractiveViewer
              Padding(
                padding: const EdgeInsets.all(14),
                child: item.imagePath != null && item.imagePath!.isNotEmpty
                    ? Container(
                        constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(context).size.height * 0.45,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border, width: 1.2),
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
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
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
                    const SizedBox(height: 4),
                    _buildInspectRow('วัน-เวลา', dateFormatter.format(item.dateTime)),
                    if (item.note != null && item.note!.isNotEmpty) ...[
                      const SizedBox(height: 4),
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
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
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

  ExpenseCategory _getCategory(CornerPosition corner) {
    return ExpenseCategory.defaultCorners.firstWhere((c) => c.corner == corner);
  }

  @override
  Widget build(BuildContext context) {
    final tavernaCat = _getCategory(CornerPosition.topLeft);
    final quadrigaCat = _getCategory(CornerPosition.topRight);
    final forumCat = _getCategory(CornerPosition.bottomLeft);
    final tributumCat = _getCategory(CornerPosition.bottomRight);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            // Minimal Swipe Arena HUD (Deck Queue Counter - Only when deck has cards)
            if (_pendingCards.isNotEmpty)
              Positioned(
                top: 8,
                left: 20,
                right: 20,
                child: Center(
                  child: ArcadeBadge(
                    label: 'คิวสลิป ${_pendingCards.length} ใบ',
                    icon: Icons.style_rounded,
                    color: AppColors.surface,
                    borderColor: AppColors.borderDark,
                    shadowColor: AppColors.shadowDefault,
                    iconColor: AppColors.goldShadow,
                    textColor: AppColors.textPrimary,
                    depth: 2.0,
                    fontSize: 12,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                  ),
                ),
              ),

            // Top-Left Vault (1. Food) - Moved up to 40 for more vertical arena space!
            Positioned(
              top: 40,
              left: 12,
              child: CornerTargetBox(
                category: tavernaCat,
                isHovered: _hoveredCorner == CornerPosition.topLeft,
                totalAmount: _categoryTotals[tavernaCat.id] ?? 0.0,
                itemCount: _categoryCounts[tavernaCat.id] ?? 0,
                onTap: () => _openVaultDetails(tavernaCat),
              ),
            ),

            // Top-Right Vault (2. Transport) - Moved up to 40 for more vertical arena space!
            Positioned(
              top: 40,
              right: 12,
              child: CornerTargetBox(
                category: quadrigaCat,
                isHovered: _hoveredCorner == CornerPosition.topRight,
                totalAmount: _categoryTotals[quadrigaCat.id] ?? 0.0,
                itemCount: _categoryCounts[quadrigaCat.id] ?? 0,
                onTap: () => _openVaultDetails(quadrigaCat),
              ),
            ),

            // Bottom-Left Vault (3. Shopping) - Positioned at 128 to clear action bar & dock
            Positioned(
              bottom: 128,
              left: 12,
              child: CornerTargetBox(
                category: forumCat,
                isHovered: _hoveredCorner == CornerPosition.bottomLeft,
                totalAmount: _categoryTotals[forumCat.id] ?? 0.0,
                itemCount: _categoryCounts[forumCat.id] ?? 0,
                onTap: () => _openVaultDetails(forumCat),
              ),
            ),

            // Bottom-Right Vault (4. Bills) - Positioned at 128 to clear action bar & dock
            Positioned(
              bottom: 128,
              right: 12,
              child: CornerTargetBox(
                category: tributumCat,
                isHovered: _hoveredCorner == CornerPosition.bottomRight,
                totalAmount: _categoryTotals[tributumCat.id] ?? 0.0,
                itemCount: _categoryCounts[tributumCat.id] ?? 0,
                onTap: () => _openVaultDetails(tributumCat),
              ),
            ),

            // Left Lateral Drag-out Target (Only shown when dragging left to later)
            if (_pendingCards.isNotEmpty && _laterHoverSide == -1)
              Positioned(
                left: 6,
                top: 260,
                bottom: 260,
                child: Center(
                  child: _buildSideDropZone(isLeft: true),
                ),
              ),

            // Right Lateral Drag-out Target (Only shown when dragging right to later)
            if (_pendingCards.isNotEmpty && _laterHoverSide == 1)
              Positioned(
                right: 6,
                top: 260,
                bottom: 260,
                child: Center(
                  child: _buildSideDropZone(isLeft: false),
                ),
              ),

            // Center Arena Card Stack: Positioned smoothly between vaults
            Positioned.fill(
              top: 122,
              bottom: 205,
              child: Center(
                child: _pendingCards.isEmpty
                    ? _buildCompletionState()
                    : _buildCardStack(),
              ),
            ),

            // Arcade Action Controls Bar - Pure Swiping Controls (Undo, Inspect, Skip)
            Positioned(
              bottom: 74,
              left: 20,
              right: 20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 1. Undo 3D Button (Recovers last categorized slip)
                  Opacity(
                    opacity: _categorizedCards.isEmpty ? 0.4 : 1.0,
                    child: ArcadeButton(
                      onPressed: _categorizedCards.isEmpty
                          ? null
                          : _undoLastAction,
                      color: AppColors.surface,
                      shadowColor: AppColors.shadowDefault,
                      borderColor: AppColors.borderDark,
                      borderWidth: 2.0,
                      depth: 3.5,
                      borderRadius: BorderRadius.circular(16),
                      padding: EdgeInsets.zero,
                      width: 52,
                      height: 48,
                      child: const Icon(
                        Icons.undo_rounded,
                        size: 23,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // 2. Inspect 3D Button (View original slip high-res & zoom)
                  Opacity(
                    opacity: _pendingCards.isEmpty ? 0.4 : 1.0,
                    child: ArcadeButton(
                      onPressed: _pendingCards.isEmpty
                          ? null
                          : _openInspectTopSlip,
                      color: AppColors.surface,
                      shadowColor: AppColors.shadowDefault,
                      borderColor: AppColors.borderDark,
                      borderWidth: 2.0,
                      depth: 3.5,
                      borderRadius: BorderRadius.circular(16),
                      padding: EdgeInsets.zero,
                      width: 56,
                      height: 48,
                      child: const Icon(
                        Icons.image_search_rounded,
                        size: 24,
                        color: AppColors.vaultQuadrigaShadow,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // 3. Skip / Later 3D Button (Pushes current slip to back of deck)
                  Opacity(
                    opacity: _pendingCards.isEmpty ? 0.4 : 1.0,
                    child: ArcadeButton(
                      onPressed: _pendingCards.isEmpty
                          ? null
                          : _skipTopCardToLater,
                      color: const Color(0xFFFEF3C7),
                      shadowColor: const Color(0xFFD97706),
                      borderColor: const Color(0xFFD97706),
                      borderWidth: 2.0,
                      depth: 3.5,
                      borderRadius: BorderRadius.circular(16),
                      padding: EdgeInsets.zero,
                      width: 52,
                      height: 48,
                      child: const Icon(
                        Icons.schedule_rounded,
                        size: 22,
                        color: Color(0xFFB45309),
                      ),
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
    final double yOffset = index * 7.0;

    return Transform.translate(
      offset: Offset(0, yOffset),
      child: Transform.scale(
        scale: scale,
        child: SwipeableSlipCard(
          key: ValueKey(item.id),
          item: item,
          isTopCard: isTop,
          onProximityChanged: (corner) {
            setState(() {
              _hoveredCorner = corner;
            });
          },
          onLaterSideChanged: (side) {
            if (_laterHoverSide != side) {
              setState(() {
                _laterHoverSide = side;
              });
            }
          },
          onSkipLater: _skipTopCardToLater,
          onCategorized: (corner) {
            _onCardCategorized(item, corner);
          },
        ),
      ),
    );
  }

  Widget _buildSideDropZone({required bool isLeft}) {
    return GestureDetector(
      onTap: _pendingCards.isEmpty ? null : _skipTopCardToLater,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF3C7),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFD97706),
            width: 2.2,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0xFFB45309),
              offset: Offset(0, 3.5),
              blurRadius: 0,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isLeft
                  ? Icons.keyboard_double_arrow_left_rounded
                  : Icons.keyboard_double_arrow_right_rounded,
              size: 20,
              color: const Color(0xFFB45309),
            ),
            const SizedBox(height: 6),
            RotatedBox(
              quarterTurns: isLeft ? 3 : 1,
              child: const Text(
                'ปล่อยเพื่อพัก',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF92400E),
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 6),
            const Icon(
              Icons.schedule_rounded,
              size: 16,
              color: Color(0xFFB45309),
            ),
          ],
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
      width: 295,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderDark, width: 2.2),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowDefault,
            offset: Offset(0, 6),
            blurRadius: 0,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Cartoon Victory Trophy
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.gold,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.goldShadow, width: 2.5),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.goldShadow,
                  offset: Offset(0, 3),
                  blurRadius: 0,
                ),
              ],
            ),
            child: const Icon(
              Icons.emoji_events_rounded,
              color: Color(0xFF1E293B),
              size: 44,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'จัดหมวดหมู่ครบแล้ว! 🎉',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'คุณได้จัดหมวดหมู่สลิป ${_categorizedCards.length} รายการเรียบร้อยแล้ว',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border, width: 1.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'ยอดรวมทั้งหมด',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  '฿ ${currencyFormatter.format(grandTotal)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: AppColors.vaultTributumShadow,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Big Chunky Duolingo Green Button
          ArcadeButton(
            onPressed: _isScanningSlips ? null : _openScanOptionsSheet,
            color: AppColors.vaultTributum,
            shadowColor: AppColors.vaultTributumShadow,
            borderColor: AppColors.vaultTributumShadow,
            borderWidth: 2.0,
            depth: 4.0,
            borderRadius: BorderRadius.circular(16),
            padding: const EdgeInsets.symmetric(vertical: 13),
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

          // Secondary Arcade Deck Button
          ArcadeButton(
            onPressed: _resetToSample,
            color: AppColors.surface,
            shadowColor: AppColors.shadowDefault,
            borderColor: AppColors.borderDark,
            borderWidth: 1.8,
            depth: 3.0,
            borderRadius: BorderRadius.circular(16),
            padding: const EdgeInsets.symmetric(vertical: 11),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(
                  Icons.refresh_rounded,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
                SizedBox(width: 6),
                Text(
                  'โหลดชุดสลิปตัวอย่างใหม่',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
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
