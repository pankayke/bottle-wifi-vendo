class ApiResponse<T> {
  final bool success;
  final String? message;
  final T? data;
  final dynamic error;

  ApiResponse({required this.success, this.message, this.data, this.error});

  factory ApiResponse.success({required T data, String? message}) {
    return ApiResponse<T>(success: true, data: data, message: message);
  }

  factory ApiResponse.error({required String message, dynamic error}) {
    return ApiResponse<T>(success: false, message: message, error: error);
  }

  @override
  String toString() {
    return 'ApiResponse(success: $success, message: $message, data: $data, error: $error)';
  }
}
