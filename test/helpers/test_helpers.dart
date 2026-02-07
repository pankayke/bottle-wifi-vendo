/// Test Helper Utilities
///
/// Provides common utilities and helpers for testing the Bottle WiFi app.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

/// Wraps a widget with MaterialApp for testing
Widget createTestWidget(Widget child) {
  return MaterialApp(home: Scaffold(body: child));
}

/// Wraps a widget with MaterialApp and providers
Widget createTestWidgetWithProviders({
  required Widget child,
  required List<ChangeNotifierProvider> providers,
}) {
  return MultiProvider(
    providers: providers,
    child: MaterialApp(home: Scaffold(body: child)),
  );
}

/// Pumps the widget and waits for all animations
Future<void> pumpAndSettleWithDelay(
  WidgetTester tester, {
  Duration delay = const Duration(milliseconds: 100),
}) async {
  await tester.pump();
  await tester.pump(delay);
  await tester.pumpAndSettle();
}

/// Finds text containing a substring (case-insensitive)
Finder findTextContaining(String substring) {
  return find.byWidgetPredicate(
    (widget) =>
        widget is Text &&
        widget.data != null &&
        widget.data!.toLowerCase().contains(substring.toLowerCase()),
  );
}

/// Finds RichText containing a substring (case-insensitive)
Finder findRichTextContaining(String substring) {
  return find.byWidgetPredicate((widget) {
    if (widget is RichText) {
      final text = widget.text.toPlainText();
      return text.toLowerCase().contains(substring.toLowerCase());
    }
    return false;
  });
}

/// Scrolls to find a widget
Future<void> scrollToFinder(
  WidgetTester tester,
  Finder scrollable,
  Finder item, {
  double delta = 300,
}) async {
  final scrollableWidget = tester.widget<Scrollable>(scrollable);
  final scrollController = scrollableWidget.controller;

  if (scrollController == null) {
    throw Exception('Scrollable does not have a controller');
  }

  while (tester.any(item) == false) {
    await tester.drag(scrollable, Offset(0, -delta));
    await tester.pumpAndSettle();

    if (scrollController.position.pixels >=
        scrollController.position.maxScrollExtent) {
      throw Exception('Item not found in scrollable');
    }
  }
}

/// Enters text into a TextField
Future<void> enterText(
  WidgetTester tester,
  Finder textField,
  String text,
) async {
  await tester.tap(textField);
  await tester.pumpAndSettle();
  await tester.enterText(textField, text);
  await tester.pumpAndSettle();
}

/// Taps a button and waits for animations
Future<void> tapAndSettle(WidgetTester tester, Finder button) async {
  await tester.tap(button);
  await tester.pumpAndSettle();
}

/// Verifies that a snackbar with specific text is shown
void expectSnackBar(String text) {
  expect(find.text(text), findsOneWidget);
  expect(find.byType(SnackBar), findsOneWidget);
}

/// Verifies that a dialog with specific text is shown
void expectDialog(String text) {
  expect(find.text(text), findsOneWidget);
  expect(find.byType(AlertDialog), findsOneWidget);
}

/// Wait for a specific duration
Future<void> wait(Duration duration) async {
  await Future.delayed(duration);
}

/// Test data generators

class TestData {
  static const String testEmail = 'test@example.com';
  static const String testPassword = 'password123';
  static const String testToken = 'mock_token_12345';
  static const String testUsername = 'Test User';

  static Map<String, dynamic> mockUser({
    int id = 1,
    String name = 'Test User',
    String email = 'test@example.com',
    String? avatarUrl,
  }) {
    return {
      'id': id,
      'name': name,
      'email': email,
      'avatar_url': avatarUrl,
      'created_at': '2024-01-01T00:00:00.000000Z',
    };
  }

  static Map<String, dynamic> mockAuthResponse({
    required String token,
    int expiresIn = 3600,
  }) {
    return {
      'success': true,
      'data': {'token': token, 'expires_in': expiresIn, 'user': mockUser()},
    };
  }

  static Map<String, dynamic> mockBottleLog({
    int id = 1,
    String status = 'verified',
    int creditsEarned = 5,
    String? imageUrl,
  }) {
    return {
      'id': id,
      'user_id': 1,
      'machine_id': 1,
      'status': status,
      'credits_earned': creditsEarned,
      'image_url': imageUrl ?? 'https://example.com/bottle.jpg',
      'created_at': '2024-01-01T00:00:00.000000Z',
      'updated_at': '2024-01-01T00:00:00.000000Z',
    };
  }

  static Map<String, dynamic> mockPaginatedResponse<T>({
    required List<T> data,
    int currentPage = 1,
    int lastPage = 5,
    int total = 100,
  }) {
    return {
      'success': true,
      'data': data,
      'meta': {
        'current_page': currentPage,
        'last_page': lastPage,
        'per_page': data.length,
        'total': total,
      },
    };
  }

  static Map<String, dynamic> mockErrorResponse({
    String message = 'An error occurred',
    int statusCode = 400,
  }) {
    return {'success': false, 'message': message, 'errors': {}};
  }
}
