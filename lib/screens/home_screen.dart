import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/animal_data.dart';
import '../utils/translation_extension.dart';
import '../widgets/loading_widget.dart';
import '../widgets/error_widget.dart';
import 'game_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isEnglish = false;
  AnimalData? currentAnimal;
  bool isLoading = false;
  String? errorMessage;
  late Future<AnimalData> _animalFuture;

  void _toggleLanguage() {
    setState(() {
      isEnglish = !isEnglish;
    });
  }

  Future<AnimalData> _loadRandomAnimal() async {
    final apiService = ApiService();
    return await apiService.getRandomAnimal();
  }

  void _refreshAnimal() {
    setState(() {
      _animalFuture = _loadRandomAnimal();
    });
  }

  @override
  void initState() {
    super.initState();
    _animalFuture = _loadRandomAnimal();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEnglish ? 'Wild Guess' : 'Vild Gissning'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: Icon(isEnglish ? Icons.language : Icons.translate),
            onPressed: _toggleLanguage,
            tooltip: isEnglish ? 'Switch to Swedish' : 'Switch to English',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEnglish ? 'Welcome to Wild Guess!' : 'Välkommen till Vild Gissning!',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isEnglish 
                        ? 'Test your knowledge of Swedish wildlife!'
                        : 'Testa din kunskap om svensk vildmark!',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: FutureBuilder<AnimalData>(
                future: _animalFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const LoadingWidget(message: 'Loading animal data...');
                  } else if (snapshot.hasError) {
                    return ErrorDisplayWidget(
                      message: snapshot.error.toString(),
                      onRetry: _refreshAnimal,
                    );
                  } else if (snapshot.hasData) {
                    final animal = snapshot.data!;
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.pets,
                              size: 80,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              isEnglish ? 'Ready to Play!' : 'Redo att spela!',
                              style: Theme.of(context).textTheme.headlineMedium,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              isEnglish 
                                ? 'A random animal has been selected. Can you guess what it is?'
                                : 'Ett slumpmässigt djur har valts. Kan du gissa vad det är?',
                              style: Theme.of(context).textTheme.bodyLarge,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => GameScreen(
                                      animal: animal,
                                      isEnglish: isEnglish,
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.play_arrow),
                              label: Text(
                                isEnglish ? 'Start Game' : 'Starta spel',
                              ),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 32,
                                  vertical: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  } else {
                    return const LoadingWidget(message: 'Loading...');
                  }
                },
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _refreshAnimal,
              child: Text(
                isEnglish ? 'Get New Animal' : 'Få nytt djur',
              ),
            ),
          ],
        ),
      ),
    );
  }

}
