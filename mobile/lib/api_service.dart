import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:http/http.dart' as http;

class AnimalData {
  final String name;
  final String scientificName;
  final String description;
  final List<String> hints;
  final String imageUrl;

  AnimalData({
    required this.name,
    required this.scientificName,
    required this.description,
    required this.hints,
    required this.imageUrl,
  });

  factory AnimalData.fromJson(Map<String, dynamic> json) {
    return AnimalData(
      name: json['name'] ?? '',
      scientificName: json['scientificName'] ?? '',
      description: json['description'] ?? '',
      hints: List<String>.from(json['hints'] ?? []),
      imageUrl: json['imageUrl'] ?? '',
    );
  }
}


class ApiService {
  static const String _baseUrl = 'https://api.artdatabanken.se/v1';
  
  // Secure key loading for taxon service
  static String get taxonSubscriptionKey {
    // 1. Try build-time environment variable (most secure for CI/CD)
    const String envKey = String.fromEnvironment('TAXON_SUBSCRIPTION_KEY');
    if (envKey.isNotEmpty) return envKey;
    
    // 2. Try runtime environment variable (for local development)
    final String? runtimeKey = Platform.environment['TAXON_SUBSCRIPTION_KEY'];
    if (runtimeKey != null && runtimeKey.isNotEmpty) return runtimeKey;
    
    // 3. Try local config file (fallback, should be gitignored)
    try {
      final configFile = File('config/taxon_key.txt');
      if (configFile.existsSync()) {
        final key = configFile.readAsStringSync().trim();
        if (key.isNotEmpty) return key;
      }
    } catch (e) {
      // Ignore file read errors
    }
    
    // 4. Return empty string if no key found
    return '';
  }

  // Secure key loading for species data service
  static String get speciesSubscriptionKey {
    // 1. Try build-time environment variable (most secure for CI/CD)
    const String envKey = String.fromEnvironment('SPECIES_SUBSCRIPTION_KEY');
    if (envKey.isNotEmpty) return envKey;
    
    // 2. Try runtime environment variable (for local development)
    final String? runtimeKey = Platform.environment['SPECIES_SUBSCRIPTION_KEY'];
    if (runtimeKey != null && runtimeKey.isNotEmpty) return runtimeKey;
    
    // 3. Try local config file (fallback, should be gitignored)
    try {
      final configFile = File('config/species_key.txt');
      if (configFile.existsSync()) {
        final key = configFile.readAsStringSync().trim();
        if (key.isNotEmpty) return key;
      }
    } catch (e) {
      // Ignore file read errors
    }
    
    // 4. Return empty string if no key found
    return '';
  }
  
  final http.Client _client;

  ApiService({http.Client? client}) : _client = client ?? http.Client();

  /// Get a random Swedish animal using the live API
  Future<AnimalData> getRandomAnimal() async {
    return getRandomAnimalFromAPI();
  }


  Future<AnimalData> getRandomAnimalFromAPI() async {
    try {
      // First, get all mammal species from the taxon endpoint
      print('[ApiService] Fetching mammal species list...');
      print('[ApiService] Taxon key present: ${taxonSubscriptionKey.isNotEmpty}');
      print('[ApiService] Taxon key length: ${taxonSubscriptionKey.length}');
      
      final mammalListUri = Uri.parse(
        'https://api.artdatabanken.se/taxonservice/v1/taxa/4000107/childids?useMainChildren=false',
      );
      
      final mammalListResponse = await _client.get(
        mammalListUri,
        headers: {
          'Cache-Control': 'no-cache',
          if (taxonSubscriptionKey.isNotEmpty) 'Ocp-Apim-Subscription-Key': taxonSubscriptionKey,
        },
      );

      print('[ApiService] Mammal list response status: ${mammalListResponse.statusCode}');
      
      if (mammalListResponse.statusCode != 200) {
        throw Exception('Failed to get mammal list: ${mammalListResponse.statusCode}');
      }

      final mammalList = json.decode(mammalListResponse.body);
      if (mammalList is! List || mammalList.isEmpty) {
        throw Exception('No mammal species found');
      }

      print('[ApiService] Found ${mammalList.length} mammal species');
      
      // Pick a random mammal species ID
      final rand = math.Random();
      final taxaId = mammalList[rand.nextInt(mammalList.length)];
      
      if (taxaId == null || taxaId == 0) {
        throw Exception('Invalid mammal species ID');
      }

      print('[ApiService] Selected mammal taxa=$taxaId');
      
      // Now get detailed data for this specific mammal species
      final uri = Uri.parse(
        'https://api.artdatabanken.se/information/v1/speciesdataservice/v1/speciesdata?taxa=$taxaId',
      );

      final response = await _client.get(
        uri,
        headers: {
          'Cache-Control': 'no-cache',
          if (speciesSubscriptionKey.isNotEmpty) 'Ocp-Apim-Subscription-Key': speciesSubscriptionKey,
        },
      );

      print('[ApiService] Response status: ${response.statusCode} for taxa=$taxaId');
      final bodyPreview = response.body.isNotEmpty
          ? response.body.substring(0, math.min(200, response.body.length))
          : '';
      if (bodyPreview.isNotEmpty) {
        print('[ApiService] Body (first ${bodyPreview.length} chars): $bodyPreview');
      }

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final decoded = json.decode(response.body);

        // Normalize to first entry
        Map<String, dynamic>? first;
        if (decoded is List && decoded.isNotEmpty && decoded.first is Map<String, dynamic>) {
          first = decoded.first as Map<String, dynamic>;
        } else if (decoded is Map<String, dynamic>) {
          first = decoded;
        }

        final Map<String, dynamic>? speciesData =
            (first != null && first['speciesData'] is Map<String, dynamic>)
                ? first['speciesData'] as Map<String, dynamic>
                : null;

        // Attempt to read names/descriptions from multiple possible fields
        final String name = (speciesData?['swedishName'] ?? first?['swedishName'] ?? first?['name'] ?? '')
            .toString();
        final String sci = (speciesData?['scientificName'] ?? first?['scientificName'] ?? '')
            .toString();

        // Redlist info can provide a useful description and hints
        String desc = '';
        final List<String> hints = <String>[];
        final redlist = speciesData?['redlistInfo'];
        if (redlist is List && redlist.isNotEmpty) {
          final Map<String, dynamic> rl0 = redlist.first is Map<String, dynamic>
              ? redlist.first as Map<String, dynamic>
              : <String, dynamic>{};
          final String category = (rl0['category'] ?? '').toString();
          final Map<String, dynamic>? period = rl0['period'] is Map<String, dynamic>
              ? rl0['period'] as Map<String, dynamic>
              : null;
          final String periodName = (period?['name'] ?? '').toString();
          final String criterionText = (rl0['criterionText'] ?? '').toString();
          desc = criterionText.isNotEmpty ? criterionText : desc;

          if (category.isNotEmpty || periodName.isNotEmpty) {
            hints.add('Rödlistning: ${category.isNotEmpty ? category : 'okänd'}${periodName.isNotEmpty ? ' (' + periodName + ')' : ''}');
          }
          if (criterionText.isNotEmpty) {
            final snippet = criterionText.substring(0, math.min(120, criterionText.length));
            hints.add('Kriterium: $snippet…');
          }
        }

        if (name.isNotEmpty) {
          hints.insert(0, 'Svenskt namn: $name');
        }
        if (sci.isNotEmpty) {
          hints.add('Vetenskapligt namn: $sci');
        }

        if (first != null) {
          return AnimalData(
            name: name.isNotEmpty ? name : 'Taxon $taxaId',
            scientificName: sci,
            description: desc,
            hints: hints.isNotEmpty ? hints : ['Ingen ledtråd tillgänglig'],
            imageUrl: '',
          );
        }
      }

      throw Exception('No data found for selected mammal species');
    } catch (e) {
      print('[ApiService] Exception during API call: $e');
      throw Exception('API Error: $e');
    }
  }


  void dispose() {
    _client.close();
  }
}

