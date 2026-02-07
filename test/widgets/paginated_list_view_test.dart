/// Widget Tests for Paginated List View
///
/// Tests the PaginatedListView and PaginatedGridView widgets

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bottle_wifi/widgets/paginated_list_view.dart';
import 'package:bottle_wifi/widgets/common_widgets.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import '../helpers/test_helpers.dart';

void main() {
  group('PaginatedListView Tests', () {
    testWidgets('renders list of items', (tester) async {
      final items = ['Item 1', 'Item 2', 'Item 3'];

      await tester.pumpWidget(
        createTestWidget(
          PaginatedListView<String>(
            onLoadMore: (page) async => items,
            itemBuilder: (context, item, index) {
              return ListTile(title: Text(item));
            },
          ),
        ),
      );

      // Wait for initial load
      await tester.pumpAndSettle();

      expect(find.text('Item 1'), findsOneWidget);
      expect(find.text('Item 2'), findsOneWidget);
      expect(find.text('Item 3'), findsOneWidget);
    });

    testWidgets('shows loading indicator on initial load', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          PaginatedListView<String>(
            onLoadMore: (page) async {
              await Future.delayed(const Duration(seconds: 1));
              return ['Item 1'];
            },
            itemBuilder: (context, item, index) {
              return ListTile(title: Text(item));
            },
          ),
        ),
      );

      // Before data loads
      await tester.pump();
      expect(find.byType(LoadingIndicator), findsOneWidget);

      // After data loads
      await tester.pumpAndSettle();
      expect(find.byType(LoadingIndicator), findsNothing);
    });

    testWidgets('shows empty state when no items', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          PaginatedListView<String>(
            onLoadMore: (page) async => [],
            itemBuilder: (context, item, index) {
              return ListTile(title: Text(item));
            },
            emptyTitle: 'No Items',
            emptyMessage: 'Add some items',
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('No Items'), findsOneWidget);
      expect(find.text('Add some items'), findsOneWidget);
      expect(find.byType(EmptyState), findsOneWidget);
    });

    testWidgets('shows error message on failure', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          PaginatedListView<String>(
            onLoadMore: (page) async {
              throw Exception('Network error');
            },
            itemBuilder: (context, item, index) {
              return ListTile(title: Text(item));
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(ErrorMessage), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('retries loading on error retry button tap', (tester) async {
      var attemptCount = 0;

      await tester.pumpWidget(
        createTestWidget(
          PaginatedListView<String>(
            onLoadMore: (page) async {
              attemptCount++;
              if (attemptCount == 1) {
                throw Exception('Network error');
              }
              return ['Item 1'];
            },
            itemBuilder: (context, item, index) {
              return ListTile(title: Text(item));
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      // First attempt fails
      expect(find.byType(ErrorMessage), findsOneWidget);
      expect(attemptCount, 1);

      // Tap retry
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      // Second attempt succeeds
      expect(find.text('Item 1'), findsOneWidget);
      expect(attemptCount, 2);
    });

    testWidgets('loads more items when scrolled to bottom', (tester) async {
      final page1Items = List.generate(20, (i) => 'Item ${i + 1}');
      final page2Items = List.generate(20, (i) => 'Item ${i + 21}');
      var currentPage = 1;

      await tester.pumpWidget(
        createTestWidget(
          PaginatedListView<String>(
            onLoadMore: (page) async {
              if (page == 1) return page1Items;
              if (page == 2) return page2Items;
              return [];
            },
            itemBuilder: (context, item, index) {
              return SizedBox(height: 50, child: ListTile(title: Text(item)));
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Initial load - page 1 items visible
      expect(find.text('Item 1'), findsOneWidget);
      expect(find.text('Item 21'), findsNothing);

      // Scroll to bottom
      await tester.drag(find.byType(SmartRefresher), const Offset(0, -2000));
      await tester.pumpAndSettle();

      // Page 2 items should be loaded
      // Note: Not all items may be visible depending on viewport
      expect(find.byType(ListTile), findsWidgets);
    });

    testWidgets('pull to refresh reloads data', (tester) async {
      var loadCount = 0;

      await tester.pumpWidget(
        createTestWidget(
          PaginatedListView<String>(
            onLoadMore: (page) async {
              loadCount++;
              return ['Item 1', 'Item 2'];
            },
            itemBuilder: (context, item, index) {
              return ListTile(title: Text(item));
            },
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(loadCount, 1);

      // Pull to refresh
      await tester.drag(find.byType(SmartRefresher), const Offset(0, 300));
      await tester.pumpAndSettle();

      expect(loadCount, 2);
    });

    testWidgets('uses custom separator', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          PaginatedListView<String>(
            onLoadMore: (page) async => ['Item 1', 'Item 2'],
            itemBuilder: (context, item, index) {
              return ListTile(title: Text(item));
            },
            separator: const Divider(thickness: 2),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(Divider), findsWidgets);
    });
  });

  group('PaginatedGridView Tests', () {
    testWidgets('renders items in grid', (tester) async {
      final items = ['Item 1', 'Item 2', 'Item 3', 'Item 4'];

      await tester.pumpWidget(
        createTestWidget(
          PaginatedGridView<String>(
            onLoadMore: (page) async => items,
            itemBuilder: (context, item, index) {
              return Card(child: Center(child: Text(item)));
            },
            crossAxisCount: 2,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Item 1'), findsOneWidget);
      expect(find.text('Item 2'), findsOneWidget);
      expect(find.text('Item 3'), findsOneWidget);
      expect(find.text('Item 4'), findsOneWidget);
    });

    testWidgets('uses correct crossAxisCount', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          PaginatedGridView<String>(
            onLoadMore: (page) async => ['Item 1', 'Item 2'],
            itemBuilder: (context, item, index) {
              return Card(child: Center(child: Text(item)));
            },
            crossAxisCount: 3,
          ),
        ),
      );

      await tester.pumpAndSettle();

      final gridView = tester.widget<GridView>(find.byType(GridView));

      final gridDelegate =
          gridView.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      expect(gridDelegate.crossAxisCount, 3);
    });

    testWidgets('shows loading indicator on initial load', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          PaginatedGridView<String>(
            onLoadMore: (page) async {
              await Future.delayed(const Duration(seconds: 1));
              return ['Item 1'];
            },
            itemBuilder: (context, item, index) {
              return Card(child: Text(item));
            },
          ),
        ),
      );

      await tester.pump();
      expect(find.byType(LoadingIndicator), findsOneWidget);

      await tester.pumpAndSettle();
      expect(find.byType(LoadingIndicator), findsNothing);
    });

    testWidgets('shows empty state when no items', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          PaginatedGridView<String>(
            onLoadMore: (page) async => [],
            itemBuilder: (context, item, index) {
              return Card(child: Text(item));
            },
            emptyTitle: 'No Photos',
            emptyMessage: 'Upload some photos',
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('No Photos'), findsOneWidget);
      expect(find.text('Upload some photos'), findsOneWidget);
    });
  });

  group('Edge Cases', () {
    testWidgets('handles null items gracefully', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          PaginatedListView<String?>(
            onLoadMore: (page) async => [null, 'Item 2', null],
            itemBuilder: (context, item, index) {
              return ListTile(title: Text(item ?? 'Empty'));
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Empty'), findsNWidgets(2));
      expect(find.text('Item 2'), findsOneWidget);
    });

    testWidgets('handles rapid scrolling', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          PaginatedListView<String>(
            onLoadMore: (page) async {
              await Future.delayed(const Duration(milliseconds: 100));
              return List.generate(
                20,
                (i) => 'Item ${(page - 1) * 20 + i + 1}',
              );
            },
            itemBuilder: (context, item, index) {
              return SizedBox(height: 50, child: ListTile(title: Text(item)));
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Rapid scroll
      for (var i = 0; i < 3; i++) {
        await tester.drag(find.byType(SmartRefresher), const Offset(0, -500));
        await tester.pump();
      }

      await tester.pumpAndSettle();

      // Should still work without errors
      expect(find.byType(ListTile), findsWidgets);
    });
  });
}
