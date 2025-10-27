import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/animal_data.dart';
// core/constants behövs inte här längre om _backendUrl är direkt i klassen

class AiClueService {
  // Use your Node.js backend server (secure, cached, rate-limited)
  static const String _backendUrl = 'http://127.0.0.1:3000'; // Eller din publika IP/domän

  final http.Client _client;

  // Clue cache
  bool _isLoadingClues = false;
  final Map<String, List<String>> _clueCache = {};
  final Map<String, DateTime> _clueCacheTimestamps = {};
  static const Duration _clueCacheExpiry = Duration(hours: 24);

  // --- NYTT FÖR FAKTA ---
  // Fact cache
  bool _isLoadingFacts = false;
  final Map<String, List<String>> _factCache = {};
  final Map<String, DateTime> _factCacheTimestamps = {};
  static const Duration _factCacheExpiry = Duration(hours: 1); // Kortare cache för fakta?
  // --- SLUT PÅ NYTT FÖR FAKTA ---


  AiClueService({http.Client? client}) : _client = client ?? http.Client();

  /// Generate creative clues for an animal using your secure backend
  Future<List<String>> generateClues(AnimalData animal, {bool isEnglish = false}) async {
    if (_isLoadingClues) {
      print('[AiClueService] Clue request already in progress, skipping...');
      return animal.hints;
    }

    final cacheKey = 'clues::${animal.scientificName}_${isEnglish ? 'en' : 'sv'}';

    if (_clueCache.containsKey(cacheKey)) {
      final timestamp = _clueCacheTimestamps[cacheKey];
      if (timestamp != null && DateTime.now().difference(timestamp) < _clueCacheExpiry) {
        print('[AiClueService] Using cached clues for: ${animal.name}');
        return _clueCache[cacheKey]!;
      } else {
        _clueCache.remove(cacheKey);
        _clueCacheTimestamps.remove(cacheKey);
      }
    }

    try {
      _isLoadingClues = true;
      print('[AiClueService] Generating clues for: ${animal.name}');

      final clues = await _callBackendWithRetry(
        animal,
        isEnglish,
        endpoint: '/clues',
        resultKey: 'clues',
        fallback: animal.hints,
      );

      _clueCache[cacheKey] = clues;
      _clueCacheTimestamps[cacheKey] = DateTime.now();

      return clues;
    } catch (e) {
      print('[AiClueService] Error generating clues: $e');
      return animal.hints;
    } finally {
      _isLoadingClues = false;
    }
  }

  // --- NY METOD FÖR FAKTA ---
  /// Generate interesting facts for an animal using your secure backend
  Future<List<String>> generateFacts(AnimalData animal, {bool isEnglish = false}) async {
    if (_isLoadingFacts) {
      print('[AiClueService] Fact request already in progress, skipping...');
      // Returnera en tom lista eller någon standardtext vid pågående anrop
      return isEnglish ? ['Loading facts...'] : ['Laddar fakta...'];
    }

    final cacheKey = 'facts::${animal.scientificName}_${isEnglish ? 'en' : 'sv'}';

    if (_factCache.containsKey(cacheKey)) {
      final timestamp = _factCacheTimestamps[cacheKey];
      if (timestamp != null && DateTime.now().difference(timestamp) < _factCacheExpiry) {
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

      final facts = await _callBackendWithRetry(
        animal,
        isEnglish,
        endpoint: '/facts', // Anropa nya endpointen
        resultKey: 'facts', // Förväntad nyckel i JSON-svaret
        fallback: [],       // Fallback är en tom lista om fakta misslyckas
      );

      // Spara bara om fakta inte är tom (för att undvika att cacha misslyckanden)
      if (facts.isNotEmpty) {
         _factCache[cacheKey] = facts;
         _factCacheTimestamps[cacheKey] = DateTime.now();
      }

      return facts;
    } catch (e) {
      print('[AiClueService] Error generating facts: $e');
      // Returnera tom lista vid fel
      return [];
    } finally {
      _isLoadingFacts = false;
    }
  }
  // --- SLUT PÅ NY METOD ---

  // --- UPPDATERAD _callBackendWithRetry FÖR ATT HANTERA OLIKA ENDPOINTS ---
  /// Call backend with exponential backoff retry logic (Generic)
  Future<List<String>> _callBackendWithRetry(
    AnimalData animal,
    bool isEnglish, {
    required String endpoint, // '/clues' or '/facts'
    required String resultKey, // 'clues' or 'facts'
    required List<String> fallback, // Fallback vid totalt misslyckande
  }) async {
    int retryCount = 0;
    const maxRetries = 2;

    while (retryCount <= maxRetries) {
      try {
        return await _callBackend(
          animal,
          isEnglish,
          endpoint: endpoint,
          resultKey: resultKey,
        );
      } catch (e) {
        retryCount++;
        final waitSeconds = 2 * retryCount;

        if (e.toString().contains('429')) {
          print('[AiClueService] Rate limited (429) on $endpoint, waiting ${waitSeconds}s before retry...');
          await Future.delayed(Duration(seconds: waitSeconds));
        } else if (e.toString().contains('500') || e.toString().contains('502') || e.toString().contains('503')) {
          print('[AiClueService] Server error on $endpoint, retrying in ${waitSeconds}s...');
          await Future.delayed(Duration(seconds: waitSeconds));
        } else if (e is SocketException || e is http.ClientException) { // Fånga ClientException också
          print('[AiClueService] Network error on $endpoint ($e), retrying in ${waitSeconds}s...');
          await Future.delayed(Duration(seconds: waitSeconds));
        } else {
           print('[AiClueService] Unretryable error on $endpoint: $e'); // Logga felet
          rethrow; // For other errors, don't retry, throw immediately
        }

        if (retryCount > maxRetries) {
           print('[AiClueService] Max retries exceeded for $endpoint. Last error: $e'); // Logga felet
          // Returnera fallback istället för att kasta exception efter max retries
          return fallback;
          // throw Exception('Max retries exceeded for $endpoint. Last error: $e');
        }
      }
    }
    // Denna kod bör inte nås på grund av logiken ovan, men för säkerhets skull:
    print('[AiClueService] Unexpected exit from retry loop for $endpoint');
    return fallback;
    // throw Exception('Unexpected error in retry logic for $endpoint');
  }

  // --- UPPDATERAD _callBackend FÖR ATT HANTERA OLIKA ENDPOINTS ---
  Future<List<String>> _callBackend(
    AnimalData animal,
    bool isEnglish, {
    required String endpoint,
    required String resultKey,
  }) async {
    final uri = Uri.parse('$_backendUrl$endpoint');

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
    ).timeout(const Duration(seconds: 20)); // Lägg till timeout

    if (response.statusCode == 200) {
      try {
        final data = json.decode(response.body);
        final results = data[resultKey] as List<dynamic>?;
        if (results != null) { // Tillåt tom lista för fakta
          return results.cast<String>();
        }
         // Om nyckeln saknas eller är null, men status är 200, logga och kasta fel
         print('[AiClueService] API $endpoint returned 200 but key "$resultKey" was missing or null. Body: ${response.body}');
         throw Exception('API returned 200 but key "$resultKey" was missing or null.');
      } catch (e) {
         // Fånga JSON-parsningsfel etc.
         print('[AiClueService] Error processing successful response from $endpoint: $e. Body: ${response.body}');
         throw Exception('Failed to process response from $endpoint: $e');
      }
    } else if (response.statusCode == 429) {
      throw Exception('Rate limited (429) - Too many requests.');
    } else if (response.statusCode >= 500) {
      throw Exception('Server error (${response.statusCode})');
    } else {
      // Annat klientfel (t.ex. 400 Bad Request)
       print('[AiClueService] API error ($endpoint - ${response.statusCode}): ${response.body}');
      throw Exception('API error (${response.statusCode})');
    }
  }
  // --- SLUT PÅ UPPDATERINGAR ---


  /// Clear both clue and fact caches
  void clearCache() {
    _clueCache.clear();
    _clueCacheTimestamps.clear();
    _factCache.clear();
    _factCacheTimestamps.clear();
    print('[AiClueService] All caches cleared');
  }

  // ... (getCacheStats och dispose är oförändrade) ...
    /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    return {
      'cachedClues': _clueCache.length,
      'cachedFacts': _factCache.length,
      // Du kan lägga till tidsstämplar om du vill
    };
  }

  void dispose() {
    _client.close();
  }
}