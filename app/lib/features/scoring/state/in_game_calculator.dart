import '../../../models/atbat.dart';
import '../utils/scoring_rules.dart' as scoring_rules;
import 'game_state.dart';

/// Calculator for deriving in-game state from AtBats
/// 
/// This is a pure function that takes a list of AtBats and a lineup,
/// and calculates the current game state (inning, outs, current batter).
class InGameCalculator {
  /// Compute game state from list of AtBats and lineup
  /// 
  /// Algorithm:
  /// 1. Sort at-bats by createdAt (chronological order)
  /// 2. Start at inning 1, outs 0, batter index 0
  /// 3. For each at-bat:
  ///    - If result is an out, increment outs
  ///    - If outs reach 3, advance to next inning and reset outs to 0
  ///    - Advance to next batter in lineup
  /// 4. Return final state
  static InGameState compute({
    required List<AtBat> atBats,
    required List<dynamic> lineup,
  }) {
    // Sort lineup by batting order
    final sortedLineup = List<Map<String, dynamic>>.from(lineup)
      ..sort((a, b) => (a['battingOrder'] as int).compareTo(b['battingOrder'] as int));
    
    if (sortedLineup.isEmpty) {
      throw ArgumentError('Lineup cannot be empty');
    }
    
    // Sort at-bats chronologically
    final sortedAtBats = List<AtBat>.from(atBats)
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    
    // Start at initial state
    int inning = 1;
    int outs = 0;
    int batterIndex = 0;
    
    // Process each at-bat
    for (final atBat in sortedAtBats) {
      // Check if this result counts as an out
      if (scoring_rules.isOut(atBat.result)) {
        final outCount = scoring_rules.outCount(atBat.result);
        outs += outCount;
        
        // Handle multiple outs (double play, triple play)
        while (outs >= 3) {
          inning++;
          outs -= 3;
        }
      }
      
      // Advance to next batter (regardless of outcome)
      batterIndex = (batterIndex + 1) % sortedLineup.length;
    }
    
    // Get current batter from lineup
    final currentBatter = sortedLineup[batterIndex];
    final currentBatterPlayerId = currentBatter['playerId'] as String;
    
    return InGameState(
      inning: inning,
      outs: outs,
      currentBatterIndex: batterIndex,
      currentBatterPlayerId: currentBatterPlayerId,
    );
  }
}

