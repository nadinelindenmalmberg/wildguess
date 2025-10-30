# Wild Guess - Animal Guessing Game

A Flutter app that challenges players to guess Swedish animals using progressive hints from the ArtDatabanken API.

## 🎮 How to Play

1. **Start the game** from the home screen
2. **Get hints** one by one about today's animal
3. **Guess the animal** based on the clues
4. **Win or lose** and try again!

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (3.10.0 or higher)
- iOS Simulator, Android Emulator, or Web Browser

### Running the App

```bash
# Get dependencies
flutter pub get

# Run with API keys (required)
flutter run --dart-define=TAXON_SUBSCRIPTION_KEY=your_taxon_key --dart-define=SPECIES_SUBSCRIPTION_KEY=your_species_key -d chrome          # Web
flutter run --dart-define=TAXON_SUBSCRIPTION_KEY=your_taxon_key --dart-define=SPECIES_SUBSCRIPTION_KEY=your_species_key -d macos           # macOS
flutter run --dart-define=TAXON_SUBSCRIPTION_KEY=your_taxon_key --dart-define=SPECIES_SUBSCRIPTION_KEY=your_species_key -d "iPhone 16"     # iOS Simulator
flutter run --dart-define=TAXON_SUBSCRIPTION_KEY=your_taxon_key --dart-define=SPECIES_SUBSCRIPTION_KEY=your_species_key -d android         # Android
```

## 📱 Features

- **Real Animal Data** - Uses ArtDatabanken API for Swedish mammals
- **Progressive Hints** - Get clues one by one
- **Multi-language** - Swedish/English support (names translated when English is active)
- **High‑quality Images** - Fetched fresh from Wikimedia Commons (no caching) with English‑first search and quality scoring
- **Daily Animals** - Different animal each day
- **Global Stats** - Daily hint distribution and success rates from Supabase `daily_scores`
- **History** - History tab renders only animals from database (`daily_scores`), not local cache
- **Cross‑Platform** - iOS, Android, Web, and macOS

## 🔐 API Keys

The app reads keys from dart‑defines (recommended) or a local `.env` via helper script. Required keys:
- `TAXON_SUBSCRIPTION_KEY` – Mammal species list
- `SPECIES_SUBSCRIPTION_KEY` – Detailed species data

Use the helper scripts:

```bash
./setup_keys.sh    # creates .env from env.example
# edit .env with your keys
./run_ios.sh       # runs with dart-defines on iOS simulator
```

## 🔧 Development

### Adding More Animals
The app automatically fetches real mammal data from ArtDatabanken, so no manual animal additions needed!

### API Integration
- **Taxon Service** - Gets list of Swedish mammal species
- **Species Data Service** - Detailed information and red list data
- **Image Service** - Wikimedia Commons with English‑first terms, scoring, and caching disabled
- **Statistics Service** - Reads global daily stats from Supabase `daily_scores` (and aggregates from `aggregate_stats`)

### Translation
Edit `lib/translation_extension.dart` to add more languages.

## 📱 Screens

1. **Home Screen** - Welcome and start game
2. **Game Screen** - Show hints and accept guesses  
3. **Result Screen** - Win/lose feedback with global stats (no score box, no description)
4. **History Screen** - Shows games from Supabase `daily_scores` only

## 🤖 AI Clue Server

Optional Node/Express service that generates 5 clues via OpenAI.
See: [ai-clue-server/README.md](ai-clue-server/README.md).

## 🌐 Supported Platforms

- **iOS** - Native iOS app
- **Android** - Native Android app
- **Web** - Progressive Web App
- **macOS** - Desktop application

## 📝 License

This project is for educational purposes.