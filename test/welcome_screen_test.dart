import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:receipt_manager/screens/old/welcome_screen.dart';

void main() {
  testWidgets('WelcomeScreen displays Log In and Register buttons',
      (WidgetTester tester) async {
    // Build the WelcomeScreen widget
    await tester.pumpWidget(MaterialApp(
      home: WelcomeScreen(),
    ));

    // Verify that the WelcomeScreen shows the buttons
    expect(find.text('Log In'), findsOneWidget);
    expect(find.text('Register'), findsOneWidget);
  });
}
