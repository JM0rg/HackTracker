import 'dart:convert';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:http/http.dart' as http;

/// API Service for HackTracker backend
/// 
/// Handles all HTTP requests to the API Gateway with automatic
/// authentication using Cognito ID tokens.
class ApiService {
  final String baseUrl;

  ApiService({required this.baseUrl});

  /// Get the current user's Cognito ID token
  Future<String> _getIdToken() async {
    final session = await Amplify.Auth.fetchAuthSession();
    final cognitoSession = session as CognitoAuthSession;
    return cognitoSession.userPoolTokensResult.value.idToken.raw;
  }

  /// Make an authenticated HTTP request
  Future<http.Response> _authenticatedRequest({
    required String method,
    required String path,
    Map<String, dynamic>? body,
  }) async {
    final idToken = await _getIdToken();
    final uri = Uri.parse('$baseUrl$path');

    final headers = {
      'Authorization': 'Bearer $idToken',
      'Content-Type': 'application/json',
    };

    switch (method.toUpperCase()) {
      case 'GET':
        return await http.get(uri, headers: headers);
      case 'POST':
        return await http.post(
          uri,
          headers: headers,
          body: body != null ? jsonEncode(body) : null,
        );
      case 'PUT':
        return await http.put(
          uri,
          headers: headers,
          body: body != null ? jsonEncode(body) : null,
        );
      case 'DELETE':
        return await http.delete(uri, headers: headers);
      default:
        throw ArgumentError('Unsupported HTTP method: $method');
    }
  }

  /// Handle API response and decode JSON
  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    } else {
      // Parse error response
      dynamic errorBody;
      try {
        errorBody = jsonDecode(response.body);
      } catch (e) {
        errorBody = {'error': response.body};
      }

      throw ApiException(
        statusCode: response.statusCode,
        message: errorBody['error'] ?? 'Unknown error',
        errorType: errorBody['errorType'],
      );
    }
  }

  // ========== TEAMS ENDPOINTS ==========

  /// List all teams for the authenticated user
  /// 
  /// Returns: List of teams with role and member count
  Future<List<Team>> listTeams() async {
    final response = await _authenticatedRequest(
      method: 'GET',
      path: '/teams',
    );

    final data = _handleResponse(response);
    final teams = (data['teams'] as List)
        .map((json) => Team.fromJson(json))
        .toList();
    
    return teams;
  }

  /// Create a new team
  /// 
  /// Returns: The created team with teamId
  Future<Team> createTeam({
    required String name,
    String? description,
  }) async {
    final response = await _authenticatedRequest(
      method: 'POST',
      path: '/teams',
      body: {
        'name': name,
        'description': description ?? '',
      },
    );

    final data = _handleResponse(response);
    return Team.fromJson(data);
  }

  /// Get team details by ID
  Future<Team> getTeam(String teamId) async {
    final response = await _authenticatedRequest(
      method: 'GET',
      path: '/teams/${Uri.encodeComponent(teamId)}',
    );

    final data = _handleResponse(response);
    return Team.fromJson(data);
  }

  /// Update team details (owner only)
  Future<Team> updateTeam({
    required String teamId,
    String? name,
    String? description,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (description != null) body['description'] = description;

    final response = await _authenticatedRequest(
      method: 'PUT',
      path: '/teams/${Uri.encodeComponent(teamId)}',
      body: body,
    );

    final data = _handleResponse(response);
    return Team.fromJson(data);
  }

  /// Delete team (owner only)
  Future<void> deleteTeam(String teamId) async {
    final response = await _authenticatedRequest(
      method: 'DELETE',
      path: '/teams/${Uri.encodeComponent(teamId)}',
    );

    _handleResponse(response);
  }
}

/// Team model
class Team {
  final String teamId;
  final String name;
  final String description;
  final String role;
  final int memberCount;
  final DateTime joinedAt;
  final DateTime createdAt;

  Team({
    required this.teamId,
    required this.name,
    required this.description,
    required this.role,
    required this.memberCount,
    required this.joinedAt,
    required this.createdAt,
  });

  factory Team.fromJson(Map<String, dynamic> json) {
    return Team(
      teamId: json['teamId'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      role: json['role'] as String,
      memberCount: json['memberCount'] as int? ?? 0,
      joinedAt: DateTime.parse(json['joinedAt'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'teamId': teamId,
      'name': name,
      'description': description,
      'role': role,
      'memberCount': memberCount,
      'joinedAt': joinedAt.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  bool get isOwner => role == 'owner';
  bool get isMember => role == 'member';
  bool get isViewer => role == 'viewer';
}

/// API Exception
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

