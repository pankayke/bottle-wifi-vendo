/// Widget Tests for Common Widgets
/// 
/// Tests all custom widgets in lib/widgets/common_widgets.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bottle_wifi/widgets/common_widgets.dart';
import '../helpers/test_helpers.dart';

void main() {
  group('LoadingIndicator Widget Tests', () {
    testWidgets('renders without message by default', (tester) async {
      await tester.pumpWidget(
        createTestWidget(const LoadingIndicator()),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(Text), findsNothing);
    });

    testWidgets('renders with custom message', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          const LoadingIndicator(message: 'Fetching data...'),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Fetching data...'), findsOneWidget);
    });

    testWidgets('renders with custom color', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          const LoadingIndicator(color: Colors.red),
        ),
      );

      final circularProgress = tester.widget<CircularProgressIndicator>(
        find.byType(CircularProgressIndicator),
      );
      expect(circularProgress.valueColor?.value, Colors.red);
    });

    testWidgets('renders with custom size', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          const LoadingIndicator(size: 50),
        ),
      );

      final sizedBox = tester.widget<SizedBox>(
        find.ancestor(
          of: find.byType(CircularProgressIndicator),
          matching: find.byType(SizedBox),
        ).first,
      );
      expect(sizedBox.width, 50);
      expect(sizedBox.height, 50);
    });
  });

  group('SmallLoadingIndicator Widget Tests', () {
    testWidgets('renders with correct size', (tester) async {
      await tester.pumpWidget(
        createTestWidget(const SmallLoadingIndicator()),
      );

      final sizedBox = tester.widget<SizedBox>(
        find.ancestor(
          of: find.byType(CircularProgressIndicator),
          matching: find.byType(SizedBox),
        ).first,
      );
      expect(sizedBox.width, 20);
      expect(sizedBox.height, 20);
    });

    testWidgets('renders with white color', (tester) async {
      await tester.pumpWidget(
        createTestWidget(const SmallLoadingIndicator()),
      );

      final circularProgress = tester.widget<CircularProgressIndicator>(
        find.byType(CircularProgressIndicator),
      );
      expect(circularProgress.valueColor?.value, Colors.white);
    });
  });

  group('ErrorMessage Widget Tests', () {
    testWidgets('renders error message and icon', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          ErrorMessage(
            message: 'Something went wrong',
            onRetry: () {},
          ),
        ),
      );

      expect(find.text('Something went wrong'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('renders retry button with refresh icon', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          ErrorMessage(
            message: 'Network error',
            onRetry: () {},
          ),
        ),
      );

      expect(find.text('Retry'), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });

    testWidgets('calls onRetry when button is tapped', (tester) async {
      var retryCalled = false;

      await tester.pumpWidget(
        createTestWidget(
          ErrorMessage(
            message: 'Network error',
            onRetry: () {
              retryCalled = true;
            },
          ),
        ),
      );

      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(retryCalled, true);
    });

    testWidgets('renders with custom icon', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          ErrorMessage(
            message: 'No internet',
            icon: Icons.wifi_off,
            onRetry: () {},
          ),
        ),
      );

      expect(find.byIcon(Icons.wifi_off), findsOneWidget);
    });
  });

  group('EmptyState Widget Tests', () {
    testWidgets('renders title, message, and icon', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          const EmptyState(
            title: 'No Items',
            message: 'Add your first item',
          ),
        ),
      );

      expect(find.text('No Items'), findsOneWidget);
      expect(find.text('Add your first item'), findsOneWidget);
      expect(find.byIcon(Icons.inbox_outlined), findsOneWidget);
    });

    testWidgets('renders with custom icon', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          const EmptyState(
            title: 'No Bottles',
            message: 'Report your first bottle',
            icon: Icons.recycling,
          ),
        ),
      );

      expect(find.byIcon(Icons.recycling), findsOneWidget);
    });

    testWidgets('renders action button when provided', (tester) async {
      var actionCalled = false;

      await tester.pumpWidget(
        createTestWidget(
          EmptyState(
            title: 'No Items',
            message: 'Get started now',
            actionLabel: 'Add Item',
            onAction: () {
              actionCalled = true;
            },
          ),
        ),
      );

      expect(find.text('Add Item'), findsOneWidget);

      await tester.tap(find.text('Add Item'));
      await tester.pumpAndSettle();

      expect(actionCalled, true);
    });
  });

  group('PrimaryButton Widget Tests', () {
    testWidgets('renders button with label', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          PrimaryButton(
            label: 'Submit',
            onPressed: () {},
          ),
        ),
      );

      expect(find.text('Submit'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('calls onPressed when tapped', (tester) async {
      var pressed = false;

      await tester.pumpWidget(
        createTestWidget(
          PrimaryButton(
            label: 'Submit',
            onPressed: () {
              pressed = true;
            },
          ),
        ),
      );

      await tester.tap(find.text('Submit'));
      await tester.pump();

      expect(pressed, true);
    });

    testWidgets('shows loading indicator when isLoading is true', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          PrimaryButton(
            label: 'Submit',
            onPressed: () {},
            isLoading: true,
          ),
        ),
      );

      expect(find.byType(SmallLoadingIndicator), findsOneWidget);
      expect(find.text('Submit'), findsNothing);
    });

    testWidgets('is disabled when isLoading', (tester) async {
      var pressed = false;

      await tester.pumpWidget(
        createTestWidget(
          PrimaryButton(
            label: 'Submit',
            onPressed: () {
              pressed = true;
            },
            isLoading: true,
          ),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(pressed, false);
    });

    testWidgets('renders with icon when provided', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          PrimaryButton(
            label: 'Login',
            icon: Icons.login,
            onPressed: () {},
          ),
        ),
      );

      expect(find.byIcon(Icons.login), findsOneWidget);
      expect(find.text('Login'), findsOneWidget);
    });

    testWidgets('has correct height', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          PrimaryButton(
            label: 'Submit',
            onPressed: () {},
          ),
        ),
      );

      final sizedBox = tester.widget<SizedBox>(
        find.ancestor(
          of: find.byType(ElevatedButton),
          matching: find.byType(SizedBox),
        ),
      );
      expect(sizedBox.height, 50);
    });
  });

  group('OutlinedButtonCustom Widget Tests', () {
    testWidgets('renders outlined button with label', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          OutlinedButtonCustom(
            label: 'Cancel',
            onPressed: () {},
          ),
        ),
      );

      expect(find.text('Cancel'), findsOneWidget);
      expect(find.byType(OutlinedButton), findsOneWidget);
    });

    testWidgets('calls onPressed when tapped', (tester) async {
      var pressed = false;

      await tester.pumpWidget(
        createTestWidget(
          OutlinedButtonCustom(
            label: 'Cancel',
            onPressed: () {
              pressed = true;
            },
          ),
        ),
      );

      await tester.tap(find.text('Cancel'));
      await tester.pump();

      expect(pressed, true);
    });

    testWidgets('shows loading indicator when isLoading', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          OutlinedButtonCustom(
            label: 'Cancel',
            onPressed: () {},
            isLoading: true,
          ),
        ),
      );

      expect(find.byType(SmallLoadingIndicator), findsOneWidget);
      expect(find.text('Cancel'), findsNothing);
    });
  });

  group('CustomCard Widget Tests', () {
    testWidgets('renders child widget', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          const CustomCard(
            child: Text('Card Content'),
          ),
        ),
      );

      expect(find.text('Card Content'), findsOneWidget);
      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets('has correct default padding', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          const CustomCard(
            child: Text('Content'),
          ),
        ),
      );

      final padding = tester.widget<Padding>(
        find.descendant(
          of: find.byType(InkWell),
          matching: find.byType(Padding),
        ),
      );
      expect(padding.padding, const EdgeInsets.all(16.0));
    });

    testWidgets('calls onTap when tapped', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        createTestWidget(
          CustomCard(
            onTap: () {
              tapped = true;
            },
            child: const Text('Tappable Card'),
          ),
        ),
      );

      await tester.tap(find.text('Tappable Card'));
      await tester.pump();

      expect(tapped, true);
    });

    testWidgets('always has InkWell', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          const CustomCard(
            child: Text('Card'),
          ),
        ),
      );

      // CustomCard always has InkWell, even without onTap
      expect(find.byType(InkWell), findsOneWidget);
    });
  });

  group('SnackBar Functions Tests', () {
    testWidgets('showSuccessSnackBar displays success message', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () {
                    showSuccessSnackBar(context, 'Operation successful');
                  },
                  child: const Text('Show Success'),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Show Success'));
      await tester.pumpAndSettle();

      expect(find.text('Operation successful'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('showErrorSnackBar displays error message', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () {
                    showErrorSnackBar(context, 'Something went wrong');
                  },
                  child: const Text('Show Error'),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Show Error'));
      await tester.pumpAndSettle();

      expect(find.text('Something went wrong'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('showInfoSnackBar displays info message', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () {
                    showInfoSnackBar(context, 'Information message');
                  ),
                  child: const Text('Show Info'),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Show Info'));
      await tester.pumpAndSettle();

      expect(find.text('Information message'), findsOneWidget);
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
    });
  });
}
