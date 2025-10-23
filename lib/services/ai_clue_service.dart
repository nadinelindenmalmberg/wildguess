import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/animal_data.dart';
import '../core/constants.dart';

class AiClueService {
  // Use your Node.js backend server (secure, cached, rate-limited)
  static const String _backendUrl = 'http://localhost:3000';
  
  final http.Client _client;

  AiClueService({http.Client? client}) : _client = client ?? http.Client();

  /// Generate creative clues for an animal using your secure backend
  Future<List<String>> generateClues(AnimalData animal, {bool isEnglish = false}) async {
    try {
      print('[AiClueService] Generating AI clues for: ${animal.name}');
      
      final clues = await _callBackend(animal, isEnglish);
      return clues;
    } catch (e) {
      print('[AiClueService] Error generating clues: $e');
      // Fallback to original hints if AI fails
      return animal.hints;
    }
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
    } else {
      throw Exception('Backend API error: ${response.statusCode} - ${response.body}');
    }
  }


  void dispose() {
    _client.close();
  }
}

