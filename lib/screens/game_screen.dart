import 'package:flutter/material.dart';
import '../models/animal_data.dart';
import '../widgets/loading_widget.dart';
import '../widgets/error_widget.dart';
import 'guess_screen.dart';

class GameScreen extends StatefulWidget {
  final AnimalData animal;
  final bool isEnglish;

  const GameScreen({
    super.key,
    required this.animal,
    required this.isEnglish,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  int currentClueIndex = 0;
  List<String> shownClues = [];

  void _showNextClue() {
    if (currentClueIndex < widget.animal.hints.length) {
      setState(() {
        shownClues.add(widget.animal.hints[currentClueIndex]);
        currentClueIndex++;
      });
    }
  }

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
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEnglish ? 'Guess the Animal' : 'Gissa Djuret'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
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
            Text(
              widget.isEnglish ? 'Clues:' : 'Ledtrådar:',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: shownClues.isEmpty
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
                  : ListView.builder(
                      itemCount: shownClues.length,
                      itemBuilder: (context, index) {
                        return Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              child: Text(
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
            if (currentClueIndex < widget.animal.hints.length)
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
