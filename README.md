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
- **Multi-language** - Swedish/English support
- **Cross-Platform** - Works on iOS, Android, Web, and macOS
- **Daily Animals** - Different animal each day

## 🏗️ Project Structure

```
wildguess/
├── lib/
│   ├── main.dart              # Main app code
│   ├── api_service.dart       # ArtDatabanken API integration
│   └── translation_extension.dart
├── pubspec.yaml              # Dependencies
├── taxon_key.txt             # ArtDatabanken taxon service key (gitignored)
├── species_key.txt           # ArtDatabanken species data key (gitignored)
└── README.md                 # This file
```

## 🔐 API Keys

The app uses two ArtDatabanken API keys stored in `api_keys.json`:
- `TAXON_SUBSCRIPTION_KEY` - For getting mammal species list
- `SPECIES_SUBSCRIPTION_KEY` - For getting detailed animal data

The `api_keys.json` file is gitignored for security. Create it with your keys:

```json
{
  "TAXON_SUBSCRIPTION_KEY": "your_taxon_key_here",
  "SPECIES_SUBSCRIPTION_KEY": "your_species_key_here"
}
```

## 🔧 Development

### Adding More Animals
The app automatically fetches real mammal data from ArtDatabanken, so no manual animal additions needed!

### API Integration
- **Taxon Service** - Gets list of 104 Swedish mammal species
- **Species Data Service** - Gets detailed information and red list data
- **Random Selection** - Picks a different mammal each time

### Translation
Edit `lib/translation_extension.dart` to add more languages.

## 📱 Screens

1. **Home Screen** - Welcome and start game
2. **Game Screen** - Show hints and accept guesses  
3. **Result Screen** - Win/lose feedback

## 🌐 Supported Platforms

- **iOS** - Native iOS app
- **Android** - Native Android app
- **Web** - Progressive Web App
- **macOS** - Desktop application

## 📝 License

This project is for educational purposes.