import 'dart:convert';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';

/// Authentication service with proper token validation
class AuthService {
  /// Check if user has a valid authentication session
  /// This validates both session existence AND token validity
  static Future<AuthStatus> validateAuth() async {
    try {
      // 1. Check if we have a session
      final session = await Amplify.Auth.fetchAuthSession();
      if (!session.isSignedIn) {
        return AuthStatus.notSignedIn;
      }

      // 2. Validate the JWT token
      final cognitoSession = session as CognitoAuthSession;
      final tokens = cognitoSession.userPoolTokensResult.value;
      
      if (tokens.idToken == null) {
        return AuthStatus.invalidToken;
      }

      // 3. Check token expiration by decoding the JWT payload
      try {
        final tokenPayload = _decodeJwtPayload(tokens.idToken.raw);
        if (tokenPayload == null) {
          return AuthStatus.invalidToken;
        }
        
        // Check expiration from JWT payload
        final exp = tokenPayload['exp'] as int?;
        if (exp != null) {
          final tokenExpiry = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
          final now = DateTime.now();
          
          if (tokenExpiry.isBefore(now)) {
            return AuthStatus.tokenExpired;
          }
        }
      } catch (e) {
        return AuthStatus.invalidToken;
      }

      return AuthStatus.valid;
    } catch (e) {
      print('Auth validation error: $e');
      return AuthStatus.error;
    }
  }

  /// Sign out and clear all authentication data
  static Future<void> signOut() async {
    try {
      await Amplify.Auth.signOut();
    } catch (e) {
      print('Sign out error: $e');
      // Even if signOut fails, we should clear local data
    }
  }

  /// Get current user ID from valid token
  static Future<String?> getCurrentUserId() async {
    try {
      final session = await Amplify.Auth.fetchAuthSession();
      if (!session.isSignedIn) return null;
      
      final cognitoSession = session as CognitoAuthSession;
      final tokens = cognitoSession.userPoolTokensResult.value;
      
      if (tokens.idToken == null) return null;
      
      final payload = _decodeJwtPayload(tokens.idToken.raw);
      return payload?['sub'] as String?;
    } catch (e) {
      print('Get user ID error: $e');
      return null;
    }
  }

  /// Decode JWT payload (basic validation)
  static Map<String, dynamic>? _decodeJwtPayload(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      
      // Decode payload (middle part)
      final payload = parts[1];
      // Add padding if needed
      final paddedPayload = payload.padRight(
        payload.length + (4 - payload.length % 4) % 4,
        '=',
      );
      
      final decoded = utf8.decode(base64Url.decode(paddedPayload));
      return jsonDecode(decoded) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }
}

/// Authentication status enum
enum AuthStatus {
  valid,
  notSignedIn,
  tokenExpired,
  invalidToken,
  error,
}

/// Extension for AuthStatus
extension AuthStatusExtension on AuthStatus {
  bool get isValid => this == AuthStatus.valid;
  bool get needsSignIn => this == AuthStatus.notSignedIn || 
                         this == AuthStatus.tokenExpired || 
                         this == AuthStatus.invalidToken;
  
  String get message {
    switch (this) {
      case AuthStatus.valid:
        return 'Authenticated';
      case AuthStatus.notSignedIn:
        return 'Not signed in';
      case AuthStatus.tokenExpired:
        return 'Session expired';
      case AuthStatus.invalidToken:
        return 'Invalid authentication';
      case AuthStatus.error:
        return 'Authentication error';
    }
  }
}
