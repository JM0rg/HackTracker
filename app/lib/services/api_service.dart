import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

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
        throw ApiException(
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
      if (e is ApiException) rethrow;
      
      // If it's an auth error, sign out and throw proper exception
      await AuthService.signOut();
      throw ApiException(
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

      // Handle authentication errors specially
      if (response.statusCode == 401) {
        // Sign out user on authentication failure
        AuthService.signOut();
        throw ApiException(
          statusCode: response.statusCode,
          message: 'Session expired. Please sign in again.',
          errorType: 'Unauthorized',
        );
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
  /// Returns: List of teams with role and member count (personal teams filtered by backend)
  Future<List<Team>> listTeams() async {
    // Get current user's ID from Cognito
    final user = await Amplify.Auth.getCurrentUser();
    final userId = user.userId;
    
    final response = await _authenticatedRequest(
      method: 'GET',
      path: '/teams?userId=$userId',
    );

    final data = _handleResponse(response);
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

    final data = _handleResponse(response);
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

    final data = _handleResponse(response);
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

    final data = _handleResponse(response);
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

    final data = _handleResponse(response);
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

    final data = _handleResponse(response);
    return Player.fromJson(data as Map<String, dynamic>);
  }

  /// Remove a player (ghost players only)
  Future<void> removePlayer(String teamId, String playerId) async {
    final response = await _authenticatedRequest(
      method: 'DELETE',
      path: '/teams/${Uri.encodeComponent(teamId)}/players/${Uri.encodeComponent(playerId)}',
    );

    _handleResponse(response);
  }

  // ========== GAMES ENDPOINTS ==========

  /// List games for a team
  Future<List<Game>> listGames(String teamId) async {
    final response = await _authenticatedRequest(
      method: 'GET',
      path: '/teams/${Uri.encodeComponent(teamId)}/games',
    );

    final data = _handleResponse(response);
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

    final data = _handleResponse(response);
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

    final data = _handleResponse(response);
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

    final data = _handleResponse(response);
    return Game.fromJson(data as Map<String, dynamic>);
  }

  /// Delete a game
  Future<void> deleteGame(String gameId) async {
    final response = await _authenticatedRequest(
      method: 'DELETE',
      path: '/games/${Uri.encodeComponent(gameId)}',
    );

    _handleResponse(response);
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
      
      final data = _handleResponse(response);
      final context = UserContext.fromJson(data as Map<String, dynamic>);
      
      debugPrint('📊 UserContext: has_personal=${context.hasPersonalContext}, has_managed=${context.hasManagedContext}');
      
      return context;
    } catch (e) {
      debugPrint('❌ API: /users/context failed: $e');
      rethrow;
    }
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
  final bool isPersonal;

  Team({
    required this.teamId,
    required this.name,
    required this.description,
    required this.role,
    required this.memberCount,
    required this.joinedAt,
    required this.createdAt,
    this.isPersonal = false,
  });

  factory Team.fromJson(Map<String, dynamic> json) {
    return Team(
      teamId: json['teamId'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      role: json['role'] as String? ?? 'player', // Can be null for listTeams()
      memberCount: json['memberCount'] as int? ?? 1,
      joinedAt: json['joinedAt'] != null 
          ? DateTime.parse(json['joinedAt'] as String)
          : DateTime.now(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      isPersonal: json['isPersonal'] as bool? ?? false,
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
      'isPersonal': isPersonal,
    };
  }

  bool get isOwner => role == 'owner';
  bool get isManager => role == 'manager';
  bool get isPlayer => role == 'player';
  bool get isMember => role == 'player'; // Keep for backwards compatibility
  bool get canManageRoster => isOwner || isManager;
  
  String get displayRole {
    switch (role) {
      case 'owner':
        return 'Owner';
      case 'manager':
        return 'Manager';
      case 'player':
        return 'Player';
      default:
        return 'Player';
    }
  }
}

/// Player model
class Player {
  final String playerId;
  final String teamId;
  final String firstName;
  final String? lastName;
  final int? playerNumber;
  final String status;
  final List<String>? positions;
  final bool isGhost;
  final String? userId;
  final String? linkedAt;
  final String? role; // owner, manager, player
  final String createdAt;
  final String updatedAt;

  Player({
    required this.playerId,
    required this.teamId,
    required this.firstName,
    required this.lastName,
    required this.playerNumber,
    required this.status,
    this.positions,
    required this.isGhost,
    required this.userId,
    required this.linkedAt,
    this.role,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      playerId: json['playerId'] as String,
      teamId: json['teamId'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String?,
      playerNumber: json['playerNumber'] == null ? null : (json['playerNumber'] as num).toInt(),
      status: json['status'] as String,
      positions: json['positions'] == null ? null : List<String>.from(json['positions'] as List),
      isGhost: (json['isGhost'] as bool?) ?? false,
      userId: json['userId'] as String?,
      linkedAt: json['linkedAt'] as String?,
      role: json['role'] as String?,
      createdAt: json['createdAt'] as String,
      updatedAt: json['updatedAt'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'playerId': playerId,
      'teamId': teamId,
      'firstName': firstName,
      'lastName': lastName,
      'playerNumber': playerNumber,
      'status': status,
      'positions': positions,
      'isGhost': isGhost,
      'userId': userId,
      'linkedAt': linkedAt,
      'role': role,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  String get fullName => (lastName != null && lastName!.isNotEmpty) ? '$firstName $lastName' : firstName;
  String get displayNumber => playerNumber?.toString() ?? '--';
  bool get isActive => status == 'active';
  String get displayRole {
    if (role == null) return 'Player';
    switch (role) {
      case 'owner':
        return 'Owner';
      case 'manager':
        return 'Manager';
      case 'player':
        return 'Player';
      default:
        return 'Player';
    }
  }
}

/// Game model
class Game {
  final String gameId;
  final String teamId;
  final String status; // SCHEDULED, IN_PROGRESS, FINAL, POSTPONED
  final int teamScore;
  final int opponentScore;
  final List<dynamic>? lineup;
  final DateTime? scheduledStart;
  final String? opponentName;
  final String? location;
  final String? seasonId;
  final DateTime createdAt;
  final DateTime updatedAt;

  Game({
    required this.gameId,
    required this.teamId,
    required this.status,
    required this.teamScore,
    required this.opponentScore,
    this.lineup,
    this.scheduledStart,
    this.opponentName,
    this.location,
    this.seasonId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Game.fromJson(Map<String, dynamic> json) {
    return Game(
      gameId: json['gameId'] as String,
      teamId: json['teamId'] as String,
      status: json['status'] as String,
      teamScore: (json['teamScore'] as num?)?.toInt() ?? 0,
      opponentScore: (json['opponentScore'] as num?)?.toInt() ?? 0,
      lineup: json['lineup'] as List<dynamic>?,
      scheduledStart: json['scheduledStart'] != null
          ? DateTime.parse(json['scheduledStart'] as String)
          : null,
      opponentName: json['opponentName'] as String?,
      location: json['location'] as String?,
      seasonId: json['seasonId'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'gameId': gameId,
      'teamId': teamId,
      'status': status,
      'teamScore': teamScore,
      'opponentScore': opponentScore,
      'lineup': lineup,
      'scheduledStart': scheduledStart?.toIso8601String(),
      'opponentName': opponentName,
      'location': location,
      'seasonId': seasonId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  bool get isScheduled => status == 'SCHEDULED';
  bool get isInProgress => status == 'IN_PROGRESS';
  bool get isFinal => status == 'FINAL';
  bool get isPostponed => status == 'POSTPONED';
  bool get isCompleted => status == 'FINAL';
  bool get isUpcoming => status == 'SCHEDULED' && (scheduledStart == null || scheduledStart!.isAfter(DateTime.now()));
}

/// User Context model for dynamic UI rendering
class UserContext {
  final bool hasPersonalContext;
  final bool hasManagedContext;

  UserContext({
    required this.hasPersonalContext,
    required this.hasManagedContext,
  });

  factory UserContext.fromJson(Map<String, dynamic> json) {
    return UserContext(
      hasPersonalContext: json['has_personal_context'] as bool,
      hasManagedContext: json['has_managed_context'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'has_personal_context': hasPersonalContext,
      'has_managed_context': hasManagedContext,
    };
  }

  /// Determine which view to show based on team context
  /// - Both contexts: Show both views (tabs visible)
  /// - Personal only: Show player view only (tabs hidden)
  /// - Managed only: Show team view only (tabs hidden)
  /// - Neither: Show welcome screen
  bool get shouldShowTabs => hasPersonalContext && hasManagedContext;
  bool get shouldShowPlayerViewOnly => hasPersonalContext && !hasManagedContext;
  bool get shouldShowTeamViewOnly => !hasPersonalContext && hasManagedContext;
  bool get shouldShowWelcome => !hasPersonalContext && !hasManagedContext;
}

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

