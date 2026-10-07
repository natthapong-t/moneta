import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/expense_card_item.dart';

class ExpenseStorageService {
  static const String _keyCategorized = 'moneta_categorized_items';
  static const String _keyPending = 'moneta_pending_items';
  static const String _keyProcessedRefs = 'moneta_processed_refs';
  static const String _keyMonthlyBudget = 'moneta_monthly_budget';
  static const String _keyStreakDays = 'moneta_streak_days';

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

  /// Reset all expenses back to the initial sample cards and clear processed references
  Future<void> resetToSample() async {
    try {
      final p = await prefs;
      final rawList = ExpenseCardItem.sampleCards
          .map((item) => jsonEncode(item.toJson()))
          .toList();
      await p.setStringList(_keyPending, rawList);
      await p.setStringList(_keyCategorized, []);
      await p.remove(_keyProcessedRefs);
    } catch (e) {
      debugPrint('Error resetting to sample: $e');
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
}
