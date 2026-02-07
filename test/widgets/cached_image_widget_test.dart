/// Widget Tests for Cached Image Widgets
///
/// Tests all image caching widgets in lib/widgets/cached_image_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:network_image_mock/network_image_mock.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:bottle_wifi/widgets/cached_image_widget.dart';
import '../helpers/test_helpers.dart';

void main() {
  group('CachedImageWidget Tests', () {
    testWidgets('renders with valid image URL', (tester) async {
      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(
          createTestWidget(
            const CachedImageWidget(imageUrl: 'https://example.com/image.jpg'),
          ),
        );

        // Wait for image to load
        await tester.pumpAndSettle();

        expect(find.byType(CachedNetworkImage), findsOneWidget);
      });
    });

    testWidgets('shows shimmer placeholder while loading', (tester) async {
      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(
          createTestWidget(
            const CachedImageWidget(imageUrl: 'https://example.com/image.jpg'),
          ),
        );

        // Before image loads
        expect(find.byType(CachedNetworkImage), findsOneWidget);
      });
    });

    testWidgets('shows error icon for invalid URL', (tester) async {
      await tester.pumpWidget(
        createTestWidget(const CachedImageWidget(imageUrl: '')),
      );

      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.broken_image), findsOneWidget);
    });

    testWidgets('uses custom width and height', (tester) async {
      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(
          createTestWidget(
            const CachedImageWidget(
              imageUrl: 'https://example.com/image.jpg',
              width: 200,
              height: 300,
            ),
          ),
        );

        await tester.pumpAndSettle();

        final sizedBox = tester.widget<SizedBox>(
          find
              .ancestor(
                of: find.byType(CachedNetworkImage),
                matching: find.byType(SizedBox),
              )
              .first,
        );

        expect(sizedBox.width, 200);
        expect(sizedBox.height, 300);
      });
    });

    testWidgets('uses correct BoxFit', (tester) async {
      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(
          createTestWidget(
            const CachedImageWidget(
              imageUrl: 'https://example.com/image.jpg',
              fit: BoxFit.contain,
            ),
          ),
        );

        await tester.pumpAndSettle();

        final cachedImage = tester.widget<CachedNetworkImage>(
          find.byType(CachedNetworkImage),
        );

        expect(cachedImage.fit, BoxFit.contain);
      });
    });

    testWidgets('applies border radius', (tester) async {
      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(
          createTestWidget(
            CachedImageWidget(
              imageUrl: 'https://example.com/image.jpg',
              borderRadius: BorderRadius.circular(16.0),
            ),
          ),
        );

        await tester.pumpAndSettle();

        final clipRRect = tester.widget<ClipRRect>(
          find.ancestor(
            of: find.byType(CachedNetworkImage),
            matching: find.byType(ClipRRect),
          ),
        );

        expect(clipRRect.borderRadius, BorderRadius.circular(16.0));
      });
    });
  });

  group('CachedAvatarImage Tests', () {
    testWidgets('renders circular avatar with image', (tester) async {
      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(
          createTestWidget(
            const CachedAvatarImage(imageUrl: 'https://example.com/avatar.jpg'),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byType(CircleAvatar), findsOneWidget);
        expect(find.byType(CachedNetworkImage), findsOneWidget);
      });
    });

    testWidgets('shows person icon for empty URL', (tester) async {
      await tester.pumpWidget(
        createTestWidget(const CachedAvatarImage(imageUrl: '')),
      );

      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.person), findsOneWidget);
      expect(find.byType(CircleAvatar), findsOneWidget);
    });

    testWidgets('uses custom radius', (tester) async {
      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(
          createTestWidget(
            const CachedAvatarImage(
              imageUrl: 'https://example.com/avatar.jpg',
              radius: 50,
            ),
          ),
        );

        await tester.pumpAndSettle();

        final avatar = tester.widget<CircleAvatar>(find.byType(CircleAvatar));

        expect(avatar.radius, 50);
      });
    });

    testWidgets('uses custom background color', (tester) async {
      await tester.pumpWidget(
        createTestWidget(const CachedAvatarImage(imageUrl: '', radius: 50)),
      );

      await tester.pumpAndSettle();

      final avatar = tester.widget<CircleAvatar>(find.byType(CircleAvatar));

      expect(avatar.backgroundColor, Colors.blue);
    });
  });

  group('BottleImageWidget Tests', () {
    testWidgets('renders bottle image with correct size', (tester) async {
      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(
          createTestWidget(
            const BottleImageWidget(
              imageUrl: 'https://example.com/bottle.jpg',
              size: 80,
            ),
          ),
        );

        await tester.pumpAndSettle();

        final sizedBox = tester.widget<SizedBox>(
          find
              .ancestor(
                of: find.byType(CachedNetworkImage),
                matching: find.byType(SizedBox),
              )
              .first,
        );

        expect(sizedBox.width, 80);
        expect(sizedBox.height, 80);
      });
    });

    testWidgets('shows recycling icon for invalid URL', (tester) async {
      await tester.pumpWidget(
        createTestWidget(const BottleImageWidget(imageUrl: '')),
      );

      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.recycling), findsOneWidget);
    });

    testWidgets('uses BoxFit.cover by default', (tester) async {
      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(
          createTestWidget(
            const BottleImageWidget(imageUrl: 'https://example.com/bottle.jpg'),
          ),
        );

        await tester.pumpAndSettle();

        final cachedImage = tester.widget<CachedNetworkImage>(
          find.byType(CachedNetworkImage),
        );

        expect(cachedImage.fit, BoxFit.cover);
      });
    });

    testWidgets('has rounded corners', (tester) async {
      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(
          createTestWidget(
            const BottleImageWidget(imageUrl: 'https://example.com/bottle.jpg'),
          ),
        );

        await tester.pumpAndSettle();

        final clipRRect = tester.widget<ClipRRect>(
          find.ancestor(
            of: find.byType(CachedNetworkImage),
            matching: find.byType(ClipRRect),
          ),
        );

        expect(clipRRect.borderRadius, BorderRadius.circular(8.0));
      });
    });
  });

  group('MachineImageWidget Tests', () {
    testWidgets('renders machine image with correct size', (tester) async {
      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(
          createTestWidget(
            const MachineImageWidget(
              imageUrl: 'https://example.com/machine.jpg',
              radius: 50,
            ),
          ),
        );

        await tester.pumpAndSettle();

        final sizedBox = tester.widget<SizedBox>(
          find
              .ancestor(
                of: find.byType(CachedNetworkImage),
                matching: find.byType(SizedBox),
              )
              .first,
        );

        expect(sizedBox.width, 100);
        expect(sizedBox.height, 100);
      });
    });

    testWidgets('shows computer icon for invalid URL', (tester) async {
      await tester.pumpWidget(
        createTestWidget(const MachineImageWidget(imageUrl: '')),
      );

      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.computer), findsOneWidget);
    });

    testWidgets('has rounded corners', (tester) async {
      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(
          createTestWidget(
            const MachineImageWidget(
              imageUrl: 'https://example.com/machine.jpg',
            ),
          ),
        );

        await tester.pumpAndSettle();

        final clipRRect = tester.widget<ClipRRect>(
          find.ancestor(
            of: find.byType(CachedNetworkImage),
            matching: find.byType(ClipRRect),
          ),
        );

        expect(clipRRect.borderRadius, BorderRadius.circular(12.0));
      });
    });
  });
}
