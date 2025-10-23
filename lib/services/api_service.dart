import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;

import '../core/constants.dart';
import '../models/animal_data.dart';
import '../models/taxon_response.dart';
import '../models/species_data.dart';


class ApiService {
  
  // Build-time injected subscription keys
  static const String taxonSubscriptionKey = String.fromEnvironment('TAXON_SUBSCRIPTION_KEY');
  static const String speciesSubscriptionKey = String.fromEnvironment('SPECIES_SUBSCRIPTION_KEY');
  
  final http.Client _client;
  
  // Cache for species data to avoid repeated API calls
  static final Map<int, AnimalData> _speciesCache = {};
  static List<AnimalData>? _allSpeciesCache;

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
      
      // Use the known working taxonId for mammals (4000107)
      // Using the mammal taxon ID (4000107) defined in AppConstants
      // AppConstants is defined in lib/core/constants.dart
      print('[ApiService] Getting mammal species from taxonId ${AppConstants.mammalTaxonId}...');
      final mammalListUri = Uri.parse(
        '${AppConstants.taxonServiceUrl}/taxa/${AppConstants.mammalTaxonId}/childids?useMainChildren=false&id=${AppConstants.speciesCategoryId}',
      );
      
      final mammalListResponse = await _client.get(
        mammalListUri,
        headers: {
          ...AppConstants.defaultHeaders,
          if (taxonSubscriptionKey.isNotEmpty) 'Ocp-Apim-Subscription-Key': taxonSubscriptionKey,
        },
      );
      
      print('[ApiService] Mammal list response status: ${mammalListResponse.statusCode}');
      
      if (mammalListResponse.statusCode != 200) {
        throw Exception('Failed to get mammal list: ${mammalListResponse.statusCode}');
      }

      final responseData = json.decode(mammalListResponse.body);
      print('[ApiService] Raw response: ${responseData.toString().substring(0, 500)}...');
      
      // Debug: Show the full response structure
      print('[ApiService] === FULL TAXON API RESPONSE ===');
      print('[ApiService] Response type: ${responseData.runtimeType}');
      print('[ApiService] Response keys: ${responseData is Map ? responseData.keys.toList() : 'Not a Map'}');
      if (responseData is Map) {
        print('[ApiService] taxonIds field: ${responseData['taxonIds']}');
        print('[ApiService] taxonInfos field: ${responseData['taxonInfos']}');
        if (responseData['taxonInfos'] is List) {
          print('[ApiService] taxonInfos length: ${(responseData['taxonInfos'] as List).length}');
          if ((responseData['taxonInfos'] as List).isNotEmpty) {
            print('[ApiService] First taxonInfo: ${(responseData['taxonInfos'] as List).first}');
          }
        }
      }
      print('[ApiService] === END FULL RESPONSE ===');
      
      // Parse the response - should be a list of taxon IDs (already filtered by server)
      List<int> taxonIds = [];
      
      if (responseData is List) {
        // Direct list of taxon IDs
        taxonIds = responseData.cast<int>();
        print('[ApiService] Found ${taxonIds.length} species-level mammal taxa (server-filtered by category ID ${AppConstants.speciesCategoryId})');
      } else if (responseData is Map && responseData['taxonIds'] is List) {
        // Wrapped in taxonIds field
        taxonIds = (responseData['taxonIds'] as List).cast<int>();
        print('[ApiService] Found ${taxonIds.length} species-level mammal taxa (server-filtered by category ID ${AppConstants.speciesCategoryId})');
      } else {
        throw Exception('Unexpected API response structure: ${responseData.runtimeType}');
      }
      
      if (taxonIds.isEmpty) {
        throw Exception('No mammal species found (server returned 0 taxa with category ID ${AppConstants.speciesCategoryId})');
      }
      
      // Pick a random mammal species ID
      final rand = math.Random();
      final taxaId = taxonIds[rand.nextInt(taxonIds.length)];
      
      if (taxaId == null || taxaId == 0) {
        throw Exception('Invalid mammal species ID');
      }

      print('[ApiService] Selected mammal taxa=$taxaId from ${taxonIds.length} available species');
      
      // Now get detailed data for this specific mammal species
      final uri = Uri.parse(
        '${AppConstants.speciesDataServiceUrl}/speciesdata?taxa=$taxaId',
      );

      final response = await _client.get(
        uri,
        headers: {
          ...AppConstants.defaultHeaders,
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
      
      // Log the FULL response for debugging
      if (response.statusCode == 200 && response.body.isNotEmpty) {
        print('[ApiService] === FULL ARTDATABANKEN RESPONSE ===');
        print('[ApiService] Full response body: ${response.body}');
        print('[ApiService] === END FULL RESPONSE ===');
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

        // Debug: Show all available fields in the response
        print('[ApiService] === AVAILABLE FIELDS IN RESPONSE ===');
        if (first != null) {
          print('[ApiService] Top-level fields: ${first.keys.toList()}');
          if (speciesData != null) {
            print('[ApiService] SpeciesData fields: ${speciesData.keys.toList()}');
          }
        }
        print('[ApiService] === END AVAILABLE FIELDS ===');

        // Attempt to read names/descriptions from multiple possible fields
        final String name = (speciesData?['swedishName'] ?? first?['swedishName'] ?? first?['name'] ?? '')
            .toString();
        final String sci = (speciesData?['scientificName'] ?? first?['scientificName'] ?? '')
            .toString();
        
        // Extract additional fields from the correct nested structure
        final Map<String, dynamic>? speciesFactText = speciesData?['speciesFactText'];
        final String ecology = (speciesFactText?['ecology'] ?? '').toString();
        final String characteristicAsHtml = (speciesFactText?['characteristicAsHtml'] ?? '').toString();
        final String ecologyChangedDate = (speciesFactText?['ecologyChangedDate'] ?? '').toString();
        final String characteristic = (speciesFactText?['characteristic'] ?? '').toString();
        final String spreadAndStatus = (speciesFactText?['spreadAndStatus'] ?? '').toString();

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
        
        // Add additional fields as hints if available
        if (ecology.isNotEmpty) {
          // Truncate long ecology text for hints
          final ecologySnippet = ecology.length > 200 
              ? ecology.substring(0, 200) + '...'
              : ecology;
          hints.add('Ekologi: $ecologySnippet');
        }
        if (characteristic.isNotEmpty) {
          // Use the plain text characteristic (not HTML)
          final characteristicSnippet = characteristic.length > 200 
              ? characteristic.substring(0, 200) + '...'
              : characteristic;
          hints.add('Karaktäristik: $characteristicSnippet');
        } else if (characteristicAsHtml.isNotEmpty) {
          // Fallback to HTML version if plain text not available
          final cleanCharacteristics = characteristicAsHtml
              .replaceAll(RegExp(r'<[^>]*>'), '')
              .replaceAll('&nbsp;', ' ')
              .replaceAll('&ndash;', '-')
              .replaceAll('&auml;', 'ä')
              .replaceAll('&ouml;', 'ö')
              .replaceAll('&aring;', 'å')
              .trim();
          if (cleanCharacteristics.isNotEmpty) {
            final characteristicSnippet = cleanCharacteristics.length > 200 
                ? cleanCharacteristics.substring(0, 200) + '...'
                : cleanCharacteristics;
            hints.add('Karaktäristik: $characteristicSnippet');
          }
        }
        if (spreadAndStatus.isNotEmpty) {
          final spreadSnippet = spreadAndStatus.length > 150 
              ? spreadAndStatus.substring(0, 150) + '...'
              : spreadAndStatus;
          hints.add('Utbredning: $spreadSnippet');
        }

        if (first != null) {
          // Debug: Show what data we're extracting
          print('[ApiService] === EXTRACTED DATA ===');
          print('[ApiService] Name: $name');
          print('[ApiService] Scientific Name: $sci');
          print('[ApiService] Description: $desc');
          print('[ApiService] Ecology: $ecology');
          print('[ApiService] Characteristic: $characteristic');
          print('[ApiService] CharacteristicAsHtml: $characteristicAsHtml');
          print('[ApiService] SpreadAndStatus: $spreadAndStatus');
          print('[ApiService] Ecology Changed Date: $ecologyChangedDate');
          print('[ApiService] Hints: $hints');
          print('[ApiService] Image URL: (empty - not available in current API)');
          print('[ApiService] === END EXTRACTED DATA ===');
          
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


  /// Get all species data once and cache it for fast searching
  Future<List<AnimalData>> _getAllSpecies() async {
    if (_allSpeciesCache != null) {
      print('[ApiService] Using cached species data');
      return _allSpeciesCache!;
    }
    
    print('[ApiService] Loading all species data for the first time...');
    
    try {
      // Get all mammal species first (using the same endpoint as random animal)
      final mammalListUri = Uri.parse(
        '${AppConstants.taxonServiceUrl}/taxa/${AppConstants.mammalTaxonId}/childids?useMainChildren=false&id=${AppConstants.speciesCategoryId}',
      );
      
      final mammalListResponse = await _client.get(
        mammalListUri,
        headers: {
          ...AppConstants.defaultHeaders,
          if (taxonSubscriptionKey.isNotEmpty) 'Ocp-Apim-Subscription-Key': taxonSubscriptionKey,
        },
      );
      
      if (mammalListResponse.statusCode != 200) {
        throw Exception('Failed to get mammal list: ${mammalListResponse.statusCode}');
      }

      final responseData = json.decode(mammalListResponse.body);
      List<int> taxonIds = [];
      
      if (responseData is List) {
        taxonIds = responseData.cast<int>();
      } else if (responseData is Map && responseData['taxonIds'] is List) {
        taxonIds = (responseData['taxonIds'] as List).cast<int>();
      }
      
      print('[ApiService] Found ${taxonIds.length} species-level mammal taxa (server-filtered by category ID ${AppConstants.speciesCategoryId})');
      
      // Load all species data in parallel (much faster)
      final futures = taxonIds.map((taxaId) => _getSpeciesData(taxaId));
      final results = await Future.wait(futures, eagerError: false);
      
      // Filter out null results and cache
      final allSpecies = results.where((animal) => animal != null).cast<AnimalData>().toList();
      _allSpeciesCache = allSpecies;
      
      print('[ApiService] Loaded ${allSpecies.length} species into cache (only individual species, no families/genera)');
      
      // Debug: Show some examples of what species were loaded
      for (int i = 0; i < math.min(5, allSpecies.length); i++) {
        final species = allSpecies[i];
        print('[ApiService] Example species $i: ${species.name} (${species.scientificName})');
      }
      
      return allSpecies;
      
    } catch (e) {
      print('[ApiService] Exception loading all species: $e');
      throw Exception('Species Loading Error: $e');
    }
  }
  
  /// Get individual species data (with caching)
  Future<AnimalData?> _getSpeciesData(int taxaId) async {
    if (_speciesCache.containsKey(taxaId)) {
      return _speciesCache[taxaId];
    }
    
    try {
      final uri = Uri.parse(
        '${AppConstants.speciesDataServiceUrl}/speciesdata?taxa=$taxaId',
      );

      final response = await _client.get(
        uri,
        headers: {
          ...AppConstants.defaultHeaders,
          if (speciesSubscriptionKey.isNotEmpty) 'Ocp-Apim-Subscription-Key': speciesSubscriptionKey,
        },
      );

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final decoded = json.decode(response.body);
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

        final String name = (speciesData?['swedishName'] ?? first?['swedishName'] ?? first?['name'] ?? '')
            .toString();
        final String sci = (speciesData?['scientificName'] ?? first?['scientificName'] ?? '')
            .toString();

        // Extract additional data
        final Map<String, dynamic>? speciesFactText = speciesData?['speciesFactText'];
        final String ecology = (speciesFactText?['ecology'] ?? '').toString();
        final String characteristic = (speciesFactText?['characteristic'] ?? '').toString();
        
        // Create basic hints
        final List<String> hints = <String>[];
        if (name.isNotEmpty) {
          hints.add('Svenskt namn: $name');
        }
        if (sci.isNotEmpty) {
          hints.add('Vetenskapligt namn: $sci');
        }
        if (ecology.isNotEmpty) {
          final ecologySnippet = ecology.length > 100 
              ? ecology.substring(0, 100) + '...'
              : ecology;
          hints.add('Ekologi: $ecologySnippet');
        }
        
        final animalData = AnimalData(
          name: name.isNotEmpty ? name : 'Taxon $taxaId',
          scientificName: sci,
          description: characteristic.isNotEmpty ? characteristic : '',
          hints: hints.isNotEmpty ? hints : ['Ingen information tillgänglig'],
          imageUrl: '',
        );
        
        // Cache the result
        _speciesCache[taxaId] = animalData;
        return animalData;
      }
    } catch (e) {
      print('[ApiService] Error getting data for taxa $taxaId: $e');
    }
    
    return null;
  }

  /// Fast search for species by partial name match (using cached data)
  Future<List<AnimalData>> searchSpecies(String searchTerm) async {
    try {
      print('[ApiService] Fast searching for species with term: "$searchTerm"');
      
      // Get all species (cached after first call)
      final allSpecies = await _getAllSpecies();
      
      // Filter by search term (very fast - no API calls)
      final searchTermLower = searchTerm.toLowerCase().trim();
      final matchingSpecies = allSpecies
          .where((animal) => 
              animal.name.toLowerCase().contains(searchTermLower) || 
              animal.scientificName.toLowerCase().contains(searchTermLower))
          .take(10) // Limit to 10 results for performance
          .toList();
      
      print('[ApiService] Found ${matchingSpecies.length} matching species for "$searchTerm" (fast search)');
      return matchingSpecies;
      
    } catch (e) {
      print('[ApiService] Exception during fast species search: $e');
      throw Exception('Search Error: $e');
    }
  }

  /// Clear the species cache (useful for debugging or refreshing data)
  static void clearSpeciesCache() {
    _speciesCache.clear();
    _allSpeciesCache = null;
    print('[ApiService] Species cache cleared');
  }

  void dispose() {
    _client.close();
  }
}

