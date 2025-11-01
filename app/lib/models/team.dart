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

