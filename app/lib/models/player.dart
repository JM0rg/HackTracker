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

