import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/animal_data.dart';
import 'image_service.dart';

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
  
  /// Save game history to Supabase database (using daily_scores table)
  static Future<void> _saveToDatabase({
    required AnimalData animal,
    required bool isCorrect,
    required int questionIndex,
    required int totalQuestions,
    required DateTime completedAt,
  }) async {
    await _ensureAuth();
    
    // Create day_key in the format used by daily_scores
    final completedDay = DateTime(completedAt.year, completedAt.month, completedAt.day);
    final dayKey = '${completedDay.year}-${completedDay.month.toString().padLeft(2, '0')}-${completedDay.day.toString().padLeft(2, '0')}:${animal.scientificName}';
    
    final scoreRecord = {
      'user_id': supa.auth.currentUser!.id,
      'day_key': dayKey,
      'animal_scientific_name': animal.scientificName,
      'attempts': questionIndex,
      'solved': isCorrect,
      'score': isCorrect ? (totalQuestions - questionIndex + 1) : 0,
    };
    
    // Use upsert to handle duplicates
    await supa.from('daily_scores').upsert(scoreRecord);
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
      print('DEBUG HISTORY: Database returned ${dbHistory.length} records');
      if (dbHistory.isNotEmpty) {
        return dbHistory;
      }
      
      print('DEBUG HISTORY: Database empty, falling back to local storage');
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
  
  /// Get game history from Supabase database (using daily_scores table)
  static Future<List<Map<String, dynamic>>> _getFromDatabase() async {
    await _ensureAuth();
    
    final response = await supa
        .from('daily_scores')
        .select('*')
        .eq('user_id', supa.auth.currentUser!.id)
        .order('created_at', ascending: false)
        .limit(50);
    
    if (response is List) {
      // Convert daily_scores format to game_history format
      final convertedScores = <Map<String, dynamic>>[];
      for (final score in response) {
        final convertedScore = await _convertDailyScoreToGameHistory(score);
        convertedScores.add(convertedScore);
      }
      return convertedScores;
    }
    
    return [];
  }
  
  /// Convert daily_scores record to game_history format
  static Future<Map<String, dynamic>> _convertDailyScoreToGameHistory(Map<String, dynamic> score) async {
    // Extract animal name from day_key (format: "2025-10-28:Delphinapterus leucas")
    final dayKey = score['day_key'] as String? ?? '';
    final animalScientificName = dayKey.contains(':') ? dayKey.split(':')[1] : 'Unknown';
    
    // Get animal data from the scientific name
    final animalData = _getAnimalDataFromScientific(animalScientificName);
    
    // Fetch real image using ImageService
    String imageUrl = animalData['image_url'];
    try {
      final fetchedImageUrl = await ImageService.getAnimalImageUrl(animalScientificName, swedishName: animalData['name']);
      if (fetchedImageUrl.isNotEmpty) {
        imageUrl = fetchedImageUrl;
      }
    } catch (e) {
      print('Error fetching image for $animalScientificName: $e');
      // Keep the fallback image URL
    }
    
    return {
      'id': score['id'],
      'animal_name': animalData['name'],
      'animal_scientific_name': animalScientificName,
      'animal_image_url': imageUrl,
      'animal_description': animalData['description'],
      'animal_hints': animalData['hints'],
      'is_correct': score['solved'] as bool? ?? false,
      'question_index': score['attempts'] as int? ?? 0,
      'total_questions': 5, // Default to 5 hints
      'completed_at': score['created_at'] as String? ?? DateTime.now().toIso8601String(),
      'score': score['score'] as int? ?? 0,
    };
  }
  
  /// Get animal data from scientific name
  static Map<String, dynamic> _getAnimalDataFromScientific(String scientificName) {
    // Basic mapping for common animals (fallback data, real images will be fetched by ImageService)
    final animalDataMap = {
      'Delphinapterus leucas': {
        'name': 'Vitval',
        'image_url': '', // Will be filled by ImageService
        'description': 'En vit val som lever i arktiska vatten.',
        'hints': ['Detta är en val', 'Den är vit', 'Den lever i kalla vatten', 'Den har ingen ryggfena', 'Den är känd för sin "melon"'],
      },
      'Vulpes vulpes': {
        'name': 'Röd räv',
        'image_url': '', // Will be filled by ImageService
        'description': 'En rävdjur som lever i skogar och öppna landskap.',
        'hints': ['Detta djur är ett rovdjur', 'Det har rödbrun päls', 'Det är känd för sin listighet', 'Det lever i skogar', 'Det har en buskig svans'],
      },
      'Alces alces': {
        'name': 'Älg',
        'image_url': '', // Will be filled by ImageService
        'description': 'Ett stort hjortdjur med stora horn.',
        'hints': ['Detta är Sveriges största landdäggdjur', 'Det har stora horn', 'Det lever i skogar', 'Det är ett hjortdjur', 'Det kan väga över 500 kg'],
      },
      'Ursus arctos': {
        'name': 'Brunbjörn',
        'image_url': '', // Will be filled by ImageService
        'description': 'Ett stort rovdjur som lever i skogar.',
        'hints': ['Detta är ett stort rovdjur', 'Det har brun päls', 'Det kan stå på bakbenen', 'Det lever i skogar', 'Det är Sveriges största rovdjur'],
      },
      'Canis lupus': {
        'name': 'Varg',
        'image_url': '', // Will be filled by ImageService
        'description': 'Ett rovdjur som lever i flockar.',
        'hints': ['Detta är ett rovdjur', 'Det lever i flockar', 'Det har grå päls', 'Det är känd för att yla', 'Det är ett hunddjur'],
      },
      'Lynx lynx': {
        'name': 'Lodjur',
        'image_url': '', // Will be filled by ImageService
        'description': 'Ett kattdjur med tofsar på öronen.',
        'hints': ['Detta är ett kattdjur', 'Det har tofsar på öronen', 'Det lever i skogar', 'Det har prickig päls', 'Det är ett rovdjur'],
      },
      'Capreolus capreolus': {
        'name': 'Rådjur',
        'image_url': '', // Will be filled by ImageService
        'description': 'Ett litet hjortdjur som lever i skogar.',
        'hints': ['Detta är ett hjortdjur', 'Det är relativt litet', 'Det lever i skogar', 'Det har små horn', 'Det är vanligt i Sverige'],
      },
      'Cervus elaphus': {
        'name': 'Kronhjort',
        'image_url': '', // Will be filled by ImageService
        'description': 'Ett stort hjortdjur med stora horn.',
        'hints': ['Detta är ett hjortdjur', 'Det har stora horn', 'Det lever i skogar', 'Det är större än rådjur', 'Det har rödbrun päls'],
      },
      'Sus scrofa': {
        'name': 'Vildsvin',
        'image_url': '', // Will be filled by ImageService
        'description': 'Ett stort däggdjur som lever i skogar.',
        'hints': ['Detta är ett stort däggdjur', 'Det har betar', 'Det lever i skogar', 'Det är allätare', 'Det kan vara farligt'],
      },
      'Lepus europaeus': {
        'name': 'Hare',
        'image_url': '', // Will be filled by ImageService
        'description': 'Ett litet däggdjur med långa öron.',
        'hints': ['Detta är ett litet däggdjur', 'Det har långa öron', 'Det hoppar', 'Det lever på öppna fält', 'Det är växtätare'],
      },
    };
    
    return animalDataMap[scientificName] ?? {
      'name': scientificName,
      'image_url': 'https://via.placeholder.com/400x300?text=No+Image',
      'description': 'Information om detta djur saknas.',
      'hints': ['Information om detta djur saknas'],
    };
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
  
  /// Clear game history from Supabase database (using daily_scores table)
  static Future<void> _clearFromDatabase() async {
    await _ensureAuth();
    
    await supa
        .from('daily_scores')
        .delete()
        .eq('user_id', supa.auth.currentUser!.id);
  }
  
  /// Clear game history from local storage
  static Future<void> _clearFromLocal() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
  }
  
  /// Clear only local cache (keep database data)
  static Future<void> clearLocalCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
    print('DEBUG HISTORY: Local cache cleared');
  }
  
  /// Get history from database only (no local fallback)
  static Future<List<Map<String, dynamic>>> getGameHistoryFromDatabaseOnly() async {
    try {
      await _ensureAuth();
      
      final response = await supa
          .from('daily_scores')
          .select('*')
          .eq('user_id', supa.auth.currentUser!.id)
          .order('created_at', ascending: false)
          .limit(50);
      
      if (response is List) {
        // Convert daily_scores format to game_history format
        final convertedScores = <Map<String, dynamic>>[];
        for (final score in response) {
          final convertedScore = await _convertDailyScoreToGameHistory(score);
          convertedScores.add(convertedScore);
        }
        print('DEBUG HISTORY: Database-only mode returned ${convertedScores.length} records from daily_scores');
        
        return convertedScores;
      }
      
      print('DEBUG HISTORY: Database-only mode returned empty');
      return [];
    } catch (e) {
      print('Error loading from database only: $e');
      return [];
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
