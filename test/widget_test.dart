import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:moneta/main.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('th_TH', null);
  });

  testWidgets('Moneta smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MonetaApp());
    expect(find.text('MONETA'), findsOneWidget);
  });
}
