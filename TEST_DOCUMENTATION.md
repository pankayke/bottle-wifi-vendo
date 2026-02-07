# Test Documentation

This document provides comprehensive information about the test suite for the Bottle WiFi Vendo Flutter application.

---

## Test Structure

```
test/
├── helpers/
│   ├── test_helpers.dart         # Common test utilities
│   └── mock_classes.dart         # Mock implementations
├── widgets/
│   ├── common_widgets_test.dart          # Tests for common UI widgets
│   ├── cached_image_widget_test.dart     # Tests for image caching widgets
│   └── paginated_list_view_test.dart     # Tests for pagination widgets
├── integration/
│   ├── api_service_test.dart              # API service integration tests
│   ├── auth_flow_test.dart                # Authentication flow tests
│   └── bottle_submission_flow_test.dart   # Bottle submission tests
└── widget_test.dart              # Original sample test
```

---

## Test Coverage

### Widget Tests (42 tests total)

#### **common_widgets_test.dart** (24 tests)
- ✅ LoadingIndicator rendering and customization
- ✅ SmallLoadingIndicator size and color
- ✅ ErrorMessage display and retry functionality
- ✅ EmptyState display with custom icons and actions
- ✅ PrimaryButton interactions, loading states, and icons
- ✅ OutlinedButtonCustom behavior
- ✅ CustomCard rendering and tap handling
- ✅ SnackBar utilities (success, error, info)

#### **cached_image_widget_test.dart** (18 tests)
- ✅ CachedImageWidget loading and error states
- ✅ Custom dimensions and BoxFit
- ✅ Border radius application
- ✅ CachedAvatarImage circular rendering
- ✅ Fallback icons for missing images
- ✅ BottleImageWidget specialized rendering
- ✅ MachineImageWidget custom styling

#### **paginated_list_view_test.dart** (15 tests)
- ✅ PaginatedListView item rendering
- ✅ Loading indicators during data fetch
- ✅ Empty state display
- ✅ Error handling and retry
- ✅ Infinite scroll pagination
- ✅ Pull-to-refresh functionality
- ✅ Custom separators
- ✅ PaginatedGridView grid layout
- ✅ Edge cases (null items, rapid scrolling)

### Integration Tests (45+ tests total)

#### **api_service_test.dart** (25+ tests)
- ✅ Login with valid credentials
- ✅ Registration flow
- ✅ Logout and token clearing
- ✅ User profile fetching
- ✅ Bottle reporting
- ✅ Paginated bottle history
- ✅ Bottle statistics
- ✅ Internet package purchase
- ✅ Error handling (401, 404, 500, timeout, connection errors)
- ✅ Automatic token refresh
- ✅ Request header verification

#### **auth_flow_test.dart** (15+ tests)
- ✅ Successful login state updates
- ✅ Failed login error handling
- ✅ Loading states during authentication
- ✅ Registration with valid data
- ✅ Registration validation errors
- ✅ Logout state clearing
- ✅ Initialize authentication from storage
- ✅ Refresh user profile
- ✅ Multiple simultaneous login attempts
- ✅ Error message clearing on retry

#### **bottle_submission_flow_test.dart** (15+ tests)
- ✅ Successful bottle report
- ✅ Failed bottle report errors
- ✅ Bottle report without image
- ✅ Loading states during submission
- ✅ Multiple bottle accumulation
- ✅ Bottle history pagination
- ✅ Empty history handling
- ✅ Statistics fetching
- ✅ Single bottle details
- ✅ Concurrent submissions
- ✅ Large image data handling

---

## Running Tests

### Install Test Dependencies

```bash
flutter pub get
```

This will install:
- `mockito` - Mock generation
- `mocktail` - Alternative mocking library
- `http_mock_adapter` - Mock HTTP responses for Dio
- `network_image_mock` - Mock network images in widget tests

### Run All Tests

```bash
flutter test
```

### Run Specific Test File

```bash
# Widget tests
flutter test test/widgets/common_widgets_test.dart
flutter test test/widgets/cached_image_widget_test.dart
flutter test test/widgets/paginated_list_view_test.dart

# Integration tests
flutter test test/integration/api_service_test.dart
flutter test test/integration/auth_flow_test.dart
flutter test test/integration/bottle_submission_flow_test.dart
```

### Run Tests with Coverage

```bash
flutter test --coverage
```

This generates a coverage report in `coverage/lcov.info`.

### View Coverage Report (HTML)

```bash
# Install genhtml (on Windows via Chocolatey or WSL)
# On WSL/Linux:
sudo apt-get install lcov

# Generate HTML report
genhtml coverage/lcov.info -o coverage/html

# Open in browser
start coverage/html/index.html
```

### Run Tests in Watch Mode (continuous testing)

```bash
flutter test --watch
```

---

## Test Helpers

### TestData Class

Provides mock data generators for tests:

```dart
TestData.testEmail          // 'test@example.com'
TestData.testPassword       // 'password123'
TestData.testToken          // 'mock_token_12345'
TestData.testUsername       // 'Test User'

TestData.mockUser()         // User object
TestData.mockAuthResponse() // Authentication response
TestData.mockBottleLog()    // Bottle log object
TestData.mockPaginatedResponse() // Paginated API response
TestData.mockErrorResponse() // Error response
```

### Test Utilities

```dart
createTestWidget(widget)                    // Wrap widget with MaterialApp
createTestWidgetWithProviders(...)          // Wrap with providers
pumpAndSettleWithDelay(tester)              // Pump with delay
findTextContaining(substring)               // Find text by substring
enterText(tester, finder, text)             // Enter text in TextField
tapAndSettle(tester, finder)                // Tap and wait
expectSnackBar(text)                        // Verify snackbar
expectDialog(text)                          // Verify dialog
```

---

## Best Practices

### 1. **Arrange-Act-Assert Pattern**
```dart
test('description', () {
  // Arrange - Setup
  final mockData = TestData.mockUser();
  when(() => mockService.getData()).thenReturn(mockData);
  
  // Act - Execute
  final result = await provider.fetchData();
  
  // Assert - Verify
  expect(result.success, true);
  verify(() => mockService.getData()).called(1);
});
```

### 2. **Use Descriptive Test Names**
```dart
❌ test('test login', () { ... });
✅ test('successful login updates state correctly', () { ... });
```

### 3. **Test One Thing Per Test**
```dart
❌ test('login and fetch profile', () { ... });
✅ test('successful login updates authentication state', () { ... });
✅ test('login triggers profile fetch', () { ... });
```

### 4. **Group Related Tests**
```dart
group('Authentication Tests', () {
  group('Login Tests', () { ... });
  group('Register Tests', () { ... });
  group('Logout Tests', () { ... });
});
```

### 5. **Clean Up After Tests**
```dart
setUp(() {
  // Initialize before each test
});

tearDown(() {
  // Clean up after each test
});
```

---

## Continuous Integration

### GitHub Actions Example

Create `.github/workflows/test.yml`:

```yaml
name: Flutter Tests

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main, develop ]

jobs:
  test:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.10.7'
    
    - name: Install dependencies
      run: flutter pub get
    
    - name: Run tests
      run: flutter test --coverage
    
    - name: Upload coverage to Codecov
      uses: codecov/codecov-action@v3
      with:
        files: coverage/lcov.info
```

---

## Troubleshooting

### Issue: Tests Fail with "MissingPluginException"

**Solution:** Some widgets require platform channels. Use mocks or run tests with:
```bash
flutter test --platform chrome
```

### Issue: Network images not loading in tests

**Solution:** Use `network_image_mock`:
```dart
import 'package:network_image_mock/network_image_mock.dart';

testWidgets('test with images', (tester) async {
  await mockNetworkImagesFor(() async {
    await tester.pumpWidget(MyWidget());
  });
});
```

### Issue: Tests timeout

**Solution:** Increase timeout:
```dart
testWidgets('slow test', (tester) async {
  // ...
}, timeout: Timeout(Duration(minutes: 2)));
```

### Issue: State not updating in provider tests

**Solution:** Ensure you're awaiting async operations:
```dart
await provider.someAsyncMethod();
await tester.pumpAndSettle(); // For widget tests
```

---

## Test Coverage Goals

| Category | Current | Target |
|----------|---------|--------|
| Widget Tests | 42 tests | 80%+ coverage |
| Integration Tests | 45+ tests | 70%+ coverage |
| Overall | 87+ tests | 75%+ coverage |

---

## Adding New Tests

### 1. Create test file

```dart
import 'package:flutter_test/flutter_test.dart';
import '../helpers/test_helpers.dart';

void main() {
  group('MyFeature Tests', () {
    test('should do something', () {
      // Arrange
      // Act
      // Assert
    });
  });
}
```

### 2. Run the new tests

```bash
flutter test test/path/to/new_test.dart
```

### 3. Verify coverage

```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

---

## Resources

- [Flutter Testing Documentation](https://docs.flutter.dev/testing)
- [Mockito Documentation](https://pub.dev/packages/mockito)
- [Mocktail Documentation](https://pub.dev/packages/mocktail)
- [Test Coverage in Flutter](https://docs.flutter.dev/testing/coverage)

---

## Summary

The test suite provides comprehensive coverage of:

✅ **42 Widget Tests** - UI components render correctly  
✅ **45+ Integration Tests** - Services and flows work end-to-end  
✅ **Test Helpers** - Reusable utilities for consistent testing  
✅ **Mock Data** - Realistic test data generators  
✅ **CI/CD Ready** - Easy integration with GitHub Actions  

**Total: 87+ tests** ensuring code quality and reliability.

Run `flutter test --coverage` to generate a detailed coverage report!
