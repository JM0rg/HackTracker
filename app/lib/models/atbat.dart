/// AtBat model
class AtBat {
  final String atBatId;
  final String gameId;
  final String teamId;
  final String playerId;
  final String result; // K, BB, HBP, 1B, 2B, 3B, HR, OUT, SAC, FC, E
  final int inning;
  final int outs; // 0, 1, or 2
  final int? battingOrder; // Position in lineup
  final Map<String, double>? hitLocation; // {x: 0.0-1.0, y: 0.0-1.0}
  final String? hitType; // fly_ball, ground_out, line_drive, pop_up, bunt
  final int? rbis;
  final DateTime createdAt;
  final DateTime updatedAt;

  AtBat({
    required this.atBatId,
    required this.gameId,
    required this.teamId,
    required this.playerId,
    required this.result,
    required this.inning,
    required this.outs,
    this.battingOrder,
    this.hitLocation,
    this.hitType,
    this.rbis,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AtBat.fromJson(Map<String, dynamic> json) {
    return AtBat(
      atBatId: json['atBatId'] as String,
      gameId: json['gameId'] as String,
      teamId: json['teamId'] as String,
      playerId: json['playerId'] as String,
      result: json['result'] as String,
      inning: (json['inning'] as num).toInt(),
      outs: (json['outs'] as num).toInt(),
      battingOrder: (json['battingOrder'] as num?)?.toInt(),
      hitLocation: json['hitLocation'] != null
          ? {
              'x': (json['hitLocation']['x'] as num).toDouble(),
              'y': (json['hitLocation']['y'] as num).toDouble(),
            }
          : null,
      hitType: json['hitType'] as String?,
      rbis: (json['rbis'] as num?)?.toInt(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'atBatId': atBatId,
      'gameId': gameId,
      'teamId': teamId,
      'playerId': playerId,
      'result': result,
      'inning': inning,
      'outs': outs,
      'battingOrder': battingOrder,
      'hitLocation': hitLocation,
      'hitType': hitType,
      'rbis': rbis,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Helper getters
  bool get isHit => ['1B', '2B', '3B', 'HR'].contains(result);
  bool get isOut => ['K', 'OUT'].contains(result);
  bool get isWalk => result == 'BB';
  bool get isStrikeout => result == 'K';
  bool get isHomeRun => result == 'HR';
}

