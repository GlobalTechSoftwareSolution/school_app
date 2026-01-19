// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:school_app/main.dart';

void main() {
  testWidgets('School portal app loads correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SchoolPortalApp());

    // Verify that the splash screen appears
    expect(find.text('Loading School Portal...'), findsOneWidget);
    expect(find.byIcon(Icons.school), findsOneWidget);

    // Wait for the transition to login page
    await tester.pumpAndSettle(const Duration(seconds: 4));

    // Verify login page is shown
    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.text('Continue your educational journey'), findsOneWidget);
  });
}
