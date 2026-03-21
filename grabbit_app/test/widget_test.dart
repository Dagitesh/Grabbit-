import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:grabbit_app/main.dart';

void main() {
  testWidgets('GrabbitApp builds MaterialApp', (WidgetTester tester) async {
    await tester.pumpWidget(const GrabbitApp());
    await tester.pump();
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
