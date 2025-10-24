import 'dart:convert';
import 'package:http/http.dart' as http;

class ImageService {
  static final http.Client _client = http.Client();
  
  // Cache for image URLs to avoid repeated API calls
  static final Map<String, String> _imageCache = {};
  
  /// Get animal image URL from Wikimedia Commons
  static Future<String> getAnimalImageUrl(String scientificName, {String? swedishName}) async {
    if (scientificName.isEmpty) return '';
    
    // Check cache first
    final cacheKey = scientificName.toLowerCase();
    if (_imageCache.containsKey(cacheKey)) {
      print('[ImageService] Using cached image for $scientificName');
      return _imageCache[cacheKey]!;
    }
    
    print('[ImageService] Fetching image for $scientificName');
    
    try {
      // Try multiple search strategies
      final searchTerms = [
        scientificName,
        swedishName,
        _getCommonName(scientificName),
      ].where((term) => term != null && term.isNotEmpty).toList();
      
      for (final searchTerm in searchTerms) {
        final imageUrl = await _searchWikimediaCommons(searchTerm!);
        if (imageUrl.isNotEmpty) {
          _imageCache[cacheKey] = imageUrl;
          print('[ImageService] Found image for $scientificName: $imageUrl');
          return imageUrl;
        }
      }
      
      // If Wikimedia fails, try alternative strategies
      print('[ImageService] Wikimedia search failed, trying alternative strategies...');
      final alternativeUrl = await _tryAlternativeImageSearch(scientificName, swedishName);
      if (alternativeUrl.isNotEmpty) {
        _imageCache[cacheKey] = alternativeUrl;
        return alternativeUrl;
      }
      
      print('[ImageService] No image found for $scientificName');
      return '';
      
    } catch (e) {
      print('[ImageService] Error fetching image for $scientificName: $e');
      return '';
    }
  }
  
  /// Search Wikimedia Commons for animal images
  static Future<String> _searchWikimediaCommons(String searchTerm) async {
    try {
      // Try multiple search strategies with better quality focus
      final searchStrategies = [
        '$searchTerm portrait',
        '$searchTerm head shot',
        '$searchTerm close-up',
        '$searchTerm face',
        '$searchTerm animal portrait',
        '$searchTerm wildlife photography',
        '$searchTerm mammal',
        '$searchTerm animal',
        '$searchTerm',
      ];
      
      for (final strategy in searchStrategies) {
        final cleanTerm = strategy
            .replaceAll(RegExp(r'[^\w\s]'), '') // Remove special characters
            .trim();
        
        final uri = Uri.parse(
          'https://commons.wikimedia.org/w/api.php'
          '?action=query'
          '&format=json'
          '&list=search'
          '&srsearch=$cleanTerm'
          '&srnamespace=6' // Only search in File namespace
          '&srlimit=10' // Get more results
          '&srprop=size|timestamp'
        );
        
        final response = await _client.get(uri);
        
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final searchResults = data['query']?['search'] as List<dynamic>?;
          
          if (searchResults != null && searchResults.isNotEmpty) {
            // Score and rank images by relevance
            final scoredResults = <Map<String, dynamic>>[];
            
            for (final result in searchResults) {
              final title = result['title'] as String? ?? '';
              final size = result['size'] as int? ?? 0;
              
              // Skip if not an image file
              if (!title.toLowerCase().endsWith('.jpg') && 
                  !title.toLowerCase().endsWith('.jpeg') &&
                  !title.toLowerCase().endsWith('.png')) {
                continue;
              }
              
              // Skip obviously irrelevant images
              if (title.toLowerCase().contains('leaf') || 
                  title.toLowerCase().contains('tree') ||
                  title.toLowerCase().contains('branch') ||
                  title.toLowerCase().contains('landscape') ||
                  title.toLowerCase().contains('habitat') ||
                  title.toLowerCase().contains('environment')) {
                continue;
              }
              
              // Calculate relevance score with better quality focus
              int score = 0;
              
              // Higher score for exact matches
              if (title.toLowerCase().contains(searchTerm.toLowerCase())) {
                score += 100;
              }
              
              // Much higher score for portrait/head shots (better for identification)
              if (title.toLowerCase().contains('portrait') || 
                  title.toLowerCase().contains('head') ||
                  title.toLowerCase().contains('close-up') ||
                  title.toLowerCase().contains('face')) {
                score += 80;
              }
              
              // Very high score for images that clearly show the animal
              if (title.toLowerCase().contains('squirrel') || 
                  title.toLowerCase().contains('animal') ||
                  title.toLowerCase().contains('mammal') ||
                  title.toLowerCase().contains('wildlife')) {
                score += 70;
              }
              
              // Higher score for professional photography terms
              if (title.toLowerCase().contains('photography') || 
                  title.toLowerCase().contains('professional') ||
                  title.toLowerCase().contains('studio')) {
                score += 60;
              }
              
              // Higher score for animal-related terms
              if (title.toLowerCase().contains('animal') || 
                  title.toLowerCase().contains('wildlife') ||
                  title.toLowerCase().contains('mammal')) {
                score += 40;
              }
              
              // Much higher score for larger, high-quality images
              if (size > 500000) score += 50; // > 500KB
              if (size > 1000000) score += 40; // > 1MB
              if (size > 2000000) score += 30; // > 2MB
              if (size > 5000000) score += 20; // > 5MB
              
              // Prefer JPG over PNG for better quality
              if (title.toLowerCase().endsWith('.jpg') || 
                  title.toLowerCase().endsWith('.jpeg')) {
                score += 15;
              }
              
              // Penalize low-quality indicators
              if (title.toLowerCase().contains('blurry') || 
                  title.toLowerCase().contains('low-res') ||
                  title.toLowerCase().contains('small')) {
                score -= 50;
              }
              
              // Penalize very small images
              if (size < 50000) score -= 30; // < 50KB
              
              // Only include images with a minimum relevance score
              if (score < 50) {
                continue; // Skip low-relevance images
              }
              
              scoredResults.add({
                'title': title,
                'score': score,
                'size': size,
              });
            }
            
            // Sort by score (highest first)
            scoredResults.sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));
            
            // Try the best results
            print('[ImageService] Found ${scoredResults.length} scored results');
            for (int i = 0; i < scoredResults.take(5).length; i++) {
              final result = scoredResults[i];
              final title = result['title'] as String;
              final score = result['score'] as int;
              print('[ImageService] Result ${i+1}: Score $score - $title');
            }
            
            for (final result in scoredResults.take(3)) {
              final title = result['title'] as String;
              final score = result['score'] as int;
              final imageUrl = await _getImageUrl(title);
              if (imageUrl.isNotEmpty) {
                print('[ImageService] Selected image with score $score: $title');
                return imageUrl;
              }
            }
          }
        }
      }
      
      return '';
    } catch (e) {
      print('[ImageService] Wikimedia search error: $e');
      return '';
    }
  }
  
  /// Get the actual image URL from Wikimedia Commons
  static Future<String> _getImageUrl(String fileName) async {
    try {
      final uri = Uri.parse(
        'https://commons.wikimedia.org/w/api.php'
        '?action=query'
        '&format=json'
        '&titles=$fileName'
        '&prop=imageinfo'
        '&iiprop=url'
        '&iiurlwidth=800' // Get a reasonable size
      );
      
      final response = await _client.get(uri);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final pages = data['query']?['pages'] as Map<String, dynamic>?;
        
        if (pages != null) {
          for (final page in pages.values) {
            final imageInfo = page['imageinfo'] as List<dynamic>?;
            if (imageInfo != null && imageInfo.isNotEmpty) {
              final url = imageInfo.first['url'] as String?;
              if (url != null && url.isNotEmpty) {
                return url;
              }
            }
          }
        }
      }
      
      return '';
    } catch (e) {
      print('[ImageService] Error getting image URL: $e');
      return '';
    }
  }
  
  /// Get common name from scientific name for better search results
  static String? _getCommonName(String scientificName) {
    // Map some common Swedish mammals to English names for better search results
    final commonNames = {
      'Lepus timidus': 'mountain hare',
      'Lepus europaeus': 'brown hare',
      'Lynx lynx': 'eurasian lynx',
      'Canis lupus': 'gray wolf',
      'Ursus arctos': 'brown bear',
      'Vulpes vulpes': 'red fox',
      'Alces alces': 'moose',
      'Capreolus capreolus': 'roe deer',
      'Cervus elaphus': 'red deer',
      'Sus scrofa': 'wild boar',
      'Martes martes': 'pine marten',
      'Mustela erminea': 'stoat',
      'Mustela nivalis': 'least weasel',
      'Meles meles': 'european badger',
      'Lutra lutra': 'eurasian otter',
      'Castor fiber': 'eurasian beaver',
      'Sciurus vulgaris': 'red squirrel',
      'Glis glis': 'edible dormouse',
      'Myocastor coypus': 'nutria',
      'Ondatra zibethicus': 'muskrat',
      'Rangifer tarandus': 'reindeer',
      'Phoca vitulina': 'harbor seal',
      'Halichoerus grypus': 'gray seal',
      'Erinaceus europaeus': 'european hedgehog',
      'Talpa europaea': 'european mole',
      'Sorex araneus': 'common shrew',
      'Neomys fodiens': 'water shrew',
      'Crocidura leucodon': 'bicolored shrew',
      'Sorex minutus': 'pygmy shrew',
    };
    
    return commonNames[scientificName];
  }
  

  /// Try alternative image search strategies
  static Future<String> _tryAlternativeImageSearch(String scientificName, String? swedishName) async {
    try {
      // Try searching with just the genus name + quality terms
      final genus = scientificName.split(' ').first;
      final genusSearches = [
        '$genus portrait',
        '$genus head',
        '$genus close-up',
        '$genus animal',
        genus,
      ];
      
      for (final search in genusSearches) {
        final url = await _searchWikimediaCommons(search);
        if (url.isNotEmpty) {
          print('[ImageService] Found genus-based image: $url');
          return url;
        }
      }
      
      // Try with common name + quality terms
      final commonName = _getCommonName(scientificName);
      if (commonName != null) {
        final commonSearches = [
          '$commonName portrait',
          '$commonName head',
          '$commonName close-up',
          '$commonName animal',
          commonName,
        ];
        
        for (final search in commonSearches) {
          final url = await _searchWikimediaCommons(search);
          if (url.isNotEmpty) {
            print('[ImageService] Found common name image: $url');
            return url;
          }
        }
      }
      
      // Try with Swedish name + quality terms
      if (swedishName != null && swedishName.isNotEmpty) {
        final swedishSearches = [
          '$swedishName portrait',
          '$swedishName huvud',
          '$swedishName närbild',
          '$swedishName djur',
          swedishName,
        ];
        
        for (final search in swedishSearches) {
          final url = await _searchWikimediaCommons(search);
          if (url.isNotEmpty) {
            print('[ImageService] Found Swedish name image: $url');
            return url;
          }
        }
      }
      
      return '';
    } catch (e) {
      print('[ImageService] Alternative search error: $e');
      return '';
    }
  }

  /// Get fallback image path for local assets
  static String getFallbackImagePath(String scientificName) {
    // Map to local asset paths
    final assetMap = {
      'Lepus timidus': 'assets/images/skogshare.jpg',
      'Lepus europaeus': 'assets/images/falthare.jpg',
      'Lynx lynx': 'assets/images/lodjur.jpg',
      'Canis lupus': 'assets/images/varg.jpg',
      'Vulpes vulpes': 'assets/images/radrav.jpg',
      'Alces alces': 'assets/images/alg.jpg',
      'Capreolus capreolus': 'assets/images/radjur.jpg',
      'Cervus elaphus': 'assets/images/kronhjort.jpg',
      'Sus scrofa': 'assets/images/vildsvin.jpg',
      'Martes martes': 'assets/images/iller.jpg',
      'Mustela erminea': 'assets/images/hermelin.jpg',
      'Mustela nivalis': 'assets/images/vanlig_weasel.jpg',
      'Meles meles': 'assets/images/gronvarg.jpg',
      'Lutra lutra': 'assets/images/utter.jpg',
      'Castor fiber': 'assets/images/bavar.jpg',
      'Sciurus vulgaris': 'assets/images/ekorre.jpg',
    };
    
    return assetMap[scientificName] ?? 'assets/images/default_animal.jpg';
  }
  
  /// Clear image cache
  static void clearCache() {
    _imageCache.clear();
    print('[ImageService] Image cache cleared');
  }
  
  /// Dispose resources
  static void dispose() {
    _client.close();
  }
}
