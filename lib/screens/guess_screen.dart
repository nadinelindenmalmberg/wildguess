import 'package:flutter/material.dart';
import '../models/animal_data.dart';
import 'quiz_result_screen.dart';

class GuessScreen extends StatefulWidget {
  final AnimalData animal;
  final bool isEnglish;

  const GuessScreen({
    super.key,
    required this.animal,
    required this.isEnglish,
  });

  @override
  State<GuessScreen> createState() => _GuessScreenState();
}

class _GuessScreenState extends State<GuessScreen> {
  final TextEditingController _guessController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Auto-focus the text field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _guessController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submitGuess() {
    final guess = _guessController.text.trim();
    if (guess.isEmpty) return;

    final isCorrect = _checkGuess(guess);
    
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => QuizResultScreen(
          animal: widget.animal,
          isEnglish: widget.isEnglish,
          isCorrect: isCorrect,
          questionIndex: 1,
          totalQuestions: 1,
          aiClues: const [], // Empty list since this is a simple guess screen
        ),
      ),
    );
  }

  bool _checkGuess(String guess) {
    // Check against both Swedish and scientific names
    final swedishName = widget.animal.name.toLowerCase();
    final scientificName = widget.animal.scientificName.toLowerCase();
    final userGuess = guess.toLowerCase();

    return userGuess == swedishName || userGuess == scientificName;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEnglish ? 'Make Your Guess' : 'Gör din gissning'),
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
                      Icons.quiz,
                      size: 64,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.isEnglish 
                        ? 'What animal do you think it is?'
                        : 'Vilket djur tror du att det är?',
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.isEnglish 
                        ? 'Enter your guess below:'
                        : 'Skriv in din gissning nedan:',
                      style: Theme.of(context).textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _guessController,
              focusNode: _focusNode,
              decoration: InputDecoration(
                labelText: widget.isEnglish ? 'Your guess' : 'Din gissning',
                hintText: widget.isEnglish 
                  ? 'Enter animal name...' 
                  : 'Skriv djurnamn...',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.edit),
              ),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submitGuess(),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _submitGuess,
              icon: const Icon(Icons.check),
              label: Text(
                widget.isEnglish ? 'Submit Guess' : 'Skicka gissning',
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
              label: Text(
                widget.isEnglish ? 'Back to clues' : 'Tillbaka till ledtrådar',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
