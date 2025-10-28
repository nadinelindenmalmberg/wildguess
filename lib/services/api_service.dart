import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;

import '../core/constants.dart';
import '../models/animal_data.dart';
import '../models/taxon_response.dart';
import '../models/species_data.dart';
import 'image_service.dart';
import 'statistics_service.dart';


class ApiService {
  
  // Build-time injected subscription keys
  static const String taxonSubscriptionKey = String.fromEnvironment('TAXON_SUBSCRIPTION_KEY');
  static const String speciesSubscriptionKey = String.fromEnvironment('SPECIES_SUBSCRIPTION_KEY');
  
  final http.Client _client;
  
  // Cache for species data to avoid repeated API calls
  static final Map<int, AnimalData> _speciesCache = {};
  static List<AnimalData>? _allSpeciesCache;
  static bool? _lastLanguageUsed; // Track last language used for cache

  ApiService({http.Client? client}) : _client = client ?? http.Client();

  /// Get today's animal (same for all players in production, random in test mode)
  Future<AnimalData> getRandomAnimal({bool isEnglish = false}) async {
    // Check if we're in test mode
    final isTestMode = await _isTestMode();
    print('[ApiService] Test mode check: $isTestMode');
    
    if (isTestMode) {
      // Test mode: return random animal
      print('[ApiService] Using test mode - returning random animal');
      try {
        return await getRandomAnimalFromAPI();
      } catch (e) {
        print('[ApiService] API failed, using test animals: $e');
        return _getTestAnimal(isEnglish: isEnglish);
      }
    } else {
      // Production mode: return today's animal (same for all players)
      print('[ApiService] Using production mode - returning today\'s animal');
      return await _getTodaysAnimal(isEnglish: isEnglish);
    }
  }

  /// Check if we're in test mode by looking at testingMode from statistics service
  Future<bool> _isTestMode() async {
    try {
      // Access the global testingMode variable from statistics_service.dart
      print('[ApiService] Current testingMode value: $testingMode');
      return testingMode;
    } catch (e) {
      print('[ApiService] Error accessing testingMode: $e');
      return false;
    }
  }

  /// Get today's animal (same for all players)
  Future<AnimalData> _getTodaysAnimal({bool isEnglish = false}) async {
    final today = DateTime.now();
    final dayKey = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    
    // For now, use a simple hash-based selection to ensure same animal per day
    final dayHash = dayKey.hashCode;
    final random = math.Random(dayHash);
    
    try {
      final allSpecies = await _getAllSpecies(isEnglish: isEnglish);
      if (allSpecies.isNotEmpty) {
        final selectedAnimal = allSpecies[random.nextInt(allSpecies.length)];
        print('[ApiService] Today\'s animal (${dayKey}): ${selectedAnimal.name}');
        
        // Ensure image is loaded for the selected animal
        return await _ensureImageLoaded(selectedAnimal);
      } else {
        throw Exception('No species available');
      }
    } catch (e) {
      print('[ApiService] Failed to get today\'s animal, using test animal: $e');
      return _getTestAnimal(isEnglish: isEnglish);
    }
  }

  /// Ensure image is loaded for an animal (lazy loading)
  Future<AnimalData> _ensureImageLoaded(AnimalData animal) async {
    // If animal already has an image, return it
    if (animal.imageUrl.isNotEmpty) {
      return animal;
    }
    
    try {
      print('[ApiService] Fetching image for ${animal.name} (${animal.scientificName})');
      final imageUrl = await ImageService.getAnimalImageUrl(
        animal.scientificName, 
        swedishName: animal.name
      );
      
      if (imageUrl.isNotEmpty) {
        // Update the cached animal data with the image URL
        final updatedAnimal = AnimalData(
          name: animal.name,
          scientificName: animal.scientificName,
          description: animal.description,
          hints: animal.hints,
          imageUrl: imageUrl,
        );
        
        // Update cache if this animal is cached
        for (final entry in _speciesCache.entries) {
          if (entry.value.name == animal.name && entry.value.scientificName == animal.scientificName) {
            _speciesCache[entry.key] = updatedAnimal;
            break;
          }
        }
        
        return updatedAnimal;
      }
    } catch (e) {
      print('[ApiService] Error loading image for ${animal.name}: $e');
    }
    
    return animal; // Return original animal if image loading fails
  }

  /// Get a test animal when API is unavailable
  AnimalData _getTestAnimal({bool isEnglish = false}) {
    print('[ApiService] Using test animal fallback');
    final testAnimals = [
      AnimalData(
        name: isEnglish ? 'Wolf' : 'varg',
        scientificName: 'Canis lupus',
        description: isEnglish 
          ? 'The wolf is a predator that lives in packs and hunts together.'
          : 'Vargen är ett rovdjur som lever i flockar och jagar tillsammans.',
        hints: isEnglish ? [
          'This animal lives in packs and hunts together',
          'It has sharp teeth and is a predator',
          'It can howl and communicate over long distances',
          'It is known for its intelligence and social structure',
          'It is Sweden\'s largest predator'
        ] : [
          'Detta djur lever i flockar och jagar tillsammans',
          'Det har vassa tänder och är ett rovdjur',
          'Det kan yla och kommunicera över långa avstånd',
          'Det är känd för sin intelligens och sociala struktur',
          'Det är Sveriges största rovdjur'
        ],
        imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/5/5a/Canis_lupus_laying_in_grass.jpg/800px-Canis_lupus_laying_in_grass.jpg',
      ),
      AnimalData(
        name: isEnglish ? 'Moose' : 'älg',
        scientificName: 'Alces alces',
        description: isEnglish 
          ? 'The moose is Sweden\'s largest deer and lives in forests.'
          : 'Älgen är Sveriges största hjortdjur och lever i skogar.',
        hints: isEnglish ? [
          'This animal is Sweden\'s largest deer',
          'It has large antlers that it sheds every year',
          'It lives in forests and eats plants',
          'It can be dangerous to meet on the road',
          'It is a very large animal with long legs'
        ] : [
          'Detta djur är Sveriges största hjortdjur',
          'Det har stora horn som den kastar varje år',
          'Det lever i skogar och äter växter',
          'Det kan vara farligt att möta på vägen',
          'Det är ett mycket stort djur med långa ben'
        ],
        imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/8/8a/Moose_superior.jpg/800px-Moose_superior.jpg',
      ),
      AnimalData(
        name: isEnglish ? 'Fox' : 'räv',
        scientificName: 'Vulpes vulpes',
        description: isEnglish 
          ? 'The fox is a nimble predator that lives in forests and open fields.'
          : 'Räven är en smidig rovdjur som lever i skogar och på öppna fält.',
        hints: isEnglish ? [
          'This animal has a bushy tail',
          'It is known for its cunning',
          'It has red-brown fur and pointed ears',
          'It hunts small animals and also eats berries',
          'It is a nimble predator'
        ] : [
          'Detta djur har en buskig svans',
          'Det är känd för sin listighet',
          'Det har rödbrun päls och spetsiga öron',
          'Det jagar smådjur och äter även bär',
          'Det är ett smidigt rovdjur'
        ],
        imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/1/16/Fox_-_British_Wildlife_Centre_%2817429406401%29.jpg/800px-Fox_-_British_Wildlife_Centre_%2817429406401%29.jpg',
      ),
    ];
    
    final random = math.Random();
    final selectedAnimal = testAnimals[random.nextInt(testAnimals.length)];
    print('[ApiService] Selected test animal: ${selectedAnimal.name}');
    return selectedAnimal;
  }


  Future<AnimalData> getRandomAnimalFromAPI() async {
    try {
      // First, get all mammal species from the taxon endpoint
      print('[ApiService] Fetching mammal species list...');
      print('[ApiService] Taxon key present: ${taxonSubscriptionKey.isNotEmpty}');
      print('[ApiService] Taxon key length: ${taxonSubscriptionKey.length}');
      
       // Use the filteredSelected endpoint to get only species (category.id == 17)
       print('[ApiService] Getting mammal species from taxonId ${AppConstants.mammalTaxonId}...');
       final mammalListUri = Uri.parse(
         '${AppConstants.taxonServiceUrl}/taxa/${AppConstants.mammalTaxonId}/filteredSelected?taxonCategories=17&onlyMainChildren=false',
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
      
      // Parse the response - should be a list of taxon objects (already filtered by server)
      List<Map<String, dynamic>> taxonObjects = [];
      
      if (responseData is List) {
        taxonObjects = responseData.cast<Map<String, dynamic>>();
        print('[ApiService] Found ${taxonObjects.length} species from filteredSelected endpoint (server-filtered by taxonCategories=17)');
      } else if (responseData is Map && responseData['children'] is List) {
        taxonObjects = (responseData['children'] as List).cast<Map<String, dynamic>>();
        print('[ApiService] Found ${taxonObjects.length} species from filteredSelected endpoint (server-filtered by taxonCategories=17)');
      } else {
        throw Exception('Unexpected API response structure: ${responseData.runtimeType}');
      }
      
      // Extract taxon IDs from taxon objects (filter out null values)
      final taxonIds = taxonObjects
          .map((taxon) => taxon['id'] as int?)
          .where((id) => id != null)
          .cast<int>()
          .toList();
      
      // No manual exclusions needed - server already filters by taxonCategories=17
      if (taxonIds.isEmpty) {
        throw Exception('No mammal species found (server returned 0 taxa with taxonCategories=17)');
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
          print('[ApiService] === END EXTRACTED DATA ===');
          
          final animalData = AnimalData(
            name: name.isNotEmpty ? name : 'Taxon $taxaId',
            scientificName: sci,
            description: desc,
            hints: hints.isNotEmpty ? hints : ['Ingen ledtråd tillgänglig'],
            imageUrl: '', // Will be loaded by _ensureImageLoaded
          );
          
          // Ensure image is loaded
          return await _ensureImageLoaded(animalData);
        }
      }

      throw Exception('No data found for selected mammal species');
    } catch (e) {
      print('[ApiService] Exception during API call: $e');
      throw Exception('API Error: $e');
    }
  }


  /// Get all species data once and cache it for fast searching
  Future<List<AnimalData>> _getAllSpecies({bool isEnglish = false}) async {
    // Clear cache if language changed
    if (_lastLanguageUsed != null && _lastLanguageUsed != isEnglish) {
      print('[ApiService] Language changed, clearing cache');
      _allSpeciesCache = null;
      _speciesCache.clear();
    }
    
    if (_allSpeciesCache != null) {
      print('[ApiService] Using cached species data');
      return _allSpeciesCache!;
    }
    
    print('[ApiService] Loading all species data for the first time...');
    
    try {
       // Get all mammal species first (using the same endpoint as random animal)
       final culture = isEnglish ? 'en_GB' : 'sv_SE';
       final mammalListUri = Uri.parse(
         '${AppConstants.taxonServiceUrl}/taxa/${AppConstants.mammalTaxonId}/filteredSelected?taxonCategories=17&onlyMainChildren=false&culture=$culture',
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
      List<Map<String, dynamic>> taxonObjects = [];
      
      if (responseData is List) {
        taxonObjects = responseData.cast<Map<String, dynamic>>();
      } else if (responseData is Map && responseData['children'] is List) {
        taxonObjects = (responseData['children'] as List).cast<Map<String, dynamic>>();
      }
      
      print('[ApiService] Found ${taxonObjects.length} species from server (server-filtered by taxonCategories=17)');
      
      // Extract taxon IDs from taxon objects (filter out null values)
      final taxonIds = taxonObjects
          .map((taxon) => taxon['id'] as int?)
          .where((id) => id != null)
          .cast<int>()
          .toList();
      
      // No manual exclusions needed - server already filters by taxonCategories=17
      
      // Load all species data in parallel (much faster)
      final futures = taxonIds.map((taxaId) => _getSpeciesData(taxaId, isEnglish: isEnglish));
      final results = await Future.wait(futures, eagerError: false);
      
      // Filter out null results and ensure we only have species
      final allAnimals = results
          .where((animal) => animal != null)
          .cast<AnimalData>()
          .toList();
      
      // All animals are already filtered for species at API level (taxonCategories=17)
      final allSpecies = allAnimals;
      
      _allSpeciesCache = allSpecies;
      _lastLanguageUsed = isEnglish; // Track the language used for this cache
      
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
  Future<AnimalData?> _getSpeciesData(int taxaId, {bool isEnglish = false}) async {
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

        // Get the name based on culture (API will return English or Swedish based on culture parameter)
        final String displayName = (speciesData?['swedishName'] ?? first?['swedishName'] ?? first?['name'] ?? '')
            .toString();
        final String sci = (speciesData?['scientificName'] ?? first?['scientificName'] ?? '')
            .toString();

        // Extract additional data
        final Map<String, dynamic>? speciesFactText = speciesData?['speciesFactText'];
        final String ecology = (speciesFactText?['ecology'] ?? '').toString();
        final String characteristic = (speciesFactText?['characteristic'] ?? '').toString();
        
        // Create basic hints based on language
        final List<String> hints = <String>[];
        if (displayName.isNotEmpty) {
          hints.add(isEnglish ? 'Name: $displayName' : 'Svenskt namn: $displayName');
        }
        if (sci.isNotEmpty) {
          hints.add(isEnglish ? 'Scientific name: $sci' : 'Vetenskapligt namn: $sci');
        }
        if (ecology.isNotEmpty) {
          final ecologySnippet = ecology.length > 100 
              ? ecology.substring(0, 100) + '...'
              : ecology;
          hints.add(isEnglish ? 'Ecology: $ecologySnippet' : 'Ekologi: $ecologySnippet');
        }
        
        // Don't fetch images during bulk loading - do it lazily when needed
        final animalData = AnimalData(
          name: displayName.isNotEmpty ? displayName : 'Taxon $taxaId',
          scientificName: sci,
          description: characteristic.isNotEmpty ? characteristic : '',
          hints: hints.isNotEmpty ? hints : [isEnglish ? 'No information available' : 'Ingen information tillgänglig'],
          imageUrl: '', // Will be fetched when needed
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
  Future<List<AnimalData>> searchSpecies(String searchTerm, {bool isEnglish = false}) async {
    try {
      print('[ApiService] Fast searching for species with term: "$searchTerm"');
      
      // Get all species (cached after first call)
      final allSpecies = await _getAllSpecies(isEnglish: isEnglish);
      
      // Filter by search term (very fast - no API calls)
      final searchTermLower = searchTerm.toLowerCase().trim();
      
      // Create comprehensive English name mappings for Swedish animals
      final englishNames = {
        'igelkott': 'hedgehog',
        'piggsvin': 'hedgehog',
        'lodjur': 'lynx',
        'lo': 'lynx',
        'varg': 'wolf',
        'ulv': 'wolf',
        'björn': 'bear',
        'brunbjörn': 'brown bear',
        'isbjörn': 'polar bear',
        'räv': 'fox',
        'rödräv': 'red fox',
        'fjällräv': 'arctic fox',
        'älg': 'moose',
        'hjort': 'deer',
        'kronhjort': 'red deer',
        'rådjur': 'roe deer',
        'dovhjort': 'fallow deer',
        'ren': 'reindeer',
        'hare': 'hare',
        'skogshare': 'mountain hare',
        'fälthare': 'brown hare',
        'ekorre': 'squirrel',
        'rödekorre': 'red squirrel',
        'utter': 'otter',
        'bäver': 'beaver',
        'iller': 'marten',
        'hermelin': 'stoat',
        'vessla': 'weasel',
        'grävling': 'badger',
        'vildsvin': 'wild boar',
        'gris': 'pig',
        'svin': 'pig',
        'tumlare': 'harbour porpoise',
        'gråsäl': 'grey seal',
        'knubbsäl': 'harbour seal',
        'ringed seal': 'ringed seal',
        'val': 'whale',
        'delfin': 'dolphin',
        'fladdermus': 'bat',
        'näbbmus': 'shrew',
        'mullvad': 'mole',
      };
      
      final matchingSpecies = allSpecies
          .where((animal) {
            final swedishName = animal.name.toLowerCase();
            final scientificName = animal.scientificName.toLowerCase();
            
            // Direct matches (Swedish names and scientific names)
            if (swedishName.contains(searchTermLower) || 
                scientificName.contains(searchTermLower)) {
              return true;
            }
            
            // If searching in English mode, prioritize English name matches
            if (isEnglish) {
              // Direct English name lookup
              final englishName = englishNames[searchTermLower];
              if (englishName != null) {
                if (swedishName.contains(englishName) || 
                    scientificName.contains(englishName)) {
                  return true;
                }
              }
              
              // Reverse lookup - if searching for English name, find Swedish
              for (final entry in englishNames.entries) {
                if (entry.value.toLowerCase().contains(searchTermLower)) {
                  if (swedishName.contains(entry.key)) {
                    return true;
                  }
                }
              }
              
              // Also search for partial English matches
              for (final entry in englishNames.entries) {
                if (entry.value.toLowerCase().contains(searchTermLower) ||
                    searchTermLower.contains(entry.value.toLowerCase())) {
                  if (swedishName.contains(entry.key)) {
                    return true;
                  }
                }
              }
            } else {
              // Swedish mode - use existing logic
              final englishName = englishNames[searchTermLower];
              if (englishName != null) {
                if (swedishName.contains(englishName) || 
                    scientificName.contains(englishName)) {
                  return true;
                }
              }
              
              // Reverse lookup - if searching for English name, find Swedish
              for (final entry in englishNames.entries) {
                if (entry.value.toLowerCase().contains(searchTermLower)) {
                  if (swedishName.contains(entry.key)) {
                    return true;
                  }
                }
              }
            }
            
            return false;
          })
          .take(10) // Limit to 10 results for performance
          .toList();
      
      print('[ApiService] Found ${matchingSpecies.length} matching species for "$searchTerm" (fast search)');
      
      // Debug: Show what species are available for debugging
      if (matchingSpecies.isEmpty && searchTermLower == 'igelkott') {
        print('[ApiService] DEBUG: No results for "igelkott". Available species:');
        for (int i = 0; i < math.min(10, allSpecies.length); i++) {
          final species = allSpecies[i];
          print('[ApiService] - ${species.name} (${species.scientificName})');
        }
      }
      
      return matchingSpecies;
      
    } catch (e) {
      print('[ApiService] Exception during fast species search: $e');
      throw Exception('Search Error: $e');
    }
  }

  /// Fetch image URL for a specific animal (lazy loading)
  Future<String> fetchAnimalImage(AnimalData animal) async {
    if (animal.imageUrl.isNotEmpty) {
      return animal.imageUrl; // Already has image
    }
    
    try {
      print('[ApiService] Fetching image for ${animal.name} (${animal.scientificName})');
      final imageUrl = await ImageService.getAnimalImageUrl(
        animal.scientificName, 
        swedishName: animal.name
      );
      
      if (imageUrl.isNotEmpty) {
        // Update the cached animal data with the image URL
        final updatedAnimal = AnimalData(
          name: animal.name,
          scientificName: animal.scientificName,
          description: animal.description,
          hints: animal.hints,
          imageUrl: imageUrl,
        );
        
        // Update cache
        for (final entry in _speciesCache.entries) {
          if (entry.value.name == animal.name) {
            _speciesCache[entry.key] = updatedAnimal;
            break;
          }
        }
        
        // Update all species cache
        if (_allSpeciesCache != null) {
          for (int i = 0; i < _allSpeciesCache!.length; i++) {
            if (_allSpeciesCache![i].name == animal.name) {
              _allSpeciesCache![i] = updatedAnimal;
              break;
            }
          }
        }
        
        print('[ApiService] Image fetched for ${animal.name}: ${imageUrl.isNotEmpty ? "Found" : "Not found"}');
        return imageUrl;
      }
      
      return '';
    } catch (e) {
      print('[ApiService] Error fetching image for ${animal.name}: $e');
      return '';
    }
  }




  /// Clear the species cache (useful for debugging or refreshing data)
  static void clearSpeciesCache() {
    _speciesCache.clear();
    _allSpeciesCache = null;
    _lastLanguageUsed = null;
    print('[ApiService] Species cache cleared');
  }

  void dispose() {
    _client.close();
  }
}

