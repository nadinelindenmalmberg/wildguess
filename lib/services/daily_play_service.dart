import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/animal_data.dart';

class DailyPlayService {
  static const String _dailyPlayKey = 'daily_play_date';
  static const String _dailyAnimalKey = 'daily_animal';
  static final SupabaseClient _supa = Supabase.instance.client;
  
  static Future<void> _ensureAuth() async {
    if (_supa.auth.currentSession == null) {
      await _supa.auth.signInAnonymously();
    }
  }
  
  /// Check if user has already played today
  static Future<bool> hasPlayedToday() async {
    // Primary: check Supabase by user_id and today's day_key
    try {
      await _ensureAuth();
      final userId = _supa.auth.currentUser?.id;
      if (userId != null) {
        final today = DateTime.now();
        final dayKey =
            '${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
        final resp = await _supa
            .from('daily_scores')
            .select('id')
            .eq('user_id', userId)
            .like('day_key', '$dayKey%')
            .limit(1);
        if (resp is List && resp.isNotEmpty) {
          return true;
        }
      }
    } catch (e) {
      print('Error checking daily play status from Supabase: $e');
    }

    // Fallback: local SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastPlayDate = prefs.getString(_dailyPlayKey);
      if (lastPlayDate == null) return false;
      final today = DateTime.now();
      final lastPlay = DateTime.parse(lastPlayDate);
      return today.year == lastPlay.year &&
          today.month == lastPlay.month &&
          today.day == lastPlay.day;
    } catch (e) {
      print('Error checking daily play status (local fallback): $e');
      return false;
    }
  }
  
  /// Mark that user has played today
  static Future<void> markPlayedToday() async {
    // We keep local mark as UI optimization; authoritative check is Supabase
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
