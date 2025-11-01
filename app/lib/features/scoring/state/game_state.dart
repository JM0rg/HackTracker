/// In-game state model
/// 
/// Represents the current state of a game in progress, derived from
/// the list of recorded AtBats. This is the single source of truth
/// for what inning, how many outs, and who's up to bat.
class InGameState {
  /// Current inning (1-based)
  final int inning;
  
  /// Current number of outs (0, 1, or 2)
  final int outs;
  
  /// Current batter index in the lineup (0-based)
  final int currentBatterIndex;
  
  /// Player ID of the current batter
  final String currentBatterPlayerId;
  
  const InGameState({
    required this.inning,
    required this.outs,
    required this.currentBatterIndex,
    required this.currentBatterPlayerId,
  });
  
  /// Default state for a new game
  factory InGameState.initial(String firstBatterPlayerId) {
    return InGameState(
      inning: 1,
      outs: 0,
      currentBatterIndex: 0,
      currentBatterPlayerId: firstBatterPlayerId,
    );
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is InGameState &&
        other.inning == inning &&
        other.outs == outs &&
        other.currentBatterIndex == currentBatterIndex &&
        other.currentBatterPlayerId == currentBatterPlayerId;
  }
  
  @override
  int get hashCode {
    return Object.hash(inning, outs, currentBatterIndex, currentBatterPlayerId);
  }
  
  @override
  String toString() {
    return 'InGameState(inning: $inning, outs: $outs, batterIndex: $currentBatterIndex, playerId: $currentBatterPlayerId)';
  }
}

