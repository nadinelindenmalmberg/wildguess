import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'history_service.dart';

final supa = Supabase.instance.client;

/// Toggle this during development
bool testingMode = false; // uses YYYY-MM-DD only

String _dayKeyDaily(DateTime utcNow) =>
    utcNow.toIso8601String().substring(0, 10); // YYYY-MM-DD

String _dayKeyTesting(DateTime utcNow, String animal) =>
    '${_dayKeyDaily(utcNow)}:$animal';

String _dayKeyWithAnimal(DateTime utcNow, String animal) =>
    '${_dayKeyDaily(utcNow)}:$animal';

Future<void> ensureAnonSession() async {
  if (supa.auth.currentSession == null) {
    await supa.auth.signInAnonymously();
  }
  await supa.rpc('ensure_player');
}

/// Calculate score based on attempts and time using the new formula
/// Formula: base = 100, attemptPenalty = 15 * (attempts - 1), timePenalty = min(time_ms / 1000 / 2, 40)
/// score = clamp(base - attemptPenalty - timePenalty, 0, 100)
int calculateScore({
  required int attempts,
  required int timeMs,
  required bool solved,
}) {
  if (!solved) return 0;
  
  const int base = 100;
  final int attemptPenalty = 15 * (attempts - 1);
  final double timePenalty = (timeMs / 1000.0 / 2.0).clamp(0, 40);
  
  final int score = (base - attemptPenalty - timePenalty).round().clamp(0, 100);
  return score;
}

Future<void> setNickname(String nickname) async {
  await ensureAnonSession();
  final userId = supa.auth.currentUser!.id;
  await supa.from('players').upsert({'user_id': userId, 'nickname': nickname});
}

Future<void> submitScore({
  required int attempts,
  required bool solved,
  required int timeMs,
  String? animalForTesting,
  String? animalName,
}) async {
  await ensureAnonSession();
  final nowUtc = DateTime.now().toUtc();
  final key = testingMode
      ? _dayKeyTesting(nowUtc, animalForTesting ?? 'test')
      : _dayKeyWithAnimal(nowUtc, animalName ?? 'unknown');

  // Calculate score using the new formula
  final int score = calculateScore(
    attempts: attempts,
    timeMs: timeMs,
    solved: solved,
  );

  await supa.rpc('submit_score', params: {
    'p_day_key': key,
    'p_score': score,
    'p_attempts': attempts,
    'p_solved': solved,
    'p_time_ms': timeMs,
  });
}

Future<List<Map<String, dynamic>>> getTopToday({
  int limit = 100,
  String? animalForTesting,
  String? animalName,
}) async {
  final nowUtc = DateTime.now().toUtc();
  final key = testingMode
      ? _dayKeyTesting(nowUtc, animalForTesting ?? 'test')
      : _dayKeyWithAnimal(nowUtc, animalName ?? 'unknown');

  final res = await supa.rpc('get_leaderboard', params: {
    'p_day_key': key,
    'p_limit': limit,
  });
  return (res as List).cast<Map<String, dynamic>>();
}

Future<Map<String, dynamic>> getMyRank({String? animalForTesting}) async {
  final nowUtc = DateTime.now().toUtc();
  final key = testingMode
      ? _dayKeyTesting(nowUtc, animalForTesting ?? 'test')
      : _dayKeyDaily(nowUtc);

  final res = await supa.rpc('get_my_rank', params: {'p_day_key': key});
  if (res is List && res.isNotEmpty) {
    return (res.first as Map<String, dynamic>);
  }
  return {'rank': null, 'score': null, 'total_players': 0};
}

class StatisticsService {
  static const String _dailyStatsKey = 'daily_statistics';
  
  /// Get daily statistics for a specific hint index
  static Future<Map<String, dynamic>> getDailyStatistics(int hintIndex) async {
    try {
      final history = await HistoryService.getGameHistory();
      
      // Get last 30 days of games for better sample size
      final thirtyDaysAgo = DateTime.now().subtract(Duration(days: 30));
      final recentGames = history.where((game) {
        final gameDate = DateTime.parse(game['completed_at']);
        return gameDate.isAfter(thirtyDaysAgo);
      }).toList();
      
      // Calculate hint distribution
      final hintDistribution = <int, int>{};
      for (int i = 1; i <= 5; i++) {
        hintDistribution[i] = recentGames.where((game) => 
          game['question_index'] == i && game['is_correct'] == true).length;
      }
      
      // Count failed attempts (is_correct = false)
      final failedCount = recentGames.where((game) => 
        game['is_correct'] == false).length;
      
      final totalGames = recentGames.length;
      
      // Calculate percentage based on success/failure (same logic as global stats)
      // This will be overridden in the UI based on isCorrect, but we need it for fallback
      final currentHintCount = hintDistribution[hintIndex] ?? 0;
      final percentage = totalGames > 0 ? (currentHintCount / totalGames * 100).round() : 0;
      
      // If we don't have enough data, use some realistic defaults
      if (totalGames < 5) {
        final defaultDistribution = {1: 8, 2: 11, 3: 52, 4: 20, 5: 9};
        return {
          'percentage': defaultDistribution[hintIndex] ?? 0,
          'totalGames': totalGames,
          'hintDistribution': defaultDistribution,
          'failedCount': failedCount,
          'isLocal': true,
          'isDefault': true,
        };
      }
      
      return {
        'percentage': percentage,
        'totalGames': totalGames,
        'hintDistribution': hintDistribution,
        'failedCount': failedCount,
        'isLocal': true,
        'isDefault': false,
      };
    } catch (e) {
      print('Error calculating daily statistics: $e');
      // Return default statistics if error
      final defaultDistribution = {1: 8, 2: 11, 3: 52, 4: 20, 5: 9};
      return {
        'percentage': defaultDistribution[hintIndex] ?? 0,
        'totalGames': 0,
        'hintDistribution': defaultDistribution,
        'failedCount': 0,
        'isLocal': true,
        'isDefault': true,
      };
    }
  }
  
  /// Get hint distribution for bar chart
  static Future<List<Map<String, dynamic>>> getHintDistribution() async {
    try {
      final history = await HistoryService.getGameHistory();
      
      // Get last 30 days of games
      final thirtyDaysAgo = DateTime.now().subtract(Duration(days: 30));
      final recentGames = history.where((game) {
        final gameDate = DateTime.parse(game['completed_at']);
        return gameDate.isAfter(thirtyDaysAgo);
      }).toList();
      
      final totalGames = recentGames.length;
      final distribution = <Map<String, dynamic>>[];
      
      for (int i = 1; i <= 5; i++) {
        final count = recentGames.where((game) => 
          game['question_index'] == i).length;
        final percentage = totalGames > 0 ? (count / totalGames * 100).round() : 0;
        
        distribution.add({
          'hint': i,
          'count': count,
          'percentage': percentage,
        });
      }
      
      // If not enough data, return default distribution
      if (totalGames < 5) {
        return [
          {'hint': 1, 'count': 8, 'percentage': 8},
          {'hint': 2, 'count': 11, 'percentage': 11},
          {'hint': 3, 'count': 52, 'percentage': 52},
          {'hint': 4, 'count': 20, 'percentage': 20},
          {'hint': 5, 'count': 9, 'percentage': 9},
        ];
      }
      
      return distribution;
    } catch (e) {
      print('Error getting hint distribution: $e');
      // Return default distribution
      return [
        {'hint': 1, 'count': 8, 'percentage': 8},
        {'hint': 2, 'count': 11, 'percentage': 11},
        {'hint': 3, 'count': 52, 'percentage': 52},
        {'hint': 4, 'count': 20, 'percentage': 20},
        {'hint': 5, 'count': 9, 'percentage': 9},
      ];
    }
  }
  
  /// Get today's statistics
  static Future<Map<String, dynamic>> getTodayStatistics() async {
    try {
      final history = await HistoryService.getGameHistory();
      final today = DateTime.now();
      
      final todayGames = history.where((game) {
        final gameDate = DateTime.parse(game['completed_at']);
        return gameDate.year == today.year && 
               gameDate.month == today.month && 
               gameDate.day == today.day;
      }).toList();
      
      final correctToday = todayGames.where((game) => game['is_correct'] == true).length;
      final totalToday = todayGames.length;
      final accuracy = totalToday > 0 ? (correctToday / totalToday * 100).round() : 0;
      
      return {
        'gamesPlayed': totalToday,
        'gamesCorrect': correctToday,
        'accuracy': accuracy,
        'streak': await _calculateCurrentStreak(),
      };
    } catch (e) {
      print('Error getting today statistics: $e');
      return {
        'gamesPlayed': 0,
        'gamesCorrect': 0,
        'accuracy': 0,
        'streak': 0,
      };
    }
  }
  
  /// Calculate current streak
  static Future<int> _calculateCurrentStreak() async {
    try {
      final history = await HistoryService.getGameHistory();
      int streak = 0;
      
      for (final game in history) {
        if (game['is_correct'] == true) {
          streak++;
        } else {
          break;
        }
      }
      
      return streak;
    } catch (e) {
      return 0;
    }
  }
}
