import 'package:shared_preferences/shared_preferences.dart';
import '../models/animal_data.dart';

class DailyPlayService {
  static const String _dailyPlayKey = 'daily_play_date';
  static const String _dailyAnimalKey = 'daily_animal';
  
  /// Check if user has already played today
  static Future<bool> hasPlayedToday() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastPlayDate = prefs.getString(_dailyPlayKey);
      
      if (lastPlayDate == null) return false;
      
      final today = DateTime.now();
      final lastPlay = DateTime.parse(lastPlayDate);
      
      // Check if it's the same day
      return today.year == lastPlay.year && 
             today.month == lastPlay.month && 
             today.day == lastPlay.day;
    } catch (e) {
      print('Error checking daily play status: $e');
      return false;
    }
  }
  
  /// Mark that user has played today
  static Future<void> markPlayedToday() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now().toIso8601String();
      await prefs.setString(_dailyPlayKey, today);
    } catch (e) {
      print('Error marking daily play: $e');
    }
  }
  
  /// Get today's animal (cached)
  static Future<AnimalData?> getTodaysAnimal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final animalJson = prefs.getString(_dailyAnimalKey);
      
      if (animalJson == null) return null;
      
      final animalMap = Map<String, dynamic>.from(
        Uri.splitQueryString(animalJson)
      );
      
      return AnimalData.fromJson(animalMap);
    } catch (e) {
      print('Error getting today\'s animal: $e');
      return null;
    }
  }
  
  /// Cache today's animal
  static Future<void> setTodaysAnimal(AnimalData animal) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final animalJson = Uri(queryParameters: animal.toJson()).query;
      await prefs.setString(_dailyAnimalKey, animalJson);
    } catch (e) {
      print('Error caching today\'s animal: $e');
    }
  }
  
  /// Clear daily play status (for testing)
  static Future<void> clearDailyPlay() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_dailyPlayKey);
      await prefs.remove(_dailyAnimalKey);
    } catch (e) {
      print('Error clearing daily play: $e');
    }
  }
}
