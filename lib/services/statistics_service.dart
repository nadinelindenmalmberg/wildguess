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
  
  /// Get global daily statistics from Supabase
  static Future<Map<String, dynamic>> _getGlobalDailyStatistics() async {
    try {
      await ensureAnonSession();
      final nowUtc = DateTime.now().toUtc();
      final dayKey = _dayKeyDaily(nowUtc);
      
      print('Fetching global statistics for dayKey: $dayKey');
      
      // Try to get global statistics for today
      // First try the new RPC function
      try {
        final res = await supa.rpc('get_daily_statistics', params: {
          'p_day_key': dayKey,
        });
        
        print('RPC response: $res');
        
        if (res is Map<String, dynamic> && res.isNotEmpty) {
          final hintDistribution = <int, int>{};
          final failedCount = res['failed_count'] as int? ?? 0;
          final totalGames = res['total_games'] as int? ?? 0;
          
          // Parse hint distribution from the response
          for (int i = 1; i <= 5; i++) {
            hintDistribution[i] = res['hint_$i'] as int? ?? 0;
          }
          
          // Calculate percentages
          final hintPercentages = <int, int>{};
          for (int i = 1; i <= 5; i++) {
            hintPercentages[i] = totalGames > 0 ? 
              ((hintDistribution[i] ?? 0) / totalGames * 100).round() : 0;
          }
          
          print('RPC stats - totalGames: $totalGames, hintPercentages: $hintPercentages');
          
          return {
            'hintDistribution': hintPercentages,
            'failedCount': failedCount,
            'totalGames': totalGames,
            'isLocal': false,
            'isDefault': false,
            'isGlobal': true,
          };
        }
      } catch (rpcError) {
        print('RPC function not available, trying alternative approach: $rpcError');
      }
      
      // Fallback: try to get data from the scores table directly
      print('Trying direct query to daily_scores table...');
      final scoresRes = await supa
          .from('daily_scores')
          .select('attempts, solved')
          .like('day_key', '$dayKey%');
      
      print('Direct query response: $scoresRes');
      
      if (scoresRes is List && scoresRes.isNotEmpty) {
        final scores = scoresRes.cast<Map<String, dynamic>>();
        final totalGames = scores.length;
        
        print('Found $totalGames scores in daily_scores table');
        
        // Calculate hint distribution
        final hintDistribution = <int, int>{};
        for (int i = 1; i <= 5; i++) {
          hintDistribution[i] = scores.where((score) => 
            score['attempts'] == i && score['solved'] == true).length;
        }
        
        final failedCount = scores.where((score) => score['solved'] == false).length;
        
        // Calculate percentages
        final hintPercentages = <int, int>{};
        for (int i = 1; i <= 5; i++) {
          hintPercentages[i] = totalGames > 0 ? 
            ((hintDistribution[i] ?? 0) / totalGames * 100).round() : 0;
        }
        
        print('Direct query stats - totalGames: $totalGames, hintPercentages: $hintPercentages');
        
        return {
          'hintDistribution': hintPercentages,
          'failedCount': failedCount,
          'totalGames': totalGames,
          'isLocal': false,
          'isDefault': false,
          'isGlobal': true,
        };
      }
      
      print('No data found in daily_scores table for dayKey: $dayKey');
      return {};
    } catch (e) {
      print('Error fetching global daily statistics: $e');
      return {};
    }
  }
  
  /// Get daily statistics for a specific hint index
  static Future<Map<String, dynamic>> getDailyStatistics(int hintIndex) async {
    try {
      // First try to get global statistics from Supabase
      final globalStats = await _getGlobalDailyStatistics();
      if (globalStats.isNotEmpty) {
        return globalStats;
      }
      
      // If no global data available, return default statistics
      final defaultDistribution = {1: 8, 2: 11, 3: 52, 4: 20, 5: 9};
      return {
        'percentage': defaultDistribution[hintIndex] ?? 0,
        'totalGames': 100, // Show some realistic total
        'hintDistribution': defaultDistribution,
        'failedCount': 15, // Show some failed attempts
        'isLocal': false,
        'isDefault': true,
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
        'isLocal': false,
        'isDefault': true,
      };
    }
  }
  
  /// Get hint distribution for bar chart
  static Future<List<Map<String, dynamic>>> getHintDistribution() async {
    try {
      // Try to get global statistics first
      final globalStats = await _getGlobalDailyStatistics();
      if (globalStats.isNotEmpty && globalStats.containsKey('hintDistribution')) {
        final hintDist = globalStats['hintDistribution'] as Map<int, int>;
        return [
          {'hint': 1, 'count': hintDist[1] ?? 0, 'percentage': hintDist[1] ?? 0},
          {'hint': 2, 'count': hintDist[2] ?? 0, 'percentage': hintDist[2] ?? 0},
          {'hint': 3, 'count': hintDist[3] ?? 0, 'percentage': hintDist[3] ?? 0},
          {'hint': 4, 'count': hintDist[4] ?? 0, 'percentage': hintDist[4] ?? 0},
          {'hint': 5, 'count': hintDist[5] ?? 0, 'percentage': hintDist[5] ?? 0},
        ];
      }
      
      // Return default distribution if no global data
      return [
        {'hint': 1, 'count': 8, 'percentage': 8},
        {'hint': 2, 'count': 11, 'percentage': 11},
        {'hint': 3, 'count': 52, 'percentage': 52},
        {'hint': 4, 'count': 20, 'percentage': 20},
        {'hint': 5, 'count': 9, 'percentage': 9},
      ];
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
  
  /// Get today's statistics from aggregate_stats table
  static Future<Map<String, dynamic>> getTodayStatistics() async {
    try {
      await ensureAnonSession();
      final userId = supa.auth.currentUser!.id;
      
      // Get user's aggregate stats
      final response = await supa
          .from('aggregate_stats')
          .select('*')
          .eq('user_id', userId)
          .single();
      
      if (response != null) {
        final gamesPlayed = response['games_played'] as int? ?? 0;
        final totalSolved = response['total_solved'] as int? ?? 0;
        final currentStreak = response['current_streak'] as int? ?? 0;
        final maxStreak = response['max_streak'] as int? ?? 0;
        final avgTimeMs = response['avg_time_ms'] as int? ?? 0;
        final bestTimeMs = response['best_time_ms'] as int? ?? 0;
        
        final accuracy = gamesPlayed > 0 ? (totalSolved / gamesPlayed * 100).round() : 0;
        
        return {
          'gamesPlayed': gamesPlayed,
          'gamesCorrect': totalSolved,
          'accuracy': accuracy,
          'streak': currentStreak,
          'maxStreak': maxStreak,
          'avgTimeMs': avgTimeMs,
          'bestTimeMs': bestTimeMs,
        };
      }
      
      return {
        'gamesPlayed': 0,
        'gamesCorrect': 0,
        'accuracy': 0,
        'streak': 0,
        'maxStreak': 0,
        'avgTimeMs': 0,
        'bestTimeMs': 0,
      };
    } catch (e) {
      print('Error getting today statistics from aggregate_stats: $e');
      return {
        'gamesPlayed': 0,
        'gamesCorrect': 0,
        'accuracy': 0,
        'streak': 0,
        'maxStreak': 0,
        'avgTimeMs': 0,
        'bestTimeMs': 0,
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
