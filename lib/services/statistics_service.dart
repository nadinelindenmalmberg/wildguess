import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'history_service.dart';

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
          game['question_index'] == i).length;
      }
      
      final totalGames = recentGames.length;
      final currentHintCount = hintDistribution[hintIndex] ?? 0;
      final percentage = totalGames > 0 ? (currentHintCount / totalGames * 100).round() : 0;
      
      // If we don't have enough data, use some realistic defaults
      if (totalGames < 5) {
        final defaultDistribution = {1: 8, 2: 11, 3: 52, 4: 20, 5: 9};
        return {
          'percentage': defaultDistribution[hintIndex] ?? 0,
          'totalGames': totalGames,
          'hintDistribution': defaultDistribution,
          'isLocal': true,
          'isDefault': true,
        };
      }
      
      return {
        'percentage': percentage,
        'totalGames': totalGames,
        'hintDistribution': hintDistribution,
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
