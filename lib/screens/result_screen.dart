import 'package:flutter/material.dart';
import '../models/animal_data.dart';
import 'home_screen.dart';

class ResultScreen extends StatelessWidget {
  final AnimalData animal;
  final String userGuess;
  final bool isCorrect;
  final bool isEnglish;

  const ResultScreen({
    super.key,
    required this.animal,
    required this.userGuess,
    required this.isCorrect,
    required this.isEnglish,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEnglish ? 'Result' : 'Resultat'),
        backgroundColor: isCorrect 
          ? Colors.green 
          : Colors.red,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              color: isCorrect 
                ? Colors.green.shade50 
                : Colors.red.shade50,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Icon(
                      isCorrect ? Icons.celebration : Icons.sentiment_dissatisfied,
                      size: 80,
                      color: isCorrect ? Colors.green : Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isCorrect 
                        ? (isEnglish ? 'Correct!' : 'Rätt!')
                        : (isEnglish ? 'Wrong!' : 'Fel!'),
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        color: isCorrect ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isCorrect 
                        ? (isEnglish 
                          ? 'Well done! You guessed it right!'
                          : 'Bra gjort! Du gissade rätt!')
                        : (isEnglish 
                          ? 'Better luck next time!'
                          : 'Bättre lycka nästa gång!'),
                      style: Theme.of(context).textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEnglish ? 'Answer:' : 'Svar:',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    if (animal.name.isNotEmpty)
                      _buildInfoRow(
                        isEnglish ? 'Name' : 'Namn',
                        animal.name,
                      ),
                    if (animal.scientificName.isNotEmpty)
                      _buildInfoRow(
                        isEnglish ? 'Scientific Name' : 'Vetenskapligt namn',
                        animal.scientificName,
                      ),
                    if (animal.description.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        isEnglish ? 'Description:' : 'Beskrivning:',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(animal.description),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (!isCorrect) ...[
              Card(
                color: Colors.orange.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info,
                        color: Colors.orange,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          isEnglish 
                            ? 'Your guess: "$userGuess"'
                            : 'Din gissning: "$userGuess"',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HomeScreen(),
                  ),
                  (route) => false,
                );
              },
              icon: const Icon(Icons.home),
              label: Text(
                isEnglish ? 'Play Again' : 'Spela igen',
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
              label: Text(
                isEnglish ? 'Back to Game' : 'Tillbaka till spelet',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
