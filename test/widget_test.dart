import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sip_sleep/main.dart';

void main() {
  testWidgets('app démarre', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await tester.pump();
    expect(find.byType(MyApp), findsOneWidget);
  });
}
