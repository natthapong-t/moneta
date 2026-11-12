import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:moneta/models/expense_card_item.dart';
import 'package:moneta/screens/dashboard_screen.dart';
import 'package:moneta/widgets/moneta_goddess_widget.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('th_TH', null);
  });

  group('MonetaSanctumHero Unslop Tests', () {
    testWidgets('renders financial heart with confident number and no filler badges',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MonetaSanctumHero(
              monthlyBudget: 15000,
              totalSpent: 3500,
              todaySpent: 350,
              streakDays: 7,
              isTodayNoSpend: false,
              pendingSlipsCount: 2,
            ),
          ),
        ),
      );
      await tester.pump();

      // Verify financial heart
      expect(find.text('งบที่เหลือ'), findsOneWidget);
      expect(find.text('฿11,500'), findsOneWidget);
      expect(find.text('สตรีค 7 วัน'), findsOneWidget);

      // Verify Rule 1: No filler badges
      expect(find.text('🏛️ อารักขาคลัง'), findsNothing);
      expect(find.text('✨ No-Spend'), findsNothing);
      expect(find.text('✨ No-Spend Day'), findsNothing);

      // Verify Rule 2: No redundant header
      expect(find.text('วิหารแห่งโมนีตา'), findsNothing);

      // Verify Rule 13: No 👑 inside speech bubbles
      expect(find.text('👑'), findsNothing);

      // Verify Goddess and Goose pixel widgets present
      expect(find.byType(MonetaGoddessPixelWidget), findsOneWidget);
      expect(find.byType(SacredGoosePixelWidget), findsOneWidget);
    });

    testWidgets('tap interaction updates speech quote', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MonetaSanctumHero(
              monthlyBudget: 0,
              totalSpent: 500,
              todaySpent: 500,
              streakDays: 0,
              isTodayNoSpend: false,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('วันนี้ใช้ไป'), findsOneWidget);
      expect(find.text('฿500'), findsOneWidget);

      // Tap on Moneta
      await tester.tap(find.byType(MonetaGoddessPixelWidget));
      await tester.pump();

      // Tap on Sacred Goose
      await tester.tap(find.byType(SacredGoosePixelWidget));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1600));
    });
  });

  group('DashboardScreen Unslop Tests', () {
    testWidgets('renders clean header and modern 2-col metric section without slop',
        (tester) async {
      final sampleCards = [
        ExpenseCardItem(
          id: 'test-1',
          receiverName: '7-Eleven',
          amount: 350.0,
          dateTime: DateTime.now(),
          bankName: 'KBANK',
          bankColor: Colors.green,
          referenceNo: 'REF123456',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: DashboardScreen(
            pendingCards: sampleCards,
            categorizedCards: sampleCards,
            monthlyBudget: 10000,
            streakDays: 5,
            onStartSwiping: () {},
            onScanGallery: () {},
            onQuickAdd: () {},
            onSelectVault: (_) {},
            onViewSlip: (_) {},
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Rule 2: Redundant labels dropped
      expect(find.text('Moneta Daily Check-in'), findsNothing);

      // Streak pill present
      expect(find.text('5'), findsOneWidget);

      // Rule 8: Modern 2-col metric section
      expect(find.text('เฉลี่ยต่อวัน'), findsOneWidget);
      expect(find.text('รายการวันนี้'), findsOneWidget);

      // Rule 6, 7 & 10: Punchy CTA button "ปัดเลย"
      expect(find.text('ปัดเลย'), findsOneWidget);
      expect(find.text('มีสลิป 1 ใบ รอปัดแยกหมวด'), findsOneWidget);
    });
  });
}
