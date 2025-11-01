import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../config/app_config.dart';

/// Provider for the ApiService instance
/// 
/// Centralized provider for the API service used across the app.
/// Configured with the base URL from environment config.
final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService(
    baseUrl: Environment.apiBaseUrl,
  );
});

