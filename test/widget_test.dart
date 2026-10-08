import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:golpoghor/main.dart';

void main() {
  testWidgets('অ্যাপ লোড স্মোক টেস্ট', (WidgetTester tester) async {
    // Supabase init ছাড়াই শুধু উইজেট ট্রি — CI-তে নেটওয়ার্ক লাগবে না
    // main() কল করব না; শুধু রুট উইজেট
    await tester.pumpWidget(
      const ProviderScope(
        child: GolpoGhorApp(),
      ),
    );
    // স্মোক: ক্র্যাশ না হলেই পাস
    expect(find.byType(GolpoGhorApp), findsOneWidget);
  });
}
