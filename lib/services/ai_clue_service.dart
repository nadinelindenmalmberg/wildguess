import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/animal_data.dart';
import '../core/constants.dart';

class AiClueService {
  // Use your Node.js backend server (secure, cached, rate-limited)
  static const String _backendUrl = 'http://127.0.0.1:3001';
  
  final http.Client _client;
  
  // Request throttling and caching
  bool _isLoading = false;
  final Map<String, List<String>> _clueCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheExpiry = Duration(hours: 24);

  AiClueService({http.Client? client}) : _client = client ?? http.Client();

  /// Generate creative clues for an animal using your secure backend
  Future<List<String>> generateClues(AnimalData animal, {bool isEnglish = false}) async {
    // Request throttling - prevent multiple calls in quick succession
    if (_isLoading) {
      print('[AiClueService] Request already in progress, skipping...');
      return animal.hints; // Return fallback hints
    }
    
    // Create cache key
    final cacheKey = '${animal.scientificName}_${isEnglish ? 'en' : 'sv'}';
    
    // Check cache first
    if (_clueCache.containsKey(cacheKey)) {
      final timestamp = _cacheTimestamps[cacheKey];
      if (timestamp != null && DateTime.now().difference(timestamp) < _cacheExpiry) {
        print('[AiClueService] Using cached clues for: ${animal.name}');
        return _clueCache[cacheKey]!;
      } else {
        // Cache expired, remove it
        _clueCache.remove(cacheKey);
        _cacheTimestamps.remove(cacheKey);
      }
    }
    
    try {
      _isLoading = true;
      print('[AiClueService] Generating clues for: ${animal.name}');
      
      final clues = await _callBackendWithRetry(animal, isEnglish);
      
      // Cache the results
      _clueCache[cacheKey] = clues;
      _cacheTimestamps[cacheKey] = DateTime.now();
      
      return clues;
    } catch (e) {
      print('[AiClueService] Error generating clues: $e');
      // Fallback to original hints if AI fails
      return animal.hints;
    } finally {
      _isLoading = false;
    }
  }

  /// Call backend with exponential backoff retry logic
  Future<List<String>> _callBackendWithRetry(AnimalData animal, bool isEnglish) async {
    int retryCount = 0;
    const maxRetries = 2;
    
    while (retryCount <= maxRetries) {
      try {
        return await _callBackend(animal, isEnglish);
      } catch (e) {
        retryCount++;
        
        // Handle specific HTTP errors
        if (e.toString().contains('429')) {
          print('[AiClueService] Rate limited (429), waiting before retry...');
          await Future.delayed(Duration(seconds: 2 * retryCount)); // Exponential backoff
        } else if (e.toString().contains('500') || e.toString().contains('502') || e.toString().contains('503')) {
          print('[AiClueService] Server error, retrying in ${2 * retryCount} seconds...');
          await Future.delayed(Duration(seconds: 2 * retryCount));
        } else if (e is SocketException) {
          print('[AiClueService] Network error, retrying in ${2 * retryCount} seconds...');
          await Future.delayed(Duration(seconds: 2 * retryCount));
        } else {
          // For other errors, don't retry
          rethrow;
        }
        
        if (retryCount > maxRetries) {
          throw Exception('Max retries exceeded. Last error: $e');
        }
      }
    }
    
    throw Exception('Unexpected error in retry logic');
  }

  Future<List<String>> _callBackend(AnimalData animal, bool isEnglish) async {
    final uri = Uri.parse('$_backendUrl/clues');
    
    final response = await _client.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'animalName': animal.name,
        'scientificName': animal.scientificName,
        'description': animal.description,
        'isEnglish': isEnglish,
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final clues = data['clues'] as List<dynamic>?;
      if (clues != null && clues.isNotEmpty) {
        return clues.cast<String>();
      }
      throw Exception('No clues in response');
    } else if (response.statusCode == 429) {
      throw Exception('Rate limited (429) - Too many requests. Please wait a few seconds and try again.');
    } else if (response.statusCode >= 500) {
      throw Exception('Server error (${response.statusCode}) - Please try again later.');
    } else {
      throw Exception('API error (${response.statusCode}): ${response.body}');
    }
  }


  /// Clear the clue cache
  void clearCache() {
    _clueCache.clear();
    _cacheTimestamps.clear();
    print('[AiClueService] Cache cleared');
  }
  
  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    return {
      'cachedItems': _clueCache.length,
      'oldestCache': _cacheTimestamps.values.isNotEmpty 
          ? _cacheTimestamps.values.reduce((a, b) => a.isBefore(b) ? a : b)
          : null,
      'newestCache': _cacheTimestamps.values.isNotEmpty 
          ? _cacheTimestamps.values.reduce((a, b) => a.isAfter(b) ? a : b)
          : null,
    };
  }

  void dispose() {
    _client.close();
  }
}

