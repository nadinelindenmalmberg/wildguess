import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/animal_data.dart';

class HistoryService {
  static const String _historyKey = 'game_history';

  /// Save a completed game to history
  static Future<void> saveGameHistory({
    required AnimalData animal, // Pass the full AnimalData object
    required bool isCorrect,
    required int questionIndex,
    required int totalQuestions,
    required DateTime completedAt,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString(_historyKey) ?? '[]';
      final List<dynamic> history = json.decode(historyJson);

      final gameRecord = {
        'animal_name': animal.name,
        'animal_scientific_name': animal.scientificName,
        'animal_image_url': animal.imageUrl,
        'animal_description': animal.description, // *** ADD DESCRIPTION ***
        'animal_hints': animal.hints,           // *** ADD HINTS ***
        'is_correct': isCorrect,
        'question_index': questionIndex,
        'total_questions': totalQuestions,
        'completed_at': completedAt.toIso8601String(),
        'score': isCorrect ? (totalQuestions - questionIndex + 1) : 0,
      };

      // Add to beginning of list (most recent first)
      history.insert(0, gameRecord);

      // Keep only last 50 games to prevent storage bloat
      if (history.length > 50) {
        history.removeRange(50, history.length);
      }

      await prefs.setString(_historyKey, json.encode(history));
    } catch (e) {
      print('Error saving game history: $e');
    }
  }

  /// Get all game history
  static Future<List<Map<String, dynamic>>> getGameHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString(_historyKey) ?? '[]';
      final List<dynamic> history = json.decode(historyJson);

      return history.cast<Map<String, dynamic>>();
    } catch (e) {
      print('Error loading game history: $e');
      return [];
    }
  }

  /// Clear all game history
  static Future<void> clearHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_historyKey);
    } catch (e) {
      print('Error clearing game history: $e');
    }
  }

  /// Get statistics from history
  static Future<Map<String, dynamic>> getStatistics() async {
    try {
      final history = await getGameHistory();

      if (history.isEmpty) {
        return {
          'total_games': 0,
          'correct_games': 0,
          'accuracy': 0.0,
          'average_score': 0.0,
          'best_score': 0,
          'current_streak': 0,
        };
      }

      final totalGames = history.length;
      final correctGames = history.where((game) => game['is_correct'] == true).length;
      final accuracy = totalGames > 0 ? (correctGames / totalGames) * 100 : 0.0;

      final scores = history.map((game) => game['score'] as int? ?? 0).toList(); // Added null check
      final averageScore = scores.isNotEmpty ? scores.reduce((a, b) => a + b) / scores.length : 0.0;
      final bestScore = scores.isNotEmpty ? scores.reduce((a, b) => a > b ? a : b) : 0;

      // Calculate current streak (consecutive correct games from most recent)
      int currentStreak = 0;
      for (final game in history) {
        if (game['is_correct'] == true) {
          currentStreak++;
        } else {
          break; // Stop counting streak on the first incorrect game
        }
      }

      return {
        'total_games': totalGames,
        'correct_games': correctGames,
        'accuracy': accuracy,
        'average_score': averageScore,
        'best_score': bestScore,
        'current_streak': currentStreak,
      };
    } catch (e) {
      print('Error calculating statistics: $e');
      // Return default empty stats on error
      return {
        'total_games': 0,
        'correct_games': 0,
        'accuracy': 0.0,
        'average_score': 0.0,
        'best_score': 0,
        'current_streak': 0,
      };
    }
  }
}