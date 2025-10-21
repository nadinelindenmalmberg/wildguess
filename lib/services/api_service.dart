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
      print('[ApiService] Getting mammal species from taxonId ${AppConstants.mammalTaxonId}...');
      final mammalListUri = Uri.parse(
        '${AppConstants.taxonServiceUrl}/taxa/${AppConstants.mammalTaxonId}/childids?useMainChildren=false',
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
      
      // Parse the response using our model
      final taxonResponse = TaxonResponse.fromJson(responseData);
      final mammalList = taxonResponse.taxonIds;
      
      if (mammalList.isEmpty) {
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

