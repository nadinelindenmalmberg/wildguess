import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/animal_data.dart';

final supa = Supabase.instance.client;

class HistoryService {
  static const String _historyKey = 'game_history';
  
  /// Ensure user is authenticated
  static Future<void> _ensureAuth() async {
    if (supa.auth.currentSession == null) {
      await supa.auth.signInAnonymously();
    }
  }
  
  /// Save a completed game to history (both database and local fallback)
  static Future<void> saveGameHistory({
    required AnimalData animal,
    required bool isCorrect,
    required int questionIndex,
    required int totalQuestions,
    required DateTime completedAt,
  }) async {
    try {
      // First try to save to database
      await _saveToDatabase(
        animal: animal,
        isCorrect: isCorrect,
        questionIndex: questionIndex,
        totalQuestions: totalQuestions,
        completedAt: completedAt,
      );
    } catch (e) {
      print('Error saving to database, falling back to local storage: $e');
      // Fallback to local storage
      await _saveToLocal(
        animal: animal,
        isCorrect: isCorrect,
        questionIndex: questionIndex,
        totalQuestions: totalQuestions,
        completedAt: completedAt,
      );
    }
  }
  
  /// Save game history to Supabase database
  static Future<void> _saveToDatabase({
    required AnimalData animal,
    required bool isCorrect,
    required int questionIndex,
    required int totalQuestions,
    required DateTime completedAt,
  }) async {
    await _ensureAuth();
    
    // Check if we already have an entry for today's game for this animal
    final completedDay = DateTime(completedAt.year, completedAt.month, completedAt.day);
    final dayStart = DateTime(completedDay.year, completedDay.month, completedDay.day);
    final dayEnd = dayStart.add(const Duration(days: 1));
    
    final existingEntries = await supa
        .from('game_history')
        .select('id')
        .eq('user_id', supa.auth.currentUser!.id)
        .eq('animal_scientific_name', animal.scientificName)
        .gte('completed_at', dayStart.toIso8601String())
        .lt('completed_at', dayEnd.toIso8601String());
    
    // If entry exists, update it; otherwise insert new
    final gameRecord = {
      'user_id': supa.auth.currentUser!.id,
      'animal_name': animal.name,
      'animal_scientific_name': animal.scientificName,
      'animal_image_url': animal.imageUrl,
      'animal_description': animal.description,
      'animal_hints': animal.hints,
      'is_correct': isCorrect,
      'question_index': questionIndex,
      'total_questions': totalQuestions,
      'completed_at': completedAt.toIso8601String(),
      'score': isCorrect ? (totalQuestions - questionIndex + 1) : 0,
    };
    
    if (existingEntries is List && existingEntries.isNotEmpty) {
      // Update existing entry
      await supa
          .from('game_history')
          .update(gameRecord)
          .eq('user_id', supa.auth.currentUser!.id)
          .eq('animal_scientific_name', animal.scientificName)
          .gte('completed_at', dayStart.toIso8601String())
          .lt('completed_at', dayEnd.toIso8601String());
    } else {
      // Insert new entry
      await supa.from('game_history').insert(gameRecord);
    }
  }
  
  /// Save game history to local storage (fallback)
  static Future<void> _saveToLocal({
    required AnimalData animal,
    required bool isCorrect,
    required int questionIndex,
    required int totalQuestions,
    required DateTime completedAt,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getString(_historyKey) ?? '[]';
    final List<dynamic> history = json.decode(historyJson);
    
    // Ensure only a single entry exists for today's game for the same animal
    final completedDay = DateTime(completedAt.year, completedAt.month, completedAt.day);
    history.removeWhere((item) {
      final String? ts = item['completed_at'] as String?;
      final String? sci = item['animal_scientific_name'] as String?;
      final DateTime? parsed = ts != null ? DateTime.tryParse(ts) : null;
      if (parsed == null) return false;
      final itemDay = DateTime(parsed.year, parsed.month, parsed.day);
      return itemDay == completedDay && sci == animal.scientificName;
    });
    
    final gameRecord = {
      'animal_name': animal.name,
      'animal_scientific_name': animal.scientificName,
      'animal_image_url': animal.imageUrl,
      'animal_description': animal.description,
      'animal_hints': animal.hints, 
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
  }
  
  /// Get all game history (from database with local fallback)
  static Future<List<Map<String, dynamic>>> getGameHistory() async {
    try {
      // First try to get from database
      final dbHistory = await _getFromDatabase();
      if (dbHistory.isNotEmpty) {
        return dbHistory;
      }
      
      // Fallback to local storage
      return await _getFromLocal();
    } catch (e) {
      print('Error loading game history: $e');
      // Try local storage as final fallback
      try {
        return await _getFromLocal();
      } catch (localError) {
        print('Error loading from local storage: $localError');
        return [];
      }
    }
  }
  
  /// Get game history from Supabase database
  static Future<List<Map<String, dynamic>>> _getFromDatabase() async {
    await _ensureAuth();
    
    final response = await supa
        .from('game_history')
        .select('*')
        .eq('user_id', supa.auth.currentUser!.id)
        .order('completed_at', ascending: false)
        .limit(50);
    
    if (response is List) {
      return response.cast<Map<String, dynamic>>();
    }
    
    return [];
  }
  
  /// Get game history from local storage
  static Future<List<Map<String, dynamic>>> _getFromLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getString(_historyKey) ?? '[]';
    final List<dynamic> history = json.decode(historyJson);
    
    return history.cast<Map<String, dynamic>>();
  }
  
  /// Clear all game history (both database and local)
  static Future<void> clearHistory() async {
    try {
      // Clear from database
      await _clearFromDatabase();
    } catch (e) {
      print('Error clearing from database: $e');
    }
    
    try {
      // Clear from local storage
      await _clearFromLocal();
    } catch (e) {
      print('Error clearing from local storage: $e');
    }
  }
  
  /// Clear game history from Supabase database
  static Future<void> _clearFromDatabase() async {
    await _ensureAuth();
    
    await supa
        .from('game_history')
        .delete()
        .eq('user_id', supa.auth.currentUser!.id);
  }
  
  /// Clear game history from local storage
  static Future<void> _clearFromLocal() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
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
      
      final scores = history.map((game) => game['score'] as int? ?? 0).toList();  // *** ADD SCORE ***  
      final averageScore = scores.isNotEmpty ? scores.reduce((a, b) => a + b) / scores.length : 0.0;
      final bestScore = scores.isNotEmpty ? scores.reduce((a, b) => a > b ? a : b) : 0;
      
      // Calculate current streak (consecutive correct games from most recent)
      int currentStreak = 0;
      for (final game in history) {
        if (game['is_correct'] == true) {
          currentStreak++;
        } else {
          break;
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
