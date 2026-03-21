import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:VCE_Busses/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Verify the app builds and shows a Scaffold
    await tester.pumpWidget(const MyApp());
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
