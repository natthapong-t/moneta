import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/constants/categories.dart';
import '../core/theme/app_theme.dart';
import '../models/expense_card_item.dart';
import '../services/expense_storage_service.dart';
import '../services/slip_parser_service.dart';
import '../widgets/quick_add_sheet.dart';
import '../widgets/vault_details_sheet.dart';
import 'analytics_screen.dart';
import 'dashboard_screen.dart';
import 'ledger_history_screen.dart';
import 'swipe_feed_screen.dart';

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;
  bool _isLoading = true;

  List<ExpenseCardItem> _pendingCards = [];
  List<ExpenseCardItem> _categorizedCards = [];
  double _monthlyBudget = 15000.0;
  int _streakDays = 7;

  // Background Scanning State
  final _slipParser = SlipParserService();
  bool _isBackgroundScanning = false;
  String _scanningStatus = '';
  StreamSubscription<SlipScanProgress>? _scanSubscription;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _scanSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    final storage = ExpenseStorageService.instance;
    final pending = await storage.loadPendingExpenses();
    final categorized = await storage.loadCategorizedExpenses();
    final budget = await storage.getMonthlyBudget();
    final streak = await storage.getStreakDays();

    if (mounted) {
      setState(() {
        _pendingCards = pending;
        _categorizedCards = categorized;
        _monthlyBudget = budget;
        _streakDays = streak;
        _isLoading = false;
      });
    }
  }

  Future<void> _saveAllData() async {
    final storage = ExpenseStorageService.instance;
    await storage.savePendingExpenses(_pendingCards);
    await storage.saveCategorizedExpenses(_categorizedCards);
  }

  void _onCardCategorized(ExpenseCardItem item, CornerPosition corner) {
    final cat = ExpenseCategory.defaultCorners.firstWhere((c) => c.corner == corner);
    final updatedItem = item.copyWith(assignedCategory: cat);

    setState(() {
      _pendingCards.removeWhere((c) => c.id == item.id);
      _categorizedCards.add(updatedItem);
    });

    _saveAllData();

    // Mark reference number as processed to prevent duplicates
    if (item.referenceNo.isNotEmpty) {
      ExpenseStorageService.instance.markReferencesProcessed([item.referenceNo]);
    }
  }

  void _onUndo() {
    if (_categorizedCards.isEmpty) return;
    final lastItem = _categorizedCards.removeLast();

    setState(() {
      _pendingCards.insert(0, lastItem.copyWith(assignedCategory: null));
    });

    _saveAllData();
  }

  void _onQuickAdded(ExpenseCardItem newItem) {
    setState(() {
      _pendingCards.insert(0, newItem);
    });
    _saveAllData();
  }

  void _onSlipsImported(List<ExpenseCardItem> newItems) {
    final uniqueItems = newItems.where((newItem) {
      final inPending = _pendingCards.any((p) => p.isDuplicateOf(newItem));
      final inCategorized = _categorizedCards.any((c) => c.isDuplicateOf(newItem));
      return !inPending && !inCategorized;
    }).toList();

    if (uniqueItems.isNotEmpty) {
      setState(() {
        _pendingCards.insertAll(0, uniqueItems);
      });
      _saveAllData();
    }
  }

  void _onDeleteTransaction(ExpenseCardItem item) {
    setState(() {
      _categorizedCards.removeWhere((c) => c.id == item.id);
    });
    _saveAllData();
    HapticFeedback.lightImpact();
  }

  void _onResetToSample() {
    setState(() {
      _pendingCards = List.from(ExpenseCardItem.sampleCards);
      _categorizedCards = [];
    });
    _saveAllData();
    ExpenseStorageService.instance.resetToSample();
  }

  void _onRestoreItem(ExpenseCardItem item) {
    setState(() {
      _categorizedCards.removeWhere((c) => c.id == item.id);
      _pendingCards.insert(0, item.copyWith(assignedCategory: null));
    });
    _saveAllData();
  }

  void _onUpdateBudget(double newBudget) {
    setState(() {
      _monthlyBudget = newBudget;
    });
    ExpenseStorageService.instance.setMonthlyBudget(newBudget);
  }

  /// Start background non-blocking gallery scan
  Future<void> _startBackgroundGalleryScan() async {
    if (_isBackgroundScanning) return;

    HapticFeedback.mediumImpact();
    setState(() {
      _isBackgroundScanning = true;
      _scanningStatus = 'กำลังเตรียมค้นหาในคลังภาพ...';
    });

    final processedRefs = await ExpenseStorageService.instance.getProcessedReferenceNumbers();
    final knownRefs = <String>{
      ...processedRefs,
      ..._pendingCards.map((p) => p.referenceNo).where((r) => r.isNotEmpty),
      ..._categorizedCards.map((c) => c.referenceNo).where((r) => r.isNotEmpty),
    };
    final knownPaths = <String>{
      ..._pendingCards.map((p) => p.imagePath ?? '').where((p) => p.isNotEmpty),
      ..._categorizedCards.map((c) => c.imagePath ?? '').where((p) => p.isNotEmpty),
    };

    _scanSubscription?.cancel();
    _scanSubscription = _slipParser
        .streamGallerySlips(
          maxScan: null,
          knownReferenceNos: knownRefs,
          knownImagePaths: knownPaths,
        )
        .listen(
      (progress) {
        if (!mounted) return;

        setState(() {
          _scanningStatus =
              'กำลังกวาดสลิป... ${progress.scanned}/${progress.total} (พบ ${progress.foundCount} สลิป)';

          if (progress.newSlip != null) {
            final newSlip = progress.newSlip!;
            final alreadyInPending = _pendingCards.any((p) => p.isDuplicateOf(newSlip));
            final alreadyInCategorized = _categorizedCards.any((c) => c.isDuplicateOf(newSlip));

            if (!alreadyInPending && !alreadyInCategorized) {
              _pendingCards.insert(0, newSlip);
              HapticFeedback.lightImpact();
            }
          }
        });

        if (progress.newSlip != null) {
          _saveAllData();
        }

        if (progress.isFinished) {
          _finishBackgroundScan(progress.foundCount);
        }
      },
      onError: (err) {
        debugPrint('Error during background scan: $err');
        if (mounted) {
          setState(() {
            _isBackgroundScanning = false;
            _scanningStatus = '';
          });
        }
      },
      onDone: () {
        if (mounted && _isBackgroundScanning) {
          _finishBackgroundScan(0);
        }
      },
    );
  }

  void _finishBackgroundScan(int found) {
    setState(() {
      _isBackgroundScanning = false;
      _scanningStatus = '';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.surface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.gold),
        ),
        content: Text(
          found > 0
              ? 'กวาดตรวจเสร็จสิ้น! พบสลิปใหม่ $found ใบพร้อมให้ปัดแล้ว'
              : 'กวาดตรวจคลังภาพครบแล้ว ไม่พบสลิปธนาคารใหม่',
          style: const TextStyle(color: AppColors.marbleWhite, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  void _openQuickAddSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => QuickAddSheet(
        onCardCreated: (newItem) {
          _onQuickAdded(newItem);
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
        });
        _saveAllData();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.gold),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // IndexedStack maintains tab scroll positions and state smoothly
          IndexedStack(
            index: _currentIndex,
            children: [
              // Tab 0: Dashboard (คลังหลวง)
              DashboardScreen(
                pendingCards: _pendingCards,
                categorizedCards: _categorizedCards,
                monthlyBudget: _monthlyBudget,
                streakDays: _streakDays,
                onStartSwiping: () {
                  HapticFeedback.selectionClick();
                  setState(() => _currentIndex = 1);
                },
                onScanGallery: _startBackgroundGalleryScan,
                onQuickAdd: _openQuickAddSheet,
                onSelectVault: _openVaultDetails,
                onViewSlip: (item) => _showSlipPreview(context, item),
              ),

              // Tab 1: Swipe Feed (โต๊ะปัดสลิป)
              SwipeFeedScreen(
                pendingCards: _pendingCards,
                categorizedCards: _categorizedCards,
                onCategorized: _onCardCategorized,
                onUndo: _onUndo,
                onQuickAdded: _onQuickAdded,
                onSlipsImported: _onSlipsImported,
                onResetToSample: _onResetToSample,
                onRestoreItem: _onRestoreItem,
                onStartBackgroundScan: _startBackgroundGalleryScan,
              ),

              // Tab 2: Ledger History (บันทึกคลัง)
              LedgerHistoryScreen(
                transactions: _categorizedCards,
                onDeleteTransaction: _onDeleteTransaction,
              ),

              // Tab 3: Analytics (สถิติ & งบประมาณ)
              AnalyticsScreen(
                transactions: _categorizedCards,
                monthlyBudget: _monthlyBudget,
                onUpdateBudget: _onUpdateBudget,
              ),
            ],
          ),

          // Top Floating Background Scanning Status Banner (if scanning)
          if (_isBackgroundScanning)
            Positioned(
              top: 14,
              left: 20,
              right: 20,
              child: SafeArea(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.vaultQuadrigaShadow, width: 2.0),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.vaultQuadrigaShadow,
                        offset: Offset(0, 3),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 15,
                        height: 15,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: AppColors.vaultQuadriga,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _scanningStatus,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      InkWell(
                        onTap: () {
                          _scanSubscription?.cancel();
                          setState(() {
                            _isBackgroundScanning = false;
                            _scanningStatus = '';
                          });
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          child: Icon(Icons.close_rounded, size: 18, color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Arcade Bottom Navigation Dock (Light Mode + Flat 3D)
          Positioned(
            left: 20,
            right: 20,
            bottom: 14,
            child: _buildArcadeBottomBar(),
          ),
        ],
      ),
    );
  }

  Widget _buildArcadeBottomBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: AppColors.borderDark,
          width: 2.0,
        ),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowDefault,
            offset: Offset(0, 4),
            blurRadius: 0, // Flat 3D Cartoon Dock
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(
            index: 0,
            icon: Icons.dashboard_rounded,
            label: 'คลังหลวง',
          ),
          _buildNavItem(
            index: 1,
            icon: Icons.style_rounded,
            label: 'ปัดสลิป',
            badgeCount: _pendingCards.length,
          ),
          _buildNavItem(
            index: 2,
            icon: Icons.receipt_long_rounded,
            label: 'บันทึกคลัง',
          ),
          _buildNavItem(
            index: 3,
            icon: Icons.pie_chart_rounded,
            label: 'สถิติ',
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
    int? badgeCount,
  }) {
    final bool isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () {
        if (_currentIndex != index) {
          HapticFeedback.selectionClick();
          setState(() => _currentIndex = index);
        }
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.gold : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          border: isSelected
              ? Border.all(color: AppColors.goldShadow, width: 1.8)
              : Border.all(color: Colors.transparent),
          boxShadow: isSelected
              ? const [
                  BoxShadow(
                    color: AppColors.goldShadow,
                    offset: Offset(0, 2),
                    blurRadius: 0,
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isSelected ? const Color(0xFF1E293B) : AppColors.textSecondary,
                ),
                if (badgeCount != null && badgeCount > 0)
                  Positioned(
                    top: -6,
                    right: -8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.vaultTaverna,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white, width: 1.2),
                        boxShadow: const [
                          BoxShadow(
                            color: AppColors.vaultTavernaShadow,
                            offset: Offset(0, 1),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Center(
                        child: Text(
                          badgeCount > 99 ? '99+' : '$badgeCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            if (isSelected) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1E293B),
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showSlipPreview(BuildContext context, ExpenseCardItem item) {
    // Quick preview dialog
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.gold),
        ),
        title: Text(
          item.receiverName,
          style: const TextStyle(color: AppColors.marbleWhite, fontSize: 16),
        ),
        content: Text(
          'ยอดเงิน: ฿ ${item.amount.toStringAsFixed(2)}\nธนาคาร: ${item.bankName}\nเลขที่อ้างอิง: ${item.referenceNo}',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ปิด', style: TextStyle(color: AppColors.gold)),
          ),
        ],
      ),
    );
  }
}
