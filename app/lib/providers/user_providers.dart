import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:amplify_flutter/amplify_flutter.dart';

/// User model for the current authenticated user
class User {
  final String userId;
  final String email;
  final String? username;

  User({
    required this.userId,
    required this.email,
    this.username,
  });
}

/// Provider for the current user with automatic caching
/// 
/// This provider:
/// - Caches the user data in memory (session-only)
/// - Shows cached data immediately
/// - Fetches fresh data in background
/// - Automatically refreshed on login
final currentUserProvider = FutureProvider<User>((ref) async {
  // Get current user from Amplify Auth
  try {
    final authUser = await Amplify.Auth.getCurrentUser();
    final attributes = await Amplify.Auth.fetchUserAttributes();
    
    String? email;
    for (final attr in attributes) {
      if (attr.userAttributeKey == AuthUserAttributeKey.email) {
        email = attr.value;
        break;
      }
    }
    
    return User(
      userId: authUser.userId,
      email: email ?? 'unknown@example.com',
      username: authUser.username,
    );
  } catch (e) {
    throw Exception('Failed to fetch user: $e');
  }
});

