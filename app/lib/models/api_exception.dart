class ApiException implements Exception {
  final int statusCode;
  final String message;
  final String? errorType;

  ApiException({
    required this.statusCode,
    required this.message,
    this.errorType,
  });

  @override
  String toString() {
    return 'ApiException($statusCode): $message${errorType != null ? ' ($errorType)' : ''}';
  }

  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isNotFound => statusCode == 404;
  bool get isValidationError => statusCode == 400;
  bool get isServerError => statusCode >= 500;
}

