import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import '../models/team.dart';
import '../models/player.dart';
import '../models/game.dart';
import '../models/atbat.dart';
import '../models/user_context.dart';
import '../models/api_exception.dart' as models;

/// API Service for HackTracker backend
/// 
/// Handles all HTTP requests to the API Gateway with automatic
/// authentication using Cognito ID tokens.
class ApiService {
  final String baseUrl;

  ApiService({required this.baseUrl});

  /// Get the current user's Cognito ID token
  Future<String> _getIdToken() async {
    try {
      // Validate authentication first
      final authStatus = await AuthService.validateAuth();
      if (!authStatus.isValid) {
        throw models.ApiException(
          statusCode: 401,
          message: 'Authentication required: ${authStatus.message}',
          errorType: 'Unauthorized',
        );
      }

      final session = await Amplify.Auth.fetchAuthSession();
      final cognitoSession = session as CognitoAuthSession;
      final tokens = cognitoSession.userPoolTokensResult.value;
      
      return tokens.idToken.raw;
    } catch (e) {
      if (e is models.ApiException) rethrow;
      
      // If it's an auth error, sign out and throw proper exception
      await AuthService.signOut();
      throw models.ApiException(
        statusCode: 401,
        message: 'Authentication failed: $e',
        errorType: 'Unauthorized',
      );
    }
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
      case 'PATCH':
        return await http.patch(
          uri,
          headers: headers,
          body: body != null ? jsonEncode(body) : null,
        );
      default:
        throw ArgumentError('Unsupported HTTP method: $method');
    }
  }

  /// Handle API response and decode JSON
  Future<dynamic> _handleResponse(http.Response response) async {
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

      // Handle authentication errors specially
      if (response.statusCode == 401) {
        // Sign out user on authentication failure (await to ensure completion)
        await AuthService.signOut();
        throw models.ApiException(
          statusCode: response.statusCode,
          message: 'Session expired. Please sign in again.',
          errorType: 'Unauthorized',
        );
      }

      throw models.ApiException(
        statusCode: response.statusCode,
        message: errorBody['error'] ?? 'Unknown error',
        errorType: errorBody['errorType'],
      );
    }
  }

  // ========== TEAMS ENDPOINTS ==========

  /// List all teams for the authenticated user
  /// 
  /// Returns: List of teams with role and member count (personal teams filtered by backend)
  Future<List<Team>> listTeams() async {
    // Get current user's ID from Cognito
    final user = await Amplify.Auth.getCurrentUser();
    final userId = user.userId;
    
    final response = await _authenticatedRequest(
      method: 'GET',
      path: '/teams?userId=$userId',
    );

    final data = await _handleResponse(response);
    final teams = (data['teams'] as List)
        .map((json) => Team.fromJson(json))
        .toList();
    
    return teams;
  }

  /// Get the user's personal stats team
  /// 
  /// Returns: The personal team (used for Player View)
  Future<Team?> getPersonalTeam() async {
    // Get current user's ID from Cognito
    final user = await Amplify.Auth.getCurrentUser();
    final userId = user.userId;
    
    final response = await _authenticatedRequest(
      method: 'GET',
      path: '/teams?userId=$userId',
    );

    final data = await _handleResponse(response);
    final teams = (data['teams'] as List)
        .map((json) => Team.fromJson(json))
        .where((team) => team.isPersonal) // Only get personal team
        .toList();
    
    return teams.isNotEmpty ? teams.first : null;
  }

  /// Create a new team
  /// 
  /// Returns: The created team with teamId
  Future<Team> createTeam({
    required String name,
    required String teamType, // MANAGED or PERSONAL
    String? description,
  }) async {
    final body = <String, dynamic>{
      'name': name,
      'teamType': teamType,
    };
    if (description != null && description.isNotEmpty) {
      body['description'] = description;
    }
    
    final response = await _authenticatedRequest(
      method: 'POST',
      path: '/teams',
      body: body,
    );

    final data = await _handleResponse(response);
    return Team.fromJson(data);
  }

  /// Get team details by ID
  Future<Team> getTeam(String teamId) async {
    final response = await _authenticatedRequest(
      method: 'GET',
      path: '/teams/${Uri.encodeComponent(teamId)}',
    );

    final data = await _handleResponse(response);
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

    final data = await _handleResponse(response);
    return Team.fromJson(data);
  }

  /// Delete team (owner only)
  Future<void> deleteTeam(String teamId) async {
    final response = await _authenticatedRequest(
      method: 'DELETE',
      path: '/teams/${Uri.encodeComponent(teamId)}',
    );

    await _handleResponse(response);
  }

  // ========== PLAYERS ENDPOINTS ==========

  /// List players for a team
  Future<List<Player>> listPlayers(
    String teamId, {
    String? status,
    bool? isGhost,
    bool includeRoles = false,
  }) async {
    final query = <String, String>{};
    if (status != null && status.isNotEmpty) {
      query['status'] = status;
    }
    if (isGhost != null) {
      query['isGhost'] = isGhost.toString();
    }
    if (includeRoles) {
      query['includeRoles'] = 'true';
    }

    final queryString = query.isEmpty
        ? ''
        : '?${query.entries.map((e) => '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}').join('&')}';

    final response = await _authenticatedRequest(
      method: 'GET',
      path: '/teams/${Uri.encodeComponent(teamId)}/players$queryString',
    );

    final data = await _handleResponse(response);
    final players = (data['players'] as List)
        .map((json) => Player.fromJson(json as Map<String, dynamic>))
        .toList();

    return players;
  }

  /// Get a single player
  Future<Player> getPlayer(String teamId, String playerId) async {
    final response = await _authenticatedRequest(
      method: 'GET',
      path: '/teams/${Uri.encodeComponent(teamId)}/players/${Uri.encodeComponent(playerId)}',
    );

    final data = await _handleResponse(response);
    return Player.fromJson(data as Map<String, dynamic>);
  }

  /// Add a new player to the roster
  Future<Player> addPlayer({
    required String teamId,
    required String firstName,
    String? lastName,
    int? playerNumber,
    String? status,
    List<String>? positions,
  }) async {
    final body = <String, dynamic>{'firstName': firstName};
    if (lastName != null && lastName.isNotEmpty) body['lastName'] = lastName;
    if (playerNumber != null) body['playerNumber'] = playerNumber;
    if (status != null && status.isNotEmpty) body['status'] = status;
    if (positions != null && positions.isNotEmpty) body['positions'] = positions;

    final response = await _authenticatedRequest(
      method: 'POST',
      path: '/teams/${Uri.encodeComponent(teamId)}/players',
      body: body,
    );

    final data = await _handleResponse(response);
    return Player.fromJson(data as Map<String, dynamic>);
  }

  /// Update an existing player
  Future<Player> updatePlayer({
    required String teamId,
    required String playerId,
    String? firstName,
    String? lastName,
    int? playerNumber,
    String? status,
    List<String>? positions,
  }) async {
    final body = <String, dynamic>{};
    if (firstName != null) body['firstName'] = firstName;
    if (lastName != null) body['lastName'] = lastName; // may be null to remove via backend behavior
    if (playerNumber != null) body['playerNumber'] = playerNumber; // may be null to remove
    if (status != null) body['status'] = status;
    if (positions != null) body['positions'] = positions; // may be empty array to remove

    final response = await _authenticatedRequest(
      method: 'PUT',
      path: '/teams/${Uri.encodeComponent(teamId)}/players/${Uri.encodeComponent(playerId)}',
      body: body,
    );

    final data = await _handleResponse(response);
    return Player.fromJson(data as Map<String, dynamic>);
  }

  /// Remove a player (ghost players only)
  Future<void> removePlayer(String teamId, String playerId) async {
    final response = await _authenticatedRequest(
      method: 'DELETE',
      path: '/teams/${Uri.encodeComponent(teamId)}/players/${Uri.encodeComponent(playerId)}',
    );

    await _handleResponse(response);
  }

  // ========== GAMES ENDPOINTS ==========

  /// List games for a team
  Future<List<Game>> listGames(String teamId) async {
    final response = await _authenticatedRequest(
      method: 'GET',
      path: '/teams/${Uri.encodeComponent(teamId)}/games',
    );

    final data = await _handleResponse(response);
    // Response is an array directly
    final games = (data as List)
        .map((json) => Game.fromJson(json as Map<String, dynamic>))
        .toList();

    return games;
  }

  /// Get a single game
  Future<Game> getGame(String gameId) async {
    final response = await _authenticatedRequest(
      method: 'GET',
      path: '/games/${Uri.encodeComponent(gameId)}',
    );

    final data = await _handleResponse(response);
    return Game.fromJson(data as Map<String, dynamic>);
  }

  /// Create a new game
  Future<Game> createGame({
    String? teamId,
    String? status,
    int? teamScore,
    int? opponentScore,
    String? scheduledStart,
    String? opponentName,
    String? location,
    String? seasonId,
    List<dynamic>? lineup,
  }) async {
    final body = <String, dynamic>{};

    if (teamId != null) body['teamId'] = teamId;
    if (status != null) body['status'] = status;
    if (teamScore != null) body['teamScore'] = teamScore;
    if (opponentScore != null) body['opponentScore'] = opponentScore;
    if (scheduledStart != null) body['scheduledStart'] = scheduledStart;
    if (opponentName != null) body['opponentName'] = opponentName;
    if (location != null) body['location'] = location;
    if (seasonId != null) body['seasonId'] = seasonId;
    if (lineup != null && lineup.isNotEmpty) body['lineup'] = lineup;

    final response = await _authenticatedRequest(
      method: 'POST',
      path: '/games',
      body: body,
    );

    final data = await _handleResponse(response);
    return Game.fromJson(data as Map<String, dynamic>);
  }

  /// Update an existing game
  Future<Game> updateGame({
    required String gameId,
    String? status,
    int? teamScore,
    int? opponentScore,
    String? scheduledStart,
    String? opponentName,
    String? location,
    String? seasonId,
    List<dynamic>? lineup,
  }) async {
    final body = <String, dynamic>{};

    if (status != null) body['status'] = status;
    if (teamScore != null) body['teamScore'] = teamScore;
    if (opponentScore != null) body['opponentScore'] = opponentScore;
    if (scheduledStart != null) body['scheduledStart'] = scheduledStart;
    if (opponentName != null) body['opponentName'] = opponentName;
    if (location != null) body['location'] = location;
    if (seasonId != null) body['seasonId'] = seasonId;
    if (lineup != null) body['lineup'] = lineup;

    final response = await _authenticatedRequest(
      method: 'PUT',
      path: '/games/${Uri.encodeComponent(gameId)}',
      body: body,
    );

    final data = await _handleResponse(response);
    return Game.fromJson(data as Map<String, dynamic>);
  }

  /// Delete a game
  Future<void> deleteGame(String gameId) async {
    final response = await _authenticatedRequest(
      method: 'DELETE',
      path: '/games/${Uri.encodeComponent(gameId)}',
    );

    await _handleResponse(response);
  }

  // ==================== AtBat API Methods ====================

  /// Create a new at-bat for a game
  Future<AtBat> createAtBat({
    required String gameId,
    required String playerId,
    required String result,
    required int inning,
    required int outs,
    required int battingOrder,
    Map<String, double>? hitLocation,
    String? hitType,
    int? rbis,
  }) async {
    final body = <String, dynamic>{
      'playerId': playerId,
      'result': result,
      'inning': inning,
      'outs': outs,
      'battingOrder': battingOrder,
    };

    if (hitLocation != null) body['hitLocation'] = hitLocation;
    if (hitType != null) body['hitType'] = hitType;
    if (rbis != null) body['rbis'] = rbis;

    final response = await _authenticatedRequest(
      method: 'POST',
      path: '/games/${Uri.encodeComponent(gameId)}/atbats',
      body: body,
    );

    final data = await _handleResponse(response);
    return AtBat.fromJson(data as Map<String, dynamic>);
  }

  /// List all at-bats for a game
  Future<List<AtBat>> listAtBats(String gameId) async {
    final response = await _authenticatedRequest(
      method: 'GET',
      path: '/games/${Uri.encodeComponent(gameId)}/atbats',
    );

    final data = await _handleResponse(response);
    return (data as List).map((json) => AtBat.fromJson(json as Map<String, dynamic>)).toList();
  }

  /// Get a specific at-bat
  Future<AtBat> getAtBat(String gameId, String atBatId) async {
    final response = await _authenticatedRequest(
      method: 'GET',
      path: '/games/${Uri.encodeComponent(gameId)}/atbats/${Uri.encodeComponent(atBatId)}',
    );

    final data = await _handleResponse(response);
    return AtBat.fromJson(data as Map<String, dynamic>);
  }

  /// Update an existing at-bat
  Future<AtBat> updateAtBat({
    required String gameId,
    required String atBatId,
    String? result,
    Map<String, double>? hitLocation,
    String? hitType,
    int? rbis,
    int? inning,
    int? outs,
  }) async {
    final body = <String, dynamic>{};

    if (result != null) body['result'] = result;
    if (hitLocation != null) body['hitLocation'] = hitLocation;
    if (hitType != null) body['hitType'] = hitType;
    if (rbis != null) body['rbis'] = rbis;
    if (inning != null) body['inning'] = inning;
    if (outs != null) body['outs'] = outs;

    final response = await _authenticatedRequest(
      method: 'PUT',
      path: '/games/${Uri.encodeComponent(gameId)}/atbats/${Uri.encodeComponent(atBatId)}',
      body: body,
    );

    final data = await _handleResponse(response);
    return AtBat.fromJson(data as Map<String, dynamic>);
  }

  /// Delete an at-bat
  Future<void> deleteAtBat(String gameId, String atBatId) async {
    final response = await _authenticatedRequest(
      method: 'DELETE',
      path: '/games/${Uri.encodeComponent(gameId)}/atbats/${Uri.encodeComponent(atBatId)}',
    );

    await _handleResponse(response);
  }

  /// Get user's team context for dynamic UI rendering
  ///
  /// Returns: UserContext with has_personal_context and has_managed_context flags
  Future<UserContext> getUserContext() async {
    debugPrint('🌐 API: Calling GET /users/context');
    debugPrint('   Base URL: $baseUrl');
    
    try {
      final response = await _authenticatedRequest(
        method: 'GET',
        path: '/users/context',
      );

      debugPrint('✅ API: /users/context returned ${response.statusCode}');
      
      final data = await _handleResponse(response);
      final context = UserContext.fromJson(data as Map<String, dynamic>);
      
      debugPrint('📊 UserContext: has_personal=${context.hasPersonalContext}, has_managed=${context.hasManagedContext}');
      
      return context;
    } catch (e) {
      debugPrint('❌ API: /users/context failed: $e');
      rethrow;
    }
  }
}
