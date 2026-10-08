import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/constants/categories.dart';
import '../core/theme/app_theme.dart';
import '../models/expense_card_item.dart';
import '../services/expense_storage_service.dart';
import '../services/slip_parser_service.dart';
import '../widgets/quick_add_sheet.dart';
import '../widgets/quick_income_sheet.dart';
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
  bool _isScanBannerMinimized = false;
  int _scanFoundCount = 0;
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
    try {
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
        });
      }
    } catch (e) {
      debugPrint('Error loading initial data: $e');
      if (mounted) {
        setState(() {
          _pendingCards = List.from(ExpenseCardItem.sampleCards);
          _categorizedCards = [];
          _monthlyBudget = 15000.0;
          _streakDays = 7;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        // MeowJot style: auto-scan incremental new slips silently in background on launch
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _startBackgroundGalleryScan(isSilent: true);
        });
      }
    }
  }

  Future<void> _saveAllData() async {
    final storage = ExpenseStorageService.instance;
    await storage.savePendingExpenses(_pendingCards);
    await storage.saveCategorizedExpenses(_categorizedCards);
  }

  void _onCardCategorized(ExpenseCardItem item, CornerPosition corner) {
    final cat = ExpenseCategory.defaultCorners.firstWhere(
      (c) => c.corner == corner,
    );
    final updatedItem = item.copyWith(assignedCategory: cat);

    setState(() {
      _pendingCards.removeWhere((c) => c.id == item.id);
      _categorizedCards.add(updatedItem);
    });

    _saveAllData();

    // Mark reference number as processed to prevent duplicates
    if (item.referenceNo.isNotEmpty) {
      ExpenseStorageService.instance.markReferencesProcessed([
        item.referenceNo,
      ]);
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
      final inCategorized = _categorizedCards.any(
        (c) => c.isDuplicateOf(newItem),
      );
      return !inPending && !inCategorized;
    }).toList();

    if (uniqueItems.isNotEmpty) {
      setState(() {
        _pendingCards.addAll(uniqueItems);
        _pendingCards.sort((a, b) => b.dateTime.compareTo(a.dateTime));
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
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.surface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.gold, width: 1.5),
        ),
        content: const Row(
          children: [
            Icon(Icons.restart_alt_rounded, color: AppColors.gold, size: 20),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'รีเซ็ตสลิปตัวอย่างใหม่เรียบร้อย!',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onClearAllData() {
    setState(() {
      _pendingCards = [];
      _categorizedCards = [];
    });
    _saveAllData();
    ExpenseStorageService.instance.clearAllData();
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.surface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
        ),
        content: const Row(
          children: [
            Icon(Icons.delete_sweep_rounded, color: Color(0xFFEF4444), size: 20),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'ล้างข้อมูลสลิปและประวัติทั้งหมดเป็น 0 เรียบร้อย!',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onCardSkipLater() {
    if (_pendingCards.isEmpty) return;
    setState(() {
      final skipped = _pendingCards.removeAt(0);
      _pendingCards.add(skipped);
    });
    _saveAllData();
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

  /// Start background non-blocking gallery scan with persistent cache
  Future<void> _startBackgroundGalleryScan({bool isSilent = false}) async {
    if (_isBackgroundScanning) return;

    if (!isSilent) {
      HapticFeedback.mediumImpact();
    }

    setState(() {
      _isBackgroundScanning = true;
      _isScanBannerMinimized = isSilent;
      _scanFoundCount = 0;
      _scanningStatus = 'กำลังเตรียมค้นหาในคลังภาพ...';
    });

    final storage = ExpenseStorageService.instance;
    final processedRefs = await storage.getProcessedReferenceNumbers();
    final cachedAssetIds = await storage.getScannedAssetIds();

    final knownRefs = <String>{
      ...processedRefs,
      ..._pendingCards.map((p) => p.referenceNo).where((r) => r.isNotEmpty),
      ..._categorizedCards.map((c) => c.referenceNo).where((r) => r.isNotEmpty),
    };
    final knownPaths = <String>{
      ..._pendingCards.map((p) => p.imagePath ?? '').where((p) => p.isNotEmpty),
      ..._categorizedCards
          .map((c) => c.imagePath ?? '')
          .where((p) => p.isNotEmpty),
    };

    final Set<String> newlyScannedAssetIds = {};

    _scanSubscription?.cancel();
    _scanSubscription = _slipParser
        .streamGallerySlips(
          maxScan: null,
          knownReferenceNos: knownRefs,
          knownImagePaths: knownPaths,
          knownAssetIds: cachedAssetIds,
          onAssetScanned: (assetId, imagePath) {
            newlyScannedAssetIds.add(assetId);
            // Flush to persistent storage incrementally in batches of 25
            if (newlyScannedAssetIds.length >= 25) {
              storage.addScannedAssetIds(newlyScannedAssetIds);
              newlyScannedAssetIds.clear();
            }
          },
        )
        .listen(
          (progress) {
            if (!mounted) return;
            setState(() {
              final albumHint = (progress.currentSource != null &&
                      progress.currentSource!.isNotEmpty)
                  ? ' [${progress.currentSource}]'
                  : '';
              _scanFoundCount = progress.foundCount;
              _scanningStatus =
                  'กำลังกวาดสลิป$albumHint... ${progress.scanned}/${progress.total} (พบ ${progress.foundCount} สลิป)';

              if (progress.newSlip != null) {
                final newSlip = progress.newSlip!;
                final alreadyInPending = _pendingCards.any(
                  (p) => p.isDuplicateOf(newSlip),
                );
                final alreadyInCategorized = _categorizedCards.any(
                  (c) => c.isDuplicateOf(newSlip),
                );

                if (!alreadyInPending && !alreadyInCategorized) {
                  _pendingCards.add(newSlip);
                  _pendingCards.sort((a, b) => b.dateTime.compareTo(a.dateTime));
                  HapticFeedback.lightImpact();
                }
              }
            });

            if (progress.newSlip != null) {
              _saveAllData();
            }

            if (progress.isFinished) {
              if (newlyScannedAssetIds.isNotEmpty) {
                storage.addScannedAssetIds(newlyScannedAssetIds);
                newlyScannedAssetIds.clear();
              }
              storage.setLastScanTime(DateTime.now());
              _finishBackgroundScan(progress.foundCount, isSilent: isSilent);
            }
          },
          onError: (err) {
            debugPrint('Error during background scan: $err');
            if (newlyScannedAssetIds.isNotEmpty) {
              storage.addScannedAssetIds(newlyScannedAssetIds);
              newlyScannedAssetIds.clear();
            }
            if (mounted) {
              setState(() {
                _isBackgroundScanning = false;
                _isScanBannerMinimized = false;
                _scanningStatus = '';
              });
            }
          },
          onDone: () {
            if (newlyScannedAssetIds.isNotEmpty) {
              storage.addScannedAssetIds(newlyScannedAssetIds);
              newlyScannedAssetIds.clear();
            }
            storage.setLastScanTime(DateTime.now());
            if (mounted && _isBackgroundScanning) {
              _finishBackgroundScan(0, isSilent: isSilent);
            }
          },
        );
  }

  void _finishBackgroundScan(int found, {bool isSilent = false}) {
    setState(() {
      _isBackgroundScanning = false;
      _isScanBannerMinimized = false;
      _scanningStatus = '';
    });

    if (isSilent && found == 0) {
      // Quiet finish when auto-scanning on launch with no new slips
      return;
    }

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
          style: const TextStyle(
            color: AppColors.marbleWhite,
            fontWeight: FontWeight.bold,
          ),
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

  void _openQuickIncomeSheet([DateTime? date]) {
    QuickIncomeSheet.show(
      context: context,
      initialDate: date,
      onIncomeCreated: (item) {
        setState(() {
          _categorizedCards.add(item);
        });
        _saveAllData();
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.surface,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: AppColors.emerald, width: 2),
            ),
            content: Row(
              children: [
                const Text('💰', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'เพิ่มรายรับ +฿${item.amount.toStringAsFixed(2)} เรียบร้อย!',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
        body: Center(child: CircularProgressIndicator(color: AppColors.gold)),
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
              // Tab 0: Dashboard (หน้าหลัก)
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
                onQuickIncome: _openQuickIncomeSheet,
                onOpenCalendar: () {
                  HapticFeedback.selectionClick();
                  setState(() => _currentIndex = 2);
                },
                onSelectVault: _openVaultDetails,
                onViewSlip: (item) => _showSlipPreview(context, item),
                onResetToSample: _onResetToSample,
                onClearAllData: _onClearAllData,
              ),

              // Tab 1: Swipe Feed (ปัดแยกสลิป)
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
                onSkipLater: _onCardSkipLater,
              ),

              // Tab 2: Ledger History (ประวัติรายการ & ปฏิทิน)
              LedgerHistoryScreen(
                transactions: _categorizedCards,
                pendingCards: _pendingCards,
                onDeleteTransaction: _onDeleteTransaction,
                onAddIncome: _openQuickIncomeSheet,
                onAddExpense: _openQuickAddSheet,
                onStartSwiping: () {
                  HapticFeedback.selectionClick();
                  setState(() => _currentIndex = 1);
                },
              ),

              // Tab 3: Analytics (สถิติ & งบประมาณ)
              AnalyticsScreen(
                transactions: _categorizedCards,
                monthlyBudget: _monthlyBudget,
                onUpdateBudget: _onUpdateBudget,
              ),
            ],
          ),

          // Top Floating Background Scanning Status Banner (Collapsible/Minimizable)
          if (_isBackgroundScanning)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              top: 14,
              left: _isScanBannerMinimized ? null : 20,
              right: 20,
              child: SafeArea(
                child: _isScanBannerMinimized
                    ? GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() {
                            _isScanBannerMinimized = false;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.vaultQuadrigaShadow,
                              width: 2.0,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: AppColors.vaultQuadrigaShadow,
                                offset: Offset(0, 3),
                                blurRadius: 0,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(
                                width: 13,
                                height: 13,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: AppColors.vaultQuadriga,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _scanFoundCount > 0
                                    ? '⚡ พบ $_scanFoundCount ใบ'
                                    : 'กวาดสลิป...',
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(
                                Icons.open_in_full_rounded,
                                size: 13,
                                color: AppColors.textSecondary,
                              ),
                            ],
                          ),
                        ),
                      )
                    : Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.vaultQuadrigaShadow,
                            width: 2.0,
                          ),
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
                            const SizedBox(width: 4),
                            // Minimize button
                            InkWell(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setState(() {
                                  _isScanBannerMinimized = true;
                                });
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 3,
                                ),
                                child: Icon(
                                  Icons.expand_less_rounded,
                                  size: 20,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 2),
                            // Cancel button
                            InkWell(
                              onTap: () {
                                _scanSubscription?.cancel();
                                setState(() {
                                  _isBackgroundScanning = false;
                                  _isScanBannerMinimized = false;
                                  _scanningStatus = '';
                                });
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 3,
                                ),
                                child: Icon(
                                  Icons.close_rounded,
                                  size: 18,
                                  color: Color(0xFFEF4444),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ),

          // Duolingo-Style Attached Bottom Navigation Bar (Light Mode)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildDuolingoBottomBar(),
          ),
        ],
      ),
    );
  }

  Widget _buildDuolingoBottomBar() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface, // Pure White (#FFFFFF)
        border: Border(
          top: BorderSide(
            color: Color(0xFFE2E8F0), // Crisp 2px top border
            width: 2.0,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                index: 0,
                icon: Icons.cottage_rounded,
                iconColor: const Color(0xFFFF9600), // Duolingo warm orange/gold house
              ),
              _buildNavItem(
                index: 1,
                icon: Icons.style_rounded,
                iconColor: const Color(0xFF1CB0F6), // Duolingo Electric Sky Blue
                badgeCount: _pendingCards.length,
              ),
              _buildNavItem(
                index: 2,
                icon: Icons.receipt_long_rounded,
                iconColor: const Color(0xFFCE82FF), // Playful Lilac Purple
              ),
              _buildNavItem(
                index: 3,
                icon: Icons.pie_chart_rounded,
                iconColor: const Color(0xFF58CC02), // Duolingo Lime Green
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required Color iconColor,
    int? badgeCount,
  }) {
    final bool isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () {
        if (_currentIndex != index) {
          HapticFeedback.lightImpact();
          setState(() => _currentIndex = index);
        }
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutBack,
        width: 66,
        height: 48,
        decoration: BoxDecoration(
          // Duolingo Signature Selection: Crisp Sky Blue Border + Soft Tinted Fill
          color: isSelected ? const Color(0xFFE8F7FE) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF1CB0F6) : Colors.transparent,
            width: 2.2,
          ),
        ),
        child: Center(
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              AnimatedScale(
                scale: isSelected ? 1.08 : 0.95,
                duration: const Duration(milliseconds: 160),
                curve: Curves.easeOutBack,
                child: Icon(
                  icon,
                  size: 28,
                  color: isSelected
                      ? iconColor
                      : iconColor.withValues(alpha: 0.85),
                ),
              ),
              if (badgeCount != null && badgeCount > 0)
                Positioned(
                  top: -5,
                  right: -8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 1.5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.vaultTaverna,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white, width: 1.8),
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
                          fontSize: 9.5,
                          fontWeight: FontWeight.w900,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
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
