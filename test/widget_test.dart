// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:ownbusiness/main.dart';

void main() {
  testWidgets('Workflow app renders customer and admin surfaces', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const OwnBusinessApp());

    expect(find.text('Own Business'), findsOneWidget);
    expect(find.text('Start a print order'), findsOneWidget);
    expect(find.text('Track order'), findsOneWidget);

    await tester.tap(find.text('Admin'));
    await tester.pump();

    expect(find.text('Operations'), findsOneWidget);
    expect(find.text('Orders'), findsOneWidget);
    expect(find.text('Production'), findsWidgets);
  });
}
