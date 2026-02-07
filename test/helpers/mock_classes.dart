/// Mock Classes for Testing
///
/// Contains all mock implementations used in tests.

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mocktail/mocktail.dart';
import 'package:bottle_wifi/services/enhanced_api_service.dart';
import 'package:bottle_wifi/services/storage_service.dart';

// Mock Dio
class MockDio extends Mock implements Dio {}

// Mock Response
class MockResponse<T> extends Mock implements Response<T> {}

// Mock RequestOptions
class MockRequestOptions extends Mock implements RequestOptions {}

// Mock FlutterSecureStorage
class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

// Mock StorageService
class MockStorageService extends Mock implements StorageService {}

// Mock EnhancedApiService
class MockEnhancedApiService extends Mock implements EnhancedApiService {}

// Mock Dio Error
class MockDioException extends Mock implements DioException {}

/// Helper to register fallback values for mocktail
void registerMocktailFallbacks() {
  registerFallbackValue(RequestOptions(path: ''));
  registerFallbackValue(const AndroidOptions());
  registerFallbackValue(const IOSOptions());
}

/// Creates a mock Dio response
Response<T> createMockResponse<T>({
  required T data,
  int statusCode = 200,
  String statusMessage = 'OK',
  Map<String, dynamic>? headers,
}) {
  return Response<T>(
    data: data,
    statusCode: statusCode,
    statusMessage: statusMessage,
    headers: Headers.fromMap(headers ?? {}),
    requestOptions: RequestOptions(path: '/test'),
  );
}

/// Creates a mock DioException
DioException createMockDioException({
  required RequestOptions requestOptions,
  DioExceptionType type = DioExceptionType.badResponse,
  Response? response,
  String message = 'Mock error',
}) {
  return DioException(
    requestOptions: requestOptions,
    type: type,
    response: response,
    message: message,
  );
}
