import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:async'; // Importera för timeout
import '../models/animal_data.dart';
// import '../core/constants.dart'; // Behövs ej om _backendUrl är definierad här

class AiClueService {
  // Use your Node.js backend server (secure, cached, rate-limited)
  // Uppdatera denna URL om din backend körs någon annanstans (t.ex. Vercel, Render)
  static const String _backendUrl = 'http://127.0.0.1:3000'; // För lokal testning

  final http.Client _client;

  // Cache och throttling för ledtrådar
  bool _isLoadingClues = false; // Byt namn för tydlighet
  final Map<String, List<String>> _clueCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheExpiry = Duration(hours: 24);

  // *** NYTT: Cache och throttling för fakta ***
  bool _isLoadingFacts = false;
  final Map<String, List<String>> _factCache = {};
  final Map<String, DateTime> _factCacheTimestamps = {};
  // Använder samma _cacheExpiry för fakta

  AiClueService({http.Client? client}) : _client = client ?? http.Client();

  /// Generate creative clues for an animal using your secure backend
  Future<List<String>> generateClues(AnimalData animal, {bool isEnglish = false}) async {
    // Request throttling
    if (_isLoadingClues) { // Använder _isLoadingClues
      print('[AiClueService] Clue request already in progress, skipping...');
      return animal.hints; // Return fallback hints
    }

    // Create cache key
    final cacheKey = '${animal.scientificName}_clues_${isEnglish ? 'en' : 'sv'}'; // Lade till _clues

    // Check cache first
    if (_clueCache.containsKey(cacheKey)) {
      final timestamp = _cacheTimestamps[cacheKey];
      if (timestamp != null && DateTime.now().difference(timestamp) < _cacheExpiry) {
        print('[AiClueService] Using cached clues for: ${animal.name}');
        return _clueCache[cacheKey]!;
      } else {
        _clueCache.remove(cacheKey);
        _cacheTimestamps.remove(cacheKey);
      }
    }

    try {
      _isLoadingClues = true; // Sätter _isLoadingClues
      print('[AiClueService] Generating clues for: ${animal.name}');

      // Använder den befintliga _callBackendWithRetry för /clues
      final clues = await _callCluesBackendWithRetry(animal, isEnglish);

      // Cache the results
      _clueCache[cacheKey] = clues;
      _cacheTimestamps[cacheKey] = DateTime.now();

      return clues;
    } catch (e) {
      print('[AiClueService] Error generating clues: $e');
      return animal.hints; // Fallback
    } finally {
      _isLoadingClues = false; // Återställer _isLoadingClues
    }
  }

  /// *** NY METOD: Generate interesting facts for an animal ***
  Future<List<String>> generateFacts(AnimalData animal, {bool isEnglish = false}) async {
      print('[AiClueService] generateFacts called for: ${animal.name}, isEnglish: $isEnglish');
      if (_isLoadingFacts) {
          print('[AiClueService] Fact request already in progress, skipping...');
          return []; // Returnera tom lista eller fallback
      }

      final cacheKey = '${animal.scientificName}_facts_${isEnglish ? 'en' : 'sv'}'; // Lade till _facts

      // Check cache first
      if (_factCache.containsKey(cacheKey)) {
          final timestamp = _factCacheTimestamps[cacheKey];
          if (timestamp != null && DateTime.now().difference(timestamp) < _cacheExpiry) {
              print('[AiClueService] Using cached facts for: ${animal.name}');
              return _factCache[cacheKey]!;
          } else {
              _factCache.remove(cacheKey);
              _factCacheTimestamps.remove(cacheKey);
          }
      }

      try {
          _isLoadingFacts = true;
          print('[AiClueService] Generating facts for: ${animal.name}');

          // Anropar en ny retry-metod specifik för /facts
          final facts = await _callFactsBackendWithRetry(animal, isEnglish);
          print('[AiClueService] Backend returned ${facts.length} facts: $facts');

          // Cache the results
          _factCache[cacheKey] = facts;
          _factCacheTimestamps[cacheKey] = DateTime.now();

          return facts;
      } catch (e) {
          print('[AiClueService] Error generating facts: $e');
          return []; // Returnera tom lista vid fel
      } finally {
          _isLoadingFacts = false;
      }
  }

  // --- Backend Call Methods with Retry ---

  /// Call backend /clues endpoint with exponential backoff retry logic
  Future<List<String>> _callCluesBackendWithRetry(AnimalData animal, bool isEnglish) async {
    return _callBackendWithRetryInternal(
      endpoint: '/clues', // Specificera endpoint
      animal: animal,
      isEnglish: isEnglish,
    );
  }

  /// *** NY METOD: Call backend /facts endpoint with retry ***
  Future<List<String>> _callFactsBackendWithRetry(AnimalData animal, bool isEnglish) async {
    return _callBackendWithRetryInternal(
      endpoint: '/facts', // Specificera endpoint
      animal: animal,
      isEnglish: isEnglish,
    );
  }

  /// Internal helper for calling backend with retry logic
  Future<List<String>> _callBackendWithRetryInternal({
    required String endpoint,
    required AnimalData animal,
    required bool isEnglish,
  }) async {
    int retryCount = 0;
    const maxRetries = 2;
    const baseDelay = Duration(seconds: 1); // Grundfördröjning

    while (retryCount <= maxRetries) {
      try {
        final uri = Uri.parse('$_backendUrl$endpoint');
        print('[AiClueService] Calling $endpoint for ${animal.name}');

        final response = await _client.post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'animalName': animal.name,
            'scientificName': animal.scientificName,
            'description': animal.description,
            'isEnglish': isEnglish,
          }),
        ).timeout(const Duration(seconds: 15)); // Timeout för anropet

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          // Kolla rätt nyckel beroende på endpoint
          final resultList = endpoint == '/clues'
              ? data['clues'] as List<dynamic>?
              : data['facts'] as List<dynamic>?;

          if (resultList != null && resultList.isNotEmpty) {
            return resultList.cast<String>();
          }
          throw Exception('No results (clues/facts) in response from $endpoint');
        } else if (response.statusCode == 429) {
          throw HttpException('Rate limited (429)'); // Använd HttpException för tydlighet
        } else if (response.statusCode >= 500) {
          throw HttpException('Server error (${response.statusCode})');
        } else {
          throw HttpException('API error (${response.statusCode}): ${response.body}');
        }
      } catch (e) {
        retryCount++;
        final isLastRetry = retryCount > maxRetries;
        print('[AiClueService] Error calling $endpoint (Attempt $retryCount/$maxRetries): $e');

        if (isLastRetry) {
          throw Exception('Max retries exceeded for $endpoint. Last error: $e');
        }

        // Beräkna väntetid (exponentiell backoff)
        final delay = baseDelay * (1 << (retryCount -1)); // 1s, 2s, 4s
        print('[AiClueService] Waiting ${delay.inSeconds}s before retrying $endpoint...');
        await Future.delayed(delay);

        // Specifik hantering baserat på feltyp (kan utökas)
        if (e is SocketException) {
          print('[AiClueService] Network error detected.');
        } else if (e is TimeoutException) {
           print('[AiClueService] Request timed out.');
        } else if (e is HttpException && e.message.contains('429')) {
           print('[AiClueService] Rate limit hit.');
        }
      }
    }
     throw Exception('Unexpected error in retry logic for $endpoint'); // Ska inte nås
  }


  /// Clear both clue and fact caches
  void clearCache() {
    _clueCache.clear();
    _cacheTimestamps.clear();
    _factCache.clear(); // Rensa fakta-cachen också
    _factCacheTimestamps.clear();
    print('[AiClueService] Caches cleared');
  }

  /// Get cache statistics (kan utökas för fakta om det behövs)
  Map<String, dynamic> getCacheStats() {
    return {
      'cachedClues': _clueCache.length,
      'cachedFacts': _factCache.length, // Lägg till fakta-cache-storlek
      // Kan lägga till timestamps om det är intressant
    };
  }

  void dispose() {
    // Om _client skapades internt, stäng den. Om den injicerades, gör inget.
    // I detta fall skapas den internt om ingen skickas in.
    // Det är dock oftast bättre att låta den som skapar AiClueService hantera clientens livscykel.
    // Men för enkelhets skull, stänger vi den här om den inte injicerats.
    // Detta antar att du inte skickar in en client i konstruktorn.
    try {
       _client.close();
       print("[AiClueService] HTTP client closed.");
    } catch (e) {
       print("[AiClueService] Error closing HTTP client: $e");
    }
  }
}

// Helper Exception class för HTTP-fel
class HttpException implements Exception {
  final String message;
  HttpException(this.message);

  @override
  String toString() => message;
}