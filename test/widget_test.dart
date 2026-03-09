import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nova_finance_os/app.dart';

void main() {
  testWidgets('App loads successfully', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: NovaAccountantApp()));

    // Verify that the app loads
    await tester.pumpAndSettle();
    
    // Check for Finance OS title
    expect(find.text('Finance OS'), findsOneWidget);
  });
}
