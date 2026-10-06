import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../core/constants/categories.dart';
import '../core/theme/app_theme.dart';
import '../models/expense_card_item.dart';
import '../widgets/corner_target_box.dart';
import '../widgets/quick_add_sheet.dart';
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

  const SwipeFeedScreen({
    super.key,
    this.pendingCards,
    this.categorizedCards,
    this.onCategorized,
    this.onUndo,
    this.onQuickAdded,
    this.onSlipsImported,
  });

  @override
  State<SwipeFeedScreen> createState() => _SwipeFeedScreenState();
}

class _SwipeFeedScreenState extends State<SwipeFeedScreen> {
  late List<ExpenseCardItem> _pendingCards;
  final List<ExpenseCardItem> _categorizedCards = [];
  CornerPosition? _hoveredCorner;

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
                        style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Option 1: Auto-scan device gallery
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
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
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _autoScanDeviceGallery();
                },
              ),
              const SizedBox(height: 12),

              // Option 2: Manual Pick
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
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
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
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
                    child: CircularProgressIndicator(color: AppColors.gold, strokeWidth: 3),
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
                    style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary, height: 1.4),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    try {
      final imagePaths = await _slipParser.scanDeviceGalleryImagePaths(limit: 50);
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
          const SnackBar(
            backgroundColor: AppColors.surface,
            content: Text('ไม่พบรูปภาพใหม่หรือยังไม่ได้รับสิทธิ์เข้าถึงคลังภาพ'),
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

      setState(() {
        _isScanningSlips = false;
        if (parsedItems.isNotEmpty) {
          _pendingCards.insertAll(0, parsedItems);
          widget.onSlipsImported?.call(parsedItems);
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
            parsedItems.isNotEmpty
                ? 'กวาดพบสลิปใหม่ ${parsedItems.length} ใบจากคลังภาพ พร้อมให้ปัดแล้ว!'
                : 'กวาดตรวจแล้ว ${imagePaths.length} รูป แต่ไม่พบสลิปธนาคารใหม่',
            style: const TextStyle(color: AppColors.marbleWhite, fontWeight: FontWeight.bold),
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
        backgroundColor: AppColors.surfaceLight,
        content: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.gold),
            ),
            const SizedBox(width: 12),
            Text(
              'กำลังอ่านข้อมูลจาก ${imagePaths.length} สลิป...',
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ],
        ),
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
      ),
    );

    final parsedItems = await _slipParser.parseSlipImages(imagePaths);

    if (!mounted) return;
    setState(() {
      _isScanningSlips = false;
      if (parsedItems.isNotEmpty) {
        _pendingCards.insertAll(0, parsedItems);
        widget.onSlipsImported?.call(parsedItems);
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
          parsedItems.isNotEmpty
              ? 'สแกนพบสลิป ${parsedItems.length} รายการ พร้อมให้ปัดเข้าหมวดหมู่แล้ว!'
              : 'ตรวจไม่พบข้อมูลสลิปที่สมบูรณ์ในรูปที่เลือก',
          style: const TextStyle(color: AppColors.marbleWhite, fontWeight: FontWeight.bold),
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
    setState(() {
      _pendingCards = List.from(ExpenseCardItem.sampleCards);
      _categorizedCards.clear();
      for (var key in _categoryTotals.keys) {
        _categoryTotals[key] = 0.0;
        _categoryCounts[key] = 0;
      }
      _hoveredCorner = null;
    });
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

  void _undoLastAction() {
    if (_categorizedCards.isEmpty) return;

    final lastItem = _categorizedCards.removeLast();
    final cat = lastItem.assignedCategory;

    setState(() {
      _pendingCards.insert(0, lastItem);
      if (cat != null) {
        _categoryTotals[cat.id] =
            (_categoryTotals[cat.id] ?? 0.0) - lastItem.amount;
        _categoryCounts[cat.id] =
            (_categoryCounts[cat.id] ?? 1) - 1;
      }
    });

    HapticFeedback.lightImpact();
    widget.onUndo?.call();
  }

  void _openQuickAdd() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => QuickAddSheet(
        onCardCreated: (newItem) {
          setState(() {
            _pendingCards.insert(0, newItem);
          });
          HapticFeedback.lightImpact();
          widget.onQuickAdded?.call(newItem);
        },
      ),
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
          _categoryCounts[cat.id] =
              (_categoryCounts[cat.id] ?? 1) - 1;
        });
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
            // Top Navigation & Cartoon Moneta Header
            Positioned(
              top: 6,
              left: 14,
              right: 14,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: AppColors.gold,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppColors.goldShadow,
                            width: 2.0,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: AppColors.goldShadow,
                              offset: Offset(0, 2.5),
                              blurRadius: 0,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.monetization_on_rounded,
                          color: Color(0xFF1E293B),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'MONETA',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.0,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            'ปัดสลิป จัดการค่าใช้จ่าย',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      // Streak Badge - Cartoon 3D Flame Pill
                      ArcadeBadge(
                        label: '7 วัน',
                        leading: const Text('🔥', style: TextStyle(fontSize: 12)),
                        color: const Color(0xFFFFF7ED),
                        borderColor: const Color(0xFFF97316),
                        shadowColor: const Color(0xFFEA580C),
                        textColor: const Color(0xFFEA580C),
                        depth: 2.0,
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      ),
                      const SizedBox(width: 6),

                      // Pending Cards Pill - Cartoon 3D Counter
                      ArcadeBadge(
                        label: '${_pendingCards.length} สลิป',
                        icon: Icons.style_rounded,
                        color: AppColors.surface,
                        borderColor: AppColors.borderDark,
                        shadowColor: AppColors.shadowDefault,
                        iconColor: AppColors.vaultQuadrigaShadow,
                        textColor: AppColors.textPrimary,
                        depth: 2.0,
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Top-Left Vault (1. Food)
            Positioned(
              top: 60,
              left: 14,
              child: CornerTargetBox(
                category: tavernaCat,
                isHovered: _hoveredCorner == CornerPosition.topLeft,
                totalAmount: _categoryTotals[tavernaCat.id] ?? 0.0,
                itemCount: _categoryCounts[tavernaCat.id] ?? 0,
                onTap: () => _openVaultDetails(tavernaCat),
              ),
            ),

            // Top-Right Vault (2. Transport)
            Positioned(
              top: 60,
              right: 14,
              child: CornerTargetBox(
                category: quadrigaCat,
                isHovered: _hoveredCorner == CornerPosition.topRight,
                totalAmount: _categoryTotals[quadrigaCat.id] ?? 0.0,
                itemCount: _categoryCounts[quadrigaCat.id] ?? 0,
                onTap: () => _openVaultDetails(quadrigaCat),
              ),
            ),

            // Bottom-Left Vault (3. Shopping) - Positioned at 136 to clear action bar & dock
            Positioned(
              bottom: 136,
              left: 14,
              child: CornerTargetBox(
                category: forumCat,
                isHovered: _hoveredCorner == CornerPosition.bottomLeft,
                totalAmount: _categoryTotals[forumCat.id] ?? 0.0,
                itemCount: _categoryCounts[forumCat.id] ?? 0,
                onTap: () => _openVaultDetails(forumCat),
              ),
            ),

            // Bottom-Right Vault (4. Bills) - Positioned at 136 to clear action bar & dock
            Positioned(
              bottom: 136,
              right: 14,
              child: CornerTargetBox(
                category: tributumCat,
                isHovered: _hoveredCorner == CornerPosition.bottomRight,
                totalAmount: _categoryTotals[tributumCat.id] ?? 0.0,
                itemCount: _categoryCounts[tributumCat.id] ?? 0,
                onTap: () => _openVaultDetails(tributumCat),
              ),
            ),

            // Center Card Stack or Cartoon Triumph Empty State
            Center(
              child: _pendingCards.isEmpty
                  ? _buildRomanTriumphState()
                  : _buildCardStack(),
            ),

            // Arcade Action Controls Bar - Floating cleanly above the bottom dock at 76!
            Positioned(
              bottom: 76,
              left: 16,
              right: 16,
              child: Row(
                children: [
                  // 1. Undo 3D Button (Only active when cards categorized)
                  Opacity(
                    opacity: _categorizedCards.isEmpty ? 0.45 : 1.0,
                    child: ArcadeButton(
                      onPressed: _categorizedCards.isEmpty ? null : _undoLastAction,
                      color: AppColors.surface,
                      shadowColor: AppColors.shadowDefault,
                      borderColor: AppColors.borderDark,
                      borderWidth: 2.0,
                      depth: 3.5,
                      borderRadius: BorderRadius.circular(14),
                      padding: EdgeInsets.zero,
                      width: 46,
                      height: 46,
                      child: const Icon(
                        Icons.undo_rounded,
                        size: 22,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // 2. Quick Add 3D Button - Big Chunky Arcade Gold
                  Expanded(
                    child: ArcadeButton(
                      onPressed: _openQuickAdd,
                      color: AppColors.gold,
                      shadowColor: AppColors.goldShadow,
                      borderColor: AppColors.goldShadow,
                      borderWidth: 2.0,
                      depth: 3.5,
                      borderRadius: BorderRadius.circular(16),
                      height: 46,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(
                            Icons.bolt_rounded,
                            size: 20,
                            color: Color(0xFF1E293B),
                          ),
                          SizedBox(width: 4),
                          Text(
                            'บันทึกด่วน',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // 3. Scan Slips 3D Button - Duolingo Sky Blue
                  ArcadeButton(
                    onPressed: _isScanningSlips ? null : _openScanOptionsSheet,
                    color: AppColors.vaultQuadriga,
                    shadowColor: AppColors.vaultQuadrigaShadow,
                    borderColor: AppColors.vaultQuadrigaShadow,
                    borderWidth: 2.0,
                    depth: 3.5,
                    borderRadius: BorderRadius.circular(16),
                    height: 46,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _isScanningSlips
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(
                                Icons.document_scanner_rounded,
                                size: 19,
                                color: Colors.white,
                              ),
                        const SizedBox(width: 6),
                        const Text(
                          'สแกน',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  // 4. Reset Deck 3D Button - Slate Pill
                  ArcadeButton(
                    onPressed: _resetToSample,
                    color: AppColors.surface,
                    shadowColor: AppColors.shadowDefault,
                    borderColor: AppColors.borderDark,
                    borderWidth: 1.8,
                    depth: 3.0,
                    borderRadius: BorderRadius.circular(14),
                    padding: EdgeInsets.zero,
                    width: 46,
                    height: 46,
                    child: const Icon(
                      Icons.refresh_rounded,
                      size: 20,
                      color: AppColors.textSecondary,
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
        for (int i = (_pendingCards.length > 3 ? 2 : _pendingCards.length - 1);
            i >= 0;
            i--)
          _buildStackedCard(i),
      ],
    );
  }

  Widget _buildStackedCard(int index) {
    final item = _pendingCards[index];
    final isTop = index == 0;

    final double scale = 1.0 - (index * 0.05);
    final double yOffset = index * 12.0;

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
          onCategorized: (corner) {
            _onCardCategorized(item, corner);
          },
        ),
      ),
    );
  }

  Widget _buildRomanTriumphState() {
    double grandTotal = 0;
    for (var val in _categoryTotals.values) {
      grandTotal += val;
    }

    final currencyFormatter = NumberFormat('#,##0.00', 'th_TH');

    return Container(
      width: 318,
      padding: const EdgeInsets.all(22),
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
              fontSize: 12,
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
            child: const Center(
              child: Text(
                'โหลดตัวอย่างสลิปมาลอง (Sample Deck)',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
