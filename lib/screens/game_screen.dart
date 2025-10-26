import 'package:flutter/material.dart';
import '../models/animal_data.dart';
import '../widgets/loading_widget.dart';
import '../widgets/error_widget.dart';
import 'guess_screen.dart';

/// GameScreen is used to reveal clues about an animal to the user
/// and allows making a guess at the end. It is intended to be used as
/// a step in the guessing game, but is NOT currently being used in the app!
class GameScreen extends StatefulWidget {
  final AnimalData animal;       // Animal data including hints
  final bool isEnglish;          // Language flag

  const GameScreen({
    super.key,
    required this.animal,
    required this.isEnglish,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  int currentClueIndex = 0;      // Index of the next clue to reveal
  List<String> shownClues = [];  // List of clues shown to the user

  /// Shows the next available clue (if any left)
  void _showNextClue() {
    // Only show a new clue if there are any remaining
    if (currentClueIndex < widget.animal.hints.length) {
      setState(() {
        shownClues.add(widget.animal.hints[currentClueIndex]); // Reveal next clue
        currentClueIndex++; // Move index forward
      });
    }
  }

  /// Navigates to the GuessScreen so user can make a guess
  void _makeGuess() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GuessScreen(
          animal: widget.animal,
          isEnglish: widget.isEnglish,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // This widget is NOT used in the app's main flow; see lib/screens/quiz_screen.dart for actual gameplay.
    return Scaffold(
      appBar: AppBar(
        // Title changes based on language
        title: Text(widget.isEnglish ? 'Guess the Animal' : 'Gissa Djuret'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        // Main column with heading, the list of clues, and buttons
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Intro card with icon and instructions
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Icon(
                      Icons.pets,
                      size: 64,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.isEnglish 
                        ? 'Can you guess this animal?'
                        : 'Kan du gissa detta djur?',
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.isEnglish 
                        ? 'Reveal clues one by one!'
                        : 'Avslöja ledtrådar en i taget!',
                      style: Theme.of(context).textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Section title for the clues
            Text(
              widget.isEnglish ? 'Clues:' : 'Ledtrådar:',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            // List of revealed clues, or prompt to reveal the first clue
            Expanded(
              child: shownClues.isEmpty
                  // No clues shown yet: show bulb icon and message
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.lightbulb_outline,
                            size: 64,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            widget.isEnglish 
                              ? 'Tap the button below to reveal the first clue!'
                              : 'Tryck på knappen nedan för att avslöja den första ledtråden!',
                            style: Theme.of(context).textTheme.bodyLarge,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  // Show list of clues as cards
                  : ListView.builder(
                      itemCount: shownClues.length,
                      itemBuilder: (context, index) {
                        return Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              child: Text(
                                // Show clue number
                                '${index + 1}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(shownClues[index]),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 16),
            // Either show the "Show Clue" button or the "Make Your Guess" button
            if (currentClueIndex < widget.animal.hints.length)
              // More clues available: "Show Clue" button
              ElevatedButton.icon(
                onPressed: _showNextClue,
                icon: const Icon(Icons.lightbulb),
                label: Text(
                  widget.isEnglish 
                    ? 'Show Clue ${currentClueIndex + 1}'
                    : 'Visa Ledtråd ${currentClueIndex + 1}',
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              )
            else
              ElevatedButton.icon(
                onPressed: _makeGuess,
                icon: const Icon(Icons.quiz),
                label: Text(
                  widget.isEnglish 
                    ? 'Make Your Guess!'
                    : 'Gör din gissning!',
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
