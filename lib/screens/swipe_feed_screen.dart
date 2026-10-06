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
import '../services/slip_parser_service.dart';

class SwipeFeedScreen extends StatefulWidget {
  const SwipeFeedScreen({super.key});

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
    _resetToSample();
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
      body: SafeArea(
        child: Stack(
          children: [
            // Top Navigation & Roman Emperor Header
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
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppColors.gold.withValues(alpha: 0.5),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.gold.withValues(alpha: 0.15),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.account_balance_rounded,
                          color: AppColors.gold,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Text(
                                'MONETA',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.5,
                                  color: AppColors.gold,
                                ),
                              ),
                            ],
                          ),
                          const Text(
                            'ปัดสลิป จัดการค่าใช้จ่าย',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      // Streak Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        margin: const EdgeInsets.only(right: 6),
                        decoration: BoxDecoration(
                          color: AppColors.vaultTributum.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.vaultTributum.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Text('🔥', style: TextStyle(fontSize: 12)),
                            SizedBox(width: 4),
                            Text(
                              '7 วัน',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF6EE7B7),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Pending Cards Pill
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 4.5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.gold.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.style_rounded,
                              size: 13,
                              color: AppColors.gold,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              '${_pendingCards.length} สลิป',
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: AppColors.marbleWhite,
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

            // Top-Left Vault (1. Food)
            Positioned(
              top: 66,
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
              top: 66,
              right: 14,
              child: CornerTargetBox(
                category: quadrigaCat,
                isHovered: _hoveredCorner == CornerPosition.topRight,
                totalAmount: _categoryTotals[quadrigaCat.id] ?? 0.0,
                itemCount: _categoryCounts[quadrigaCat.id] ?? 0,
                onTap: () => _openVaultDetails(quadrigaCat),
              ),
            ),

            // Bottom-Left Vault (3. Shopping)
            Positioned(
              bottom: 84,
              left: 14,
              child: CornerTargetBox(
                category: forumCat,
                isHovered: _hoveredCorner == CornerPosition.bottomLeft,
                totalAmount: _categoryTotals[forumCat.id] ?? 0.0,
                itemCount: _categoryCounts[forumCat.id] ?? 0,
                onTap: () => _openVaultDetails(forumCat),
              ),
            ),

            // Bottom-Right Vault (4. Bills)
            Positioned(
              bottom: 84,
              right: 14,
              child: CornerTargetBox(
                category: tributumCat,
                isHovered: _hoveredCorner == CornerPosition.bottomRight,
                totalAmount: _categoryTotals[tributumCat.id] ?? 0.0,
                itemCount: _categoryCounts[tributumCat.id] ?? 0,
                onTap: () => _openVaultDetails(tributumCat),
              ),
            ),

            // Center Card Stack or Roman Triumph Empty State
            Center(
              child: _pendingCards.isEmpty
                  ? _buildRomanTriumphState()
                  : _buildCardStack(),
            ),

            // Bottom Floating Controls
            Positioned(
              bottom: 16,
              left: 18,
              right: 18,
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _openQuickAdd,
                      icon: const Icon(Icons.flash_on_rounded, size: 18, color: AppColors.gold),
                      label: const Text(
                        'บันทึกด่วน',
                        style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.gold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.surface,
                        side: const BorderSide(color: AppColors.gold, width: 1.2),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    tooltip: 'นำเข้าสลิปธนาคาร (Import Slips)',
                    onPressed: _isScanningSlips ? null : _openScanOptionsSheet,
                    icon: _isScanningSlips
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.gold,
                            ),
                          )
                        : const Icon(Icons.document_scanner_rounded),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.surface,
                      foregroundColor: AppColors.gold,
                      side: const BorderSide(color: AppColors.gold, width: 1.2),
                      padding: const EdgeInsets.all(14),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (_categorizedCards.isNotEmpty)
                    IconButton.filled(
                      tooltip: 'เลิกทำรายการล่าสุด (Undo)',
                      onPressed: _undoLastAction,
                      icon: const Icon(Icons.undo_rounded),
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.surface,
                        foregroundColor: AppColors.gold,
                        side: BorderSide(color: AppColors.gold.withValues(alpha: 0.4)),
                        padding: const EdgeInsets.all(14),
                      ),
                    ),
                  IconButton.filled(
                    tooltip: 'รีเซ็ตข้อมูลตัวอย่าง',
                    onPressed: _resetToSample,
                    icon: const Icon(Icons.refresh_rounded),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.surfaceLight,
                      foregroundColor: AppColors.textSecondary,
                      padding: const EdgeInsets.all(14),
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
      width: 324,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.gold, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.gold.withValues(alpha: 0.2),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Roman Laurel & Victory Medallion
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.gold, width: 2),
            ),
            child: const Icon(
              Icons.workspace_premium_rounded,
              color: AppColors.gold,
              size: 46,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'จัดหมวดหมู่ครบแล้ว! 🎉',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
              color: AppColors.gold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'คุณได้จัดหมวดหมู่สลิป ${_categorizedCards.length} รายการเรียบร้อยแล้ว',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12.5,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.surfaceLight),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'ยอดรวมทั้งหมด',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
                Text(
                  '฿ ${currencyFormatter.format(grandTotal)}',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppColors.goldBright,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isScanningSlips ? null : _openScanOptionsSheet,
              icon: _isScanningSlips
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                    )
                  : const Icon(Icons.document_scanner_rounded, size: 20),
              label: const Text('นำเข้าและสแกนสลิป (Import Slips)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: const Color(0xFF0F172A),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _resetToSample,
              icon: const Icon(Icons.replay_rounded, size: 18),
              label: const Text('โหลดตัวอย่างสลิปมาลอง (Sample Deck)'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.gold,
                side: const BorderSide(color: AppColors.surfaceLight),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
