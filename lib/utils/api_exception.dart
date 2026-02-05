/// Custom exception for API errors
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  ApiException({
    required this.message,
    this.statusCode,
    this.data,
  });

  @override
  String toString() {
    return 'ApiException: $message (Status Code: $statusCode)';
  }

  /// Factory constructor for network errors
  factory ApiException.networkError() {
    return ApiException(
      message: 'No internet connection. Please check your network.',
      statusCode: null,
    );
  }

  /// Factory constructor for timeout errors
  factory ApiException.timeout() {
    return ApiException(
      message: 'Request timeout. Please try again.',
      statusCode: 408,
    );
  }

  /// Factory constructor for unauthorized errors
  factory ApiException.unauthorized() {
    return ApiException(
      message: 'Unauthorized. Please login again.',
      statusCode: 401,
    );
  }

  /// Factory constructor for server errors
  factory ApiException.serverError() {
    return ApiException(
      message: 'Server error. Please try again later.',
      statusCode: 500,
    );
  }

  /// Factory constructor for validation errors
  factory ApiException.validationError(String message) {
    return ApiException(
      message: message,
      statusCode: 422,
    );
  }
}
