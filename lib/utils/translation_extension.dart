import 'dart:convert';
import 'package:http/http.dart' as http;

/// Extension to add translation functionality to String
extension TranslationExtension on String {
  /// Translates Swedish text to English using a free translation API
  Future<String> translateToEnglish() async {
    try {
      // Using MyMemory API (free translation service)
      final url = Uri.parse(
          'https://api.mymemory.translated.net/get?q=${Uri.encodeComponent(this)}&langpair=sv|en');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final translatedText =
            data['responseData']['translatedText'] as String?;

        if (translatedText != null && translatedText.isNotEmpty) {
          return translatedText;
        }
      }

      // Fallback: return original text if translation fails
      return this;
    } catch (e) {
      // If translation fails, return original text
      return this;
    }
  }

  /// Simple offline translation for common Swedish words
  String translateOffline() {
    final translations = {
      'Dagens Djur': 'Today\'s Animal',
      'Gissa vilket djur det är!': 'Guess which animal it is!',
      'Starta Spel': 'Start Game',
      'Gissa Djuret': 'Guess the Animal',
      'Ledtrådar:': 'Hints:',
      'Visa Ledtråd': 'Show Hint',
      'Alla ledtrådar visade': 'All hints shown',
      'Din gissning': 'Your guess',
      'Gissa': 'Guess',
      'Grattis!': 'Congratulations!',
      'Rätt!': 'Correct!',
      'Det var en': 'It was a',
      'Tillbaka': 'Back',
      'Tyvärr': 'Sorry',
      'Fel!': 'Wrong!',
      'Rätt svar var:': 'Correct answer was:',
      'Älg': 'Moose',
      'Rödräv': 'Red Fox',
      'Brunbjörn': 'Brown Bear',
      'Varg': 'Wolf',
      'Kungsörn': 'Golden Eagle',
      'Vitval': 'White Whale',
      'Lodjur': 'Lynx',
      'Rådjur': 'Roe Deer',
      'Kronhjort': 'Red Deer',
      'Hare': 'Hare',
      'Ekorre': 'Squirrel',
      'Utter': 'Otter',
      'Bäver': 'Beaver',
      'Iller': 'Pine Marten',
      'Hermelin': 'Stoat',
      'Vessla': 'Weasel',
      'Grävling': 'Badger',
      'Igelkott': 'Hedgehog',
      'Mullvad': 'Mole',
      'Nordens största hjortdjur': 'Northern Europe\'s largest deer',
      'karakteristiska horn som formar en skopa':
          'characteristic antlers that form a scoop',
      'lever i skogar och myrar': 'lives in forests and marshes',
      'växtätare som äter blad och bark': 'herbivore that eats leaves and bark',
      'kan väga upp till 700kg': 'can weigh up to 700kg',
      'karakteristisk rödbrun päls': 'characteristic reddish-brown fur',
      'rovdjur som jagar små däggdjur': 'predator that hunts small mammals',
      'kan anpassa sig till olika miljöer':
          'can adapt to different environments',
      'buskig svans': 'bushy tail',
      'aktivt både dag och natt': 'active both day and night',
      'Sveriges största rovdjur': 'Sweden\'s largest predator',
      'kraftig kropp och tjock päls': 'strong body and thick fur',
      'lever i skogar i norra Sverige': 'lives in forests in northern Sweden',
      'allätare och äter bär, fisk och små djur':
          'omnivore that eats berries, fish and small animals',
      'går i ide under vintern': 'hibernates during winter',
      'lever i flockar': 'lives in packs',
      'rovdjur som jagar i grupp': 'predator that hunts in groups',
      'karakteristisk ylande': 'characteristic howling',
      'nära släkt med hundar': 'closely related to dogs',
      'Europas största rovfåglar': 'Europe\'s largest birds of prey',
      'imponerande vingspann': 'impressive wingspan',
      'jagar små däggdjur och fåglar': 'hunts small mammals and birds',
      'bygger stora bon i träd eller på klippor':
          'builds large nests in trees or on cliffs',
      'skarpa klor och näbb': 'sharp claws and beak',
    };

    return translations[this] ?? this;
  }

  /// Get translated animal name based on language preference
  String getTranslatedAnimalName(bool isEnglish) {
    if (isEnglish) {
      return translateOffline();
    }
    return this;
  }
}
