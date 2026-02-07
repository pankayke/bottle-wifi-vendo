/// Integration Tests for Bottle Submission Flow
///
/// Tests the complete bottle reporting and management flow

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:bottle_wifi/providers/bottle_provider.dart';
import 'package:bottle_wifi/services/api_service.dart';
import 'package:bottle_wifi/models/bottle_log.dart';
import 'package:bottle_wifi/utils/api_response.dart';
import 'package:bottle_wifi/utils/api_exception.dart';
import '../helpers/test_helpers.dart';
import '../helpers/mock_classes.dart';

class MockApiService extends Mock implements ApiService {}

void main() {
  late BottleProvider bottleProvider;
  late MockApiService mockApiService;

  setUp(() {
    registerMocktailFallbacks();
    mockApiService = MockApiService();
    bottleProvider = BottleProvider(apiService: mockApiService);
  });

  group('Bottle Reporting Tests', () {
    test('successful bottle report adds to list', () async {
      final mockBottle = BottleLog.fromJson(
        TestData.mockBottleLog(id: 1, status: 'verified'),
      );

      when(
        () => mockApiService.reportBottle(
          machineId: 1,
          imageBase64: 'base64_image_data',
        ),
      ).thenAnswer(
        (_) async => ApiResponse<BottleLog>(success: true, data: mockBottle),
      );

      final result = await bottleProvider.reportBottle(
        machineId: 1,
        imageBase64: 'base64_image_data',
      );

      expect(result, true);
      expect(bottleProvider.bottleLogs.length, 1);
      expect(bottleProvider.bottleLogs.first.id, 1);
      expect(bottleProvider.bottleLogs.first.status, 'verified');
      expect(bottleProvider.isLoading, false);
      expect(bottleProvider.errorMessage, isNull);
    });

    test('failed bottle report shows error', () async {
      when(
        () => mockApiService.reportBottle(
          machineId: any(named: 'machineId'),
          imageBase64: any(named: 'imageBase64'),
        ),
      ).thenThrow(ApiException('Machine not found'));

      final result = await bottleProvider.reportBottle(
        machineId: 999,
        imageBase64: 'base64_image_data',
      );

      expect(result, false);
      expect(bottleProvider.bottleLogs.isEmpty, true);
      expect(bottleProvider.errorMessage, 'Machine not found');
      expect(bottleProvider.isLoading, false);
    });

    test('bottle report without image succeeds', () async {
      final mockBottle = BottleLog.fromJson(TestData.mockBottleLog(id: 1));

      when(
        () => mockApiService.reportBottle(machineId: 1, imageBase64: null),
      ).thenAnswer(
        (_) async => ApiResponse<BottleLog>(success: true, data: mockBottle),
      );

      final result = await bottleProvider.reportBottle(
        machineId: 1,
        imageBase64: null,
      );

      expect(result, true);
      expect(bottleProvider.bottleLogs.length, 1);
    });

    test('bottle report sets loading state', () async {
      final mockBottle = BottleLog.fromJson(TestData.mockBottleLog());

      when(
        () => mockApiService.reportBottle(
          machineId: any(named: 'machineId'),
          imageBase64: any(named: 'imageBase64'),
        ),
      ).thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 100));
        return ApiResponse<BottleLog>(success: true, data: mockBottle);
      });

      // Start report without awaiting
      final reportFuture = bottleProvider.reportBottle(
        machineId: 1,
        imageBase64: 'base64_data',
      );

      // Check loading state
      await Future.delayed(const Duration(milliseconds: 10));
      expect(bottleProvider.isLoading, true);

      // Complete report
      await reportFuture;
      expect(bottleProvider.isLoading, false);
    });

    test('multiple bottle reports accumulate correctly', () async {
      final bottle1 = BottleLog.fromJson(TestData.mockBottleLog(id: 1));
      final bottle2 = BottleLog.fromJson(TestData.mockBottleLog(id: 2));
      final bottle3 = BottleLog.fromJson(TestData.mockBottleLog(id: 3));

      when(
        () => mockApiService.reportBottle(
          machineId: any(named: 'machineId'),
          imageBase64: any(named: 'imageBase64'),
        ),
      ).thenAnswer((_) async {
        return ApiResponse<BottleLog>(success: true, data: bottle1);
      });

      await bottleProvider.reportBottle(machineId: 1, imageBase64: 'img1');

      when(
        () => mockApiService.reportBottle(
          machineId: any(named: 'machineId'),
          imageBase64: any(named: 'imageBase64'),
        ),
      ).thenAnswer((_) async {
        return ApiResponse<BottleLog>(success: true, data: bottle2);
      });

      await bottleProvider.reportBottle(machineId: 1, imageBase64: 'img2');

      when(
        () => mockApiService.reportBottle(
          machineId: any(named: 'machineId'),
          imageBase64: any(named: 'imageBase64'),
        ),
      ).thenAnswer((_) async {
        return ApiResponse<BottleLog>(success: true, data: bottle3);
      });

      await bottleProvider.reportBottle(machineId: 1, imageBase64: 'img3');

      expect(bottleProvider.bottleLogs.length, 3);
      expect(bottleProvider.bottleLogs[0].id, 3); // Most recent first
      expect(bottleProvider.bottleLogs[1].id, 2);
      expect(bottleProvider.bottleLogs[2].id, 1);
    });
  });

  group('Bottle History Tests', () {
    test('fetching bottle history loads data', () async {
      final mockBottles = List.generate(
        20,
        (i) => BottleLog.fromJson(TestData.mockBottleLog(id: i + 1)),
      );

      when(
        () => mockApiService.getBottleHistory(page: 1, perPage: 20),
      ).thenAnswer(
        (_) async => ApiResponse<List<BottleLog>>(
          success: true,
          data: mockBottles,
          meta: {'current_page': 1, 'last_page': 5, 'total': 100},
        ),
      );

      final result = await bottleProvider.fetchBottleHistory(page: 1);

      expect(result.length, 20);
      expect(bottleProvider.errorMessage, isNull);
    });

    test('fetching empty history returns empty list', () async {
      when(
        () => mockApiService.getBottleHistory(page: 1, perPage: 20),
      ).thenAnswer(
        (_) async => ApiResponse<List<BottleLog>>(
          success: true,
          data: [],
          meta: {'current_page': 1, 'last_page': 1, 'total': 0},
        ),
      );

      final result = await bottleProvider.fetchBottleHistory(page: 1);

      expect(result.isEmpty, true);
    });

    test('fetching bottle history handles errors', () async {
      when(
        () => mockApiService.getBottleHistory(
          page: any(named: 'page'),
          perPage: any(named: 'perPage'),
        ),
      ).thenThrow(ApiException('Network error'));

      expect(
        () => bottleProvider.fetchBottleHistory(page: 1),
        throwsA(isA<ApiException>()),
      );
    });

    test('pagination loads next page correctly', () async {
      final page1Bottles = List.generate(
        20,
        (i) => BottleLog.fromJson(TestData.mockBottleLog(id: i + 1)),
      );
      final page2Bottles = List.generate(
        20,
        (i) => BottleLog.fromJson(TestData.mockBottleLog(id: i + 21)),
      );

      when(
        () => mockApiService.getBottleHistory(page: 1, perPage: 20),
      ).thenAnswer(
        (_) async =>
            ApiResponse<List<BottleLog>>(success: true, data: page1Bottles),
      );

      when(
        () => mockApiService.getBottleHistory(page: 2, perPage: 20),
      ).thenAnswer(
        (_) async =>
            ApiResponse<List<BottleLog>>(success: true, data: page2Bottles),
      );

      final page1Result = await bottleProvider.fetchBottleHistory(page: 1);
      expect(page1Result.length, 20);
      expect(page1Result.first.id, 1);

      final page2Result = await bottleProvider.fetchBottleHistory(page: 2);
      expect(page2Result.length, 20);
      expect(page2Result.first.id, 21);
    });
  });

  group('Bottle Statistics Tests', () {
    test('fetching statistics returns data', () async {
      when(() => mockApiService.getBottleStatistics()).thenAnswer(
        (_) async => ApiResponse<Map<String, dynamic>>(
          success: true,
          data: {
            'total_bottles': 150,
            'total_credits': 750,
            'verified_bottles': 140,
            'pending_bottles': 10,
            'rejected_bottles': 0,
          },
        ),
      );

      final result = await bottleProvider.fetchBottleStatistics();

      expect(result, true);
      expect(bottleProvider.errorMessage, isNull);
    });

    test('fetching statistics handles errors', () async {
      when(
        () => mockApiService.getBottleStatistics(),
      ).thenThrow(ApiException('Failed to fetch statistics'));

      final result = await bottleProvider.fetchBottleStatistics();

      expect(result, false);
      expect(bottleProvider.errorMessage, isNotNull);
    });
  });

  group('Bottle Details Tests', () {
    test('fetching single bottle returns details', () async {
      final mockBottle = BottleLog.fromJson(
        TestData.mockBottleLog(id: 1, status: 'verified'),
      );

      when(() => mockApiService.getBottleById(1)).thenAnswer(
        (_) async => ApiResponse<BottleLog>(success: true, data: mockBottle),
      );

      final result = await bottleProvider.getBottleById(1);

      expect(result, isNotNull);
      expect(result!.id, 1);
      expect(result.status, 'verified');
    });

    test('fetching non-existent bottle returns null', () async {
      when(
        () => mockApiService.getBottleById(999),
      ).thenThrow(ApiException('Bottle not found'));

      final result = await bottleProvider.getBottleById(999);

      expect(result, isNull);
      expect(bottleProvider.errorMessage, 'Bottle not found');
    });
  });

  group('Provider State Management Tests', () {
    test('clear error message works correctly', () async {
      when(
        () => mockApiService.reportBottle(
          machineId: any(named: 'machineId'),
          imageBase64: any(named: 'imageBase64'),
        ),
      ).thenThrow(ApiException('Test error'));

      await bottleProvider.reportBottle(machineId: 1, imageBase64: 'test');

      expect(bottleProvider.errorMessage, 'Test error');

      bottleProvider.clearError();

      expect(bottleProvider.errorMessage, isNull);
    });

    test('notifies listeners on state changes', () async {
      final mockBottle = BottleLog.fromJson(TestData.mockBottleLog());

      when(
        () => mockApiService.reportBottle(
          machineId: any(named: 'machineId'),
          imageBase64: any(named: 'imageBase64'),
        ),
      ).thenAnswer(
        (_) async => ApiResponse<BottleLog>(success: true, data: mockBottle),
      );

      var notifyCount = 0;
      bottleProvider.addListener(() {
        notifyCount++;
      });

      await bottleProvider.reportBottle(machineId: 1, imageBase64: 'test');

      expect(notifyCount, greaterThan(0));
    });
  });

  group('Edge Cases', () {
    test('handles concurrent bottle submissions', () async {
      final bottle1 = BottleLog.fromJson(TestData.mockBottleLog(id: 1));
      final bottle2 = BottleLog.fromJson(TestData.mockBottleLog(id: 2));

      when(
        () => mockApiService.reportBottle(machineId: 1, imageBase64: 'img1'),
      ).thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 100));
        return ApiResponse<BottleLog>(success: true, data: bottle1);
      });

      when(
        () => mockApiService.reportBottle(machineId: 1, imageBase64: 'img2'),
      ).thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 100));
        return ApiResponse<BottleLog>(success: true, data: bottle2);
      });

      // Submit two bottles concurrently
      final future1 = bottleProvider.reportBottle(
        machineId: 1,
        imageBase64: 'img1',
      );
      final future2 = bottleProvider.reportBottle(
        machineId: 1,
        imageBase64: 'img2',
      );

      await Future.wait([future1, future2]);

      expect(bottleProvider.bottleLogs.length, 2);
    });

    test('clears error on new successful submission', () async {
      // First failed attempt
      when(
        () => mockApiService.reportBottle(machineId: 999, imageBase64: 'test'),
      ).thenThrow(ApiException('Machine not found'));

      await bottleProvider.reportBottle(machineId: 999, imageBase64: 'test');

      expect(bottleProvider.errorMessage, 'Machine not found');

      // Second successful attempt
      final mockBottle = BottleLog.fromJson(TestData.mockBottleLog());
      when(
        () => mockApiService.reportBottle(machineId: 1, imageBase64: 'test'),
      ).thenAnswer(
        (_) async => ApiResponse<BottleLog>(success: true, data: mockBottle),
      );

      await bottleProvider.reportBottle(machineId: 1, imageBase64: 'test');

      expect(bottleProvider.errorMessage, isNull);
    });

    test('handles large image data', () async {
      final mockBottle = BottleLog.fromJson(TestData.mockBottleLog());
      final largeImageData = 'x' * 1000000; // 1MB of data

      when(
        () => mockApiService.reportBottle(
          machineId: 1,
          imageBase64: largeImageData,
        ),
      ).thenAnswer(
        (_) async => ApiResponse<BottleLog>(success: true, data: mockBottle),
      );

      final result = await bottleProvider.reportBottle(
        machineId: 1,
        imageBase64: largeImageData,
      );

      expect(result, true);
    });
  });
}
