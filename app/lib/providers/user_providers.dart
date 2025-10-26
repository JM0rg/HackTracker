import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import '../utils/persistence.dart';
import '../services/auth_service.dart';

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

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'email': email,
        'username': username,
      };

  factory User.fromJson(Map<String, dynamic> json) => User(
        userId: json['userId'] as String,
        email: json['email'] as String,
        username: json['username'] as String?,
      );
}

class CurrentUserNotifier extends AsyncNotifier<User> {
  static const _cacheKey = 'current_user';

  @override
  Future<User> build() async {
    // Try cache first
    final cached = await Persistence.getJson<User>(
      _cacheKey,
      (obj) => User.fromJson(obj as Map<String, dynamic>),
    );
    if (cached != null) {
      // Background refresh
      Future.microtask(() async {
        try {
          final fresh = await _fetch();
          state = AsyncValue.data(fresh);
          await Persistence.setJson(_cacheKey, fresh.toJson());
        } catch (_) {}
      });
      return cached;
    }

    final user = await _fetch();
    await Persistence.setJson(_cacheKey, user.toJson());
    return user;
  }

  Future<User> _fetch() async {
    // Validate authentication first
    final authStatus = await AuthService.validateAuth();
    if (!authStatus.isValid) {
      throw Exception('Authentication required: ${authStatus.message}');
    }

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
  }

  Future<void> refreshUser() async {
    state = await AsyncValue.guard(() async {
      final fresh = await _fetch();
      await Persistence.setJson(_cacheKey, fresh.toJson());
      return fresh;
    });
  }
}

final currentUserProvider = AsyncNotifierProvider<CurrentUserNotifier, User>(() => CurrentUserNotifier());

