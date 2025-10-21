# Flutter Project Structure

This document describes the recommended folder structure for the WildGuess Flutter application.

## 📁 Folder Structure

```
lib/
├── main.dart                 # App entry point
├── core/                     # Core application files
│   ├── constants.dart        # App constants and configuration
│   └── theme.dart           # App theme and styling
├── services/                # API and external services
│   └── api_service.dart     # ArtDatabanken API integration
├── models/                  # Data models
│   ├── animal_data.dart     # Animal data model
│   ├── taxon_response.dart  # Taxon API response model
│   └── species_data.dart    # Species data model
├── screens/                 # UI screens/pages
│   └── home_screen.dart     # Main home screen
├── widgets/                 # Reusable UI components
│   ├── loading_widget.dart  # Loading indicator
│   └── error_widget.dart    # Error display widget
└── utils/                   # Utility functions
    └── translation_extension.dart # Translation utilities
```

## 🎯 Benefits of This Structure

### 1. **Separation of Concerns**
- **Core**: Configuration and theming
- **Services**: External API integrations
- **Models**: Data structures and serialization
- **Screens**: UI pages and navigation
- **Widgets**: Reusable components
- **Utils**: Helper functions and extensions

### 2. **Scalability**
- Easy to add new features without cluttering
- Clear boundaries between different types of code
- Simple to locate and modify specific functionality

### 3. **Team Collaboration**
- Multiple developers can work on different folders simultaneously
- Clear ownership of different parts of the codebase
- Reduced merge conflicts

### 4. **Maintainability**
- Easy to find and update specific functionality
- Clear import paths make dependencies obvious
- Consistent organization across the project

## 🚀 Getting Started

### Running the App

```bash
# With API keys
flutter run --dart-define=TAXON_SUBSCRIPTION_KEY=your_taxon_key --dart-define=SPECIES_SUBSCRIPTION_KEY=your_species_key

# Or use the provided script
./run_ios.sh
```

### Adding New Features

1. **New API endpoints**: Add to `services/`
2. **New data models**: Add to `models/`
3. **New screens**: Add to `screens/`
4. **Reusable components**: Add to `widgets/`
5. **Helper functions**: Add to `utils/`

## 📝 Best Practices

### Import Organization
```dart
// 1. Dart/Flutter imports
import 'package:flutter/material.dart';

// 2. Third-party packages
import 'package:http/http.dart' as http;

// 3. Local imports (core first, then others)
import '../core/constants.dart';
import '../models/animal_data.dart';
import '../services/api_service.dart';
```

### File Naming
- Use `snake_case` for file names
- Use descriptive names that indicate purpose
- Group related files in appropriate folders

### Code Organization
- Keep files focused on a single responsibility
- Use clear, descriptive class and method names
- Add documentation for complex logic

## 🔄 Migration from Old Structure

The project has been migrated from a flat structure to this organized structure:

- `api_service.dart` → `services/api_service.dart`
- `translation_extension.dart` → `utils/translation_extension.dart`
- UI logic moved to `screens/home_screen.dart`
- Constants moved to `core/constants.dart`
- Theme moved to `core/theme.dart`

All imports have been updated to reflect the new structure.
