import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/expense_card_item.dart';

class ExpenseStorageService {
  static const String _keyCategorized = 'moneta_categorized_items';
  static const String _keyPending = 'moneta_pending_items';
  static const String _keyProcessedRefs = 'moneta_processed_refs';
  static const String _keyScannedAssetIds = 'moneta_scanned_asset_ids';
  static const String _keyLastScanTimestamp = 'moneta_last_scan_timestamp';
  static const String _keyMonthlyBudget = 'moneta_monthly_budget';
  static const String _keyStreakDays = 'moneta_streak_days';
  static const String _keyNoSpendDates = 'moneta_no_spend_dates';
  static const String _keyCompletedOnboarding = 'moneta_completed_onboarding';
  static const String _keyUserLanguage = 'moneta_user_language';
  static const String _keyUserCurrency = 'moneta_user_currency';
  static const String _keyUserSalaryRange = 'moneta_user_salary_range';
  static const String _keyScanHistoryDays = 'moneta_scan_history_days';

  static ExpenseStorageService? _instance;
  static ExpenseStorageService get instance => _instance ??= ExpenseStorageService._();

  ExpenseStorageService._();

  SharedPreferences? _prefs;

  Future<SharedPreferences> get prefs async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  /// Load all categorized transactions
  Future<List<ExpenseCardItem>> loadCategorizedExpenses() async {
    try {
      final p = await prefs;
      final rawList = p.getStringList(_keyCategorized) ?? [];
      return rawList.map((raw) {
        final Map<String, dynamic> map = jsonDecode(raw);
        return ExpenseCardItem.fromJson(map);
      }).toList();
    } catch (e) {
      debugPrint('Error loading categorized expenses: $e');
      return [];
    }
  }

  /// Save all categorized transactions
  Future<void> saveCategorizedExpenses(List<ExpenseCardItem> items) async {
    try {
      final p = await prefs;
      final rawList = items.map((item) => jsonEncode(item.toJson())).toList();
      await p.setStringList(_keyCategorized, rawList);
    } catch (e) {
      debugPrint('Error saving categorized expenses: $e');
    }
  }

  /// Load pending cards waiting for triage
  Future<List<ExpenseCardItem>> loadPendingExpenses() async {
    try {
      final p = await prefs;
      final rawList = p.getStringList(_keyPending);
      if (rawList == null) {
        // Return initial sample deck on first launch
        return List.from(ExpenseCardItem.sampleCards);
      }
      return rawList.map((raw) {
        final Map<String, dynamic> map = jsonDecode(raw);
        return ExpenseCardItem.fromJson(map);
      }).toList();
    } catch (e) {
      debugPrint('Error loading pending expenses: $e');
      return List.from(ExpenseCardItem.sampleCards);
    }
  }

  /// Save pending cards
  Future<void> savePendingExpenses(List<ExpenseCardItem> items) async {
    try {
      final p = await prefs;
      final rawList = items.map((item) => jsonEncode(item.toJson())).toList();
      await p.setStringList(_keyPending, rawList);
    } catch (e) {
      debugPrint('Error saving pending expenses: $e');
    }
  }

  /// Get set of processed slip reference numbers (De-duplication)
  Future<Set<String>> getProcessedReferenceNumbers() async {
    try {
      final p = await prefs;
      final list = p.getStringList(_keyProcessedRefs) ?? [];
      return list.toSet();
    } catch (e) {
      return {};
    }
  }

  /// Mark reference numbers as processed so they aren't imported twice
  Future<void> markReferencesProcessed(Iterable<String> refs) async {
    try {
      final p = await prefs;
      final current = (p.getStringList(_keyProcessedRefs) ?? []).toSet();
      current.addAll(refs.where((r) => r.isNotEmpty));
      await p.setStringList(_keyProcessedRefs, current.toList());
    } catch (e) {
      debugPrint('Error marking processed refs: $e');
    }
  }

  /// Get set of scanned asset IDs (both slips and non-slips)
  Future<Set<String>> getScannedAssetIds() async {
    try {
      final p = await prefs;
      final list = p.getStringList(_keyScannedAssetIds) ?? [];
      return list.toSet();
    } catch (e) {
      return {};
    }
  }

  /// Add newly scanned asset IDs to persistent cache
  Future<void> addScannedAssetIds(Iterable<String> ids) async {
    try {
      final p = await prefs;
      final current = (p.getStringList(_keyScannedAssetIds) ?? []).toSet();
      current.addAll(ids.where((id) => id.isNotEmpty));
      await p.setStringList(_keyScannedAssetIds, current.toList());
    } catch (e) {
      debugPrint('Error saving scanned asset IDs: $e');
    }
  }

  /// Last scan timestamp
  Future<DateTime?> getLastScanTime() async {
    try {
      final p = await prefs;
      final ms = p.getInt(_keyLastScanTimestamp);
      return ms != null ? DateTime.fromMillisecondsSinceEpoch(ms) : null;
    } catch (e) {
      return null;
    }
  }

  Future<void> setLastScanTime(DateTime time) async {
    try {
      final p = await prefs;
      await p.setInt(_keyLastScanTimestamp, time.millisecondsSinceEpoch);
    } catch (e) {
      debugPrint('Error setting last scan time: $e');
    }
  }

  /// Reset all expenses back to the initial sample cards and clear processed references & scan cache
  Future<void> resetToSample() async {
    try {
      final p = await prefs;
      final rawList = ExpenseCardItem.sampleCards
          .map((item) => jsonEncode(item.toJson()))
          .toList();
      await p.setStringList(_keyPending, rawList);
      await p.setStringList(_keyCategorized, []);
      await p.remove(_keyProcessedRefs);
      await p.remove(_keyScannedAssetIds);
      await p.remove(_keyLastScanTimestamp);
    } catch (e) {
      debugPrint('Error resetting to sample: $e');
    }
  }

  /// Completely clear all pending, categorized expenses and processed references & scan cache
  Future<void> clearAllData() async {
    try {
      final p = await prefs;
      await p.setStringList(_keyPending, []);
      await p.setStringList(_keyCategorized, []);
      await p.remove(_keyProcessedRefs);
      await p.remove(_keyScannedAssetIds);
      await p.remove(_keyLastScanTimestamp);
    } catch (e) {
      debugPrint('Error clearing all data: $e');
    }
  }

  /// Completely wipe all stored data and reset onboarding state (fresh install simulation)
  Future<void> resetToFirstInstall() async {
    try {
      final p = await prefs;
      await p.clear();
    } catch (e) {
      debugPrint('Error resetting to first install: $e');
    }
  }

  /// Monthly budget limit (Default: ฿15,000)
  Future<double> getMonthlyBudget() async {
    try {
      final p = await prefs;
      return p.getDouble(_keyMonthlyBudget) ?? 15000.0;
    } catch (e) {
      debugPrint('Error getting monthly budget: $e');
      return 15000.0;
    }
  }

  Future<void> setMonthlyBudget(double amount) async {
    try {
      final p = await prefs;
      await p.setDouble(_keyMonthlyBudget, amount);
    } catch (e) {
      debugPrint('Error setting monthly budget: $e');
    }
  }

  /// Streaks
  Future<int> getStreakDays() async {
    try {
      final p = await prefs;
      return p.getInt(_keyStreakDays) ?? 7; // Default initial 7-day streak for fun
    } catch (e) {
      debugPrint('Error getting streak days: $e');
      return 7;
    }
  }

  Future<void> setStreakDays(int days) async {
    try {
      final p = await prefs;
      await p.setInt(_keyStreakDays, days);
    } catch (e) {
      debugPrint('Error setting streak days: $e');
    }
  }

  /// No-Spend Day tracking (Mintio v1.2.2 feature)
  String _todayDateKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  Future<bool> isTodayNoSpendDay() async {
    try {
      final p = await prefs;
      final dates = p.getStringList(_keyNoSpendDates) ?? [];
      return dates.contains(_todayDateKey());
    } catch (e) {
      return false;
    }
  }

  Future<bool> markTodayNoSpendDay() async {
    try {
      final p = await prefs;
      final dates = (p.getStringList(_keyNoSpendDates) ?? []).toSet();
      final today = _todayDateKey();
      if (!dates.contains(today)) {
        dates.add(today);
        await p.setStringList(_keyNoSpendDates, dates.toList());
        // Increment streak
        final currentStreak = await getStreakDays();
        await setStreakDays(currentStreak + 1);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error marking no spend day: $e');
      return false;
    }
  }

  /// Onboarding status
  Future<bool> hasCompletedOnboarding() async {
    try {
      final p = await prefs;
      return p.getBool(_keyCompletedOnboarding) ?? false;
    } catch (e) {
      return false;
    }
  }

  Future<void> setCompletedOnboarding(bool completed) async {
    try {
      final p = await prefs;
      await p.setBool(_keyCompletedOnboarding, completed);
    } catch (e) {
      debugPrint('Error setting onboarding status: $e');
    }
  }

  /// User Preferences from Onboarding
  Future<String> getUserLanguage() async {
    try {
      final p = await prefs;
      return p.getString(_keyUserLanguage) ?? 'th';
    } catch (e) {
      return 'th';
    }
  }

  Future<void> setUserLanguage(String lang) async {
    final p = await prefs;
    await p.setString(_keyUserLanguage, lang);
  }

  Future<String> getUserCurrency() async {
    try {
      final p = await prefs;
      return p.getString(_keyUserCurrency) ?? 'THB';
    } catch (e) {
      return 'THB';
    }
  }

  Future<void> setUserCurrency(String currency) async {
    final p = await prefs;
    await p.setString(_keyUserCurrency, currency);
  }

  Future<String> getUserSalaryRange() async {
    try {
      final p = await prefs;
      return p.getString(_keyUserSalaryRange) ?? '฿10,000 - 50,000';
    } catch (e) {
      return '฿10,000 - 50,000';
    }
  }

  Future<void> setUserSalaryRange(String range) async {
    final p = await prefs;
    await p.setString(_keyUserSalaryRange, range);
  }

  /// Scan History Window in Days (0 = today only, 7 = 7 days, 30 = 30 days, -1 = all)
  Future<int> getScanHistoryDays() async {
    try {
      final p = await prefs;
      return p.getInt(_keyScanHistoryDays) ?? 7; // Default: Sweet Spot 7 days
    } catch (e) {
      return 7;
    }
  }

  Future<void> setScanHistoryDays(int days) async {
    try {
      final p = await prefs;
      await p.setInt(_keyScanHistoryDays, days);
    } catch (e) {
      debugPrint('Error setting scan history days: $e');
    }
  }
}
