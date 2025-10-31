import '../services/api_service.dart';

/// Groups games by date ranges: This Week, Next Week, Later
Map<String, List<Game>> groupGamesByDateRange(List<Game> games) {
  final now = DateTime.now();
  final thisWeekEnd = now.add(Duration(days: 7 - now.weekday));
  final nextWeekEnd = thisWeekEnd.add(const Duration(days: 7));
  
  final Map<String, List<Game>> grouped = {
    'This Week': [],
    'Next Week': [],
    'Later': [],
  };
  
  // Include scheduled and in-progress games
  final scheduledGames = games.where((g) => 
    g.status == 'SCHEDULED' || g.status == 'IN_PROGRESS'
  ).toList();
  
  for (final game in scheduledGames) {
    if (game.scheduledStart == null) {
      grouped['Later']!.add(game);
    } else if (game.scheduledStart!.isBefore(thisWeekEnd)) {
      grouped['This Week']!.add(game);
    } else if (game.scheduledStart!.isBefore(nextWeekEnd)) {
      grouped['Next Week']!.add(game);
    } else {
      grouped['Later']!.add(game);
    }
  }
  
  // Remove empty groups
  grouped.removeWhere((key, value) => value.isEmpty);
  return grouped;
}


