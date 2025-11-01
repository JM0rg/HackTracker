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

