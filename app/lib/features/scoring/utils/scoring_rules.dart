/// Scoring rules for baseball/softball game state calculation
/// 
/// This module provides utilities for determining game state from at-bat results.
/// Used to derive inning, outs, and batter position from the list of recorded AtBats.

/// Determines if an at-bat result counts as an out
/// 
/// Returns true if the result represents an out (or multiple outs).
/// Note: Some results like DP (double play) count as 2 outs, but this
/// function returns true for any out. The actual count should be handled
/// by the state calculator.
bool isOut(String result) {
  // Normalize to uppercase for comparison
  final normalized = result.toUpperCase().trim();
  
  // Single out results
  if ([
    'K',        // Strikeout
    'OUT',      // Generic out
    'FO',       // Flyout
    'GO',       // Ground out
    'PO',       // Pop out
    'LO',       // Line out
    'F7',       // Flyout to left field
    'F8',       // Flyout to center field
    'F9',       // Flyout to right field
    'L7',       // Line drive out to left
    'L8',       // Line drive out to center
    'L9',       // Line drive out to right
    'P3',       // Pop out to first
    'P4',       // Pop out to second
    'P5',       // Pop out to third
    'P6',       // Pop out to shortstop
    'G3',       // Ground out to first
    'G4',       // Ground out to second
    'G5',       // Ground out to third
    'G6',       // Ground out to shortstop
    'SF',       // Sacrifice fly (counts as out for batter)
    'SH',       // Sacrifice hit/bunt (counts as out for batter)
    'SAC',      // Sacrifice (alternative notation)
  ].contains(normalized)) {
    return true;
  }
  
  // Multiple out results (double play, triple play)
  if (normalized.startsWith('DP') || normalized == 'DOUBLE_PLAY') {
    return true; // Counts as 2 outs, handled by calculator
  }
  
  if (normalized.startsWith('TP') || normalized == 'TRIPLE_PLAY') {
    return true; // Counts as 3 outs, handled by calculator
  }
  
  // Not an out
  return false;
}

/// Returns the number of outs for a given result
/// 
/// Most results count as 1 out, but some count as multiple.
int outCount(String result) {
  final normalized = result.toUpperCase().trim();
  
  if (normalized.startsWith('TP') || normalized == 'TRIPLE_PLAY') {
    return 3;
  }
  
  if (normalized.startsWith('DP') || normalized == 'DOUBLE_PLAY') {
    return 2;
  }
  
  if (isOut(normalized)) {
    return 1;
  }
  
  return 0;
}

/// Determines if an at-bat result is a hit
bool isHit(String result) {
  final normalized = result.toUpperCase().trim();
  return ['1B', '2B', '3B', 'HR', 'SINGLE', 'DOUBLE', 'TRIPLE', 'HOMERUN', 'HOME_RUN'].contains(normalized);
}

/// Determines if an at-bat result is a walk/base on balls
bool isWalk(String result) {
  final normalized = result.toUpperCase().trim();
  return ['BB', 'BASE_ON_BALLS', 'WALK'].contains(normalized);
}

/// Determines if an at-bat result is a hit by pitch
bool isHitByPitch(String result) {
  final normalized = result.toUpperCase().trim();
  return ['HBP', 'HIT_BY_PITCH'].contains(normalized);
}

/// Determines if an at-bat advances the batter to first base
/// (hit, walk, HBP, error, fielder's choice that reaches base, etc.)
bool reachesBase(String result) {
  final normalized = result.toUpperCase().trim();
  
  if (isHit(normalized) || isWalk(normalized) || isHitByPitch(normalized)) {
    return true;
  }
  
  // Error or fielder's choice where batter reaches base
  if (['E', 'ERROR', 'FC', 'FIELDERS_CHOICE'].contains(normalized)) {
    return true; // Batter reaches base on error/FC
  }
  
  return false;
}

