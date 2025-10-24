class AppConstants {
  // API Configuration
  static const String baseUrl = 'https://api.artdatabanken.se/v1';
  static const String taxonServiceUrl = 'https://api.artdatabanken.se/taxonservice/v1';
  static const String speciesDataServiceUrl = 'https://api.artdatabanken.se/information/v1/speciesdataservice/v1';
  
  // Taxon IDs
  static const int mammalTaxonId = 4000107;
  static const int speciesCategoryId = 17; // Category ID for individual species
  
  // API Headers
  static const Map<String, String> defaultHeaders = {
    'Cache-Control': 'no-cache',
  };
  
  // App Configuration
  static const String appName = 'WildGuess';
  static const String appVersion = '1.0.0';
}
