import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/animal_data.dart';
import 'quiz_result_screen.dart';
import 'home_screen.dart';

class QuizScreen extends StatefulWidget {
  final AnimalData animal;
  final bool isEnglish;
  final int questionIndex;
  final int totalQuestions;

  const QuizScreen({
    super.key,
    required this.animal,
    required this.isEnglish,
    this.questionIndex = 1,
    this.totalQuestions = 5,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  // Definiera färgen som ska ersätta vitt
  static const Color _newColor = Color(0xFFE7EFE7);

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  final List<String> _allAnimals = const [
    'Rabbit', 'White tailed rabbit', 'Brown Canadian rabbit', 'Hare',
    'Arctic hare', 'Mountain hare', 'Pika', 'Mouse', 'Rat', 'Squirrel', 'Fox',
    'Red fox', 'Arctic fox', 'Wolf', 'Bear', 'Brown bear', 'Polar bear', 'Deer',
    'Moose', 'Elk',
    // Lägg till fler djur här vid behov
  ];

  List<String> _filtered = const [];
  bool _isIncorrect = false;
  bool _isCorrect = false;
  String? _selectedAnswer;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onQueryChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onQueryChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onQueryChanged() {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      setState(() {
        _filtered = const [];
        _isIncorrect = false;
        _isCorrect = false;
        _selectedAnswer = null;
      });
      return;
    }
    setState(() {
      _filtered = _allAnimals
          .where((name) => name.toLowerCase().contains(query))
          .take(6) // Behåll .take(6) så att listan KAN skrollas om det finns fler än 3 träffar
          .toList();
      _isIncorrect = false;
      _isCorrect = false;
      _selectedAnswer = null;
    });
  }

  // Visar "Hur man spelar"-dialogen (använder showDialog med anpassat tema)
  void _showHowToPlayDialog(BuildContext context) {
    final String title = widget.isEnglish ? 'How to Play' : 'Hur man spelar';
    final List<Map<String, String>> instructions = [
       {
        'title_en': 'Guess the Animal',
        'title_sv': 'Gissa Djuret',
        'body_en':
            'You will be presented with 5 questions in decreasing difficulty, about a specific swedish mammal. Your goal is simple: guess the animal!',
        'body_sv':
            'Du kommer att presenteras med 5 frågor i fallande svårighetsgrad, om ett specifikt svenskt däggdjur. Ditt mål är enkelt: gissa djuret!',
      },
      {
        'title_en': 'Daily game',
        'title_sv': 'Dagligt spel',
        'body_en':
            'You can play the game once per day. After 24 hours, you will be able to play the game again, with a new animal.',
        'body_sv':
            'Du kan spela spelet en gång per dag. Efter 24 timmar kommer du att kunna spela spelet igen, med ett nytt djur.',
      },
      {
        'title_en': 'Highest Score',
        'title_sv': 'Högsta Poängen',
        'body_en':
            'The fewer guesses it takes to guess the correct animal, the higher your score will be!',
        'body_sv':
            'Ju färre frågor du använder för att gissa det korrekta djuret, desto högre blir din poäng!',
      },
      {
        'title_en': 'One Chance Only',
        'title_sv': 'Bara en chans',
        'body_en':
            'You get only one attempt to submit your final guess per question. Make sure you are confident before you lock it in!',
        'body_sv':
            'Du får bara ett försök att skicka in din slutgiltiga gissning per fråga. Se till att du är säker innan du låser den!',
      },
    ];

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.75), // Mörk "dimma"
      builder: (BuildContext context) {
        // Sveper in i ett mörkt tema för att matcha skärmens UI
        return Theme(
          data: ThemeData.dark().copyWith(
            textTheme: GoogleFonts.ibmPlexMonoTextTheme(
              ThemeData.dark().textTheme,
            ).copyWith(
              titleLarge: const TextStyle(color: _newColor, fontWeight: FontWeight.w700), // Ändrad
              bodyMedium: TextStyle(color: _newColor.withOpacity(0.8)), // Ändrad
            ), dialogTheme: DialogThemeData(backgroundColor: const Color(0xFF1E1E1E)),
          ),
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: _newColor.withOpacity(0.2)), // Ändrad
            ),
            title: Text(
              title,
              textAlign: TextAlign.center,
              ),
            titlePadding: const EdgeInsets.only(top: 24, bottom: 16), // Spacing
            contentPadding: const EdgeInsets.only(left: 24, right: 24, top: 20), // Spacing
            content: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.7,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: instructions.map((step) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.check_circle_outline,
                            color: Color(0xFF10B981), // Grön check-ikon (behålls)
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.isEnglish
                                      ? step['title_en']!
                                      : step['title_sv']!,
                                  style: GoogleFonts.ibmPlexMono(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w600,
                                    color: _newColor, // Ändrad
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  widget.isEnglish
                                      ? step['body_en']!
                                      : step['body_sv']!,
                                  style: GoogleFonts.ibmPlexMono(
                                    fontSize: 15,
                                    color: _newColor.withOpacity(0.7), // Ändrad
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            actions: [
              TextButton(
                child: Text(
                  'OK',
                  style: GoogleFonts.ibmPlexMono(
                    color: _newColor, // Ändrad
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final String titleText = widget.isEnglish
        ? 'Question ${widget.questionIndex}/${widget.totalQuestions}'
        : 'Fråga ${widget.questionIndex}/${widget.totalQuestions}';

    final bool canGuess = _searchController.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.black, // Behålls svart
      body: Container(
        color: Colors.black, // Behålls svart
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, // Behåll startjustering för header
              children: [
                // Header med knappar
                 Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(color: _newColor.withOpacity(0.08), borderRadius: BorderRadius.circular(12)), // Ändrad
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                        color: _newColor, // Ändrad
                        onPressed: () => Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (context) => const HomeScreen()), (Route<dynamic> route) => false),
                        style: IconButton.styleFrom(padding: const EdgeInsets.all(8), minimumSize: const Size(40, 40)),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      decoration: BoxDecoration(color: _newColor.withOpacity(0.08), borderRadius: BorderRadius.circular(12)), // Ändrad
                      child: IconButton(
                        icon: const Icon(Icons.info_outline_rounded, size: 20),
                        color: _newColor, // Ändrad
                        onPressed: () => _showHowToPlayDialog(context),
                        style: IconButton.styleFrom(padding: const EdgeInsets.all(8), minimumSize: const Size(40, 40)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Frågetitel
                Center(
                  child: Text(
                    titleText,
                    style: GoogleFonts.ibmPlexMono(
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                      color: _newColor, // Ändrad
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Centrerad sektion med fast bredd för ledtråd och textfält
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 380), // Fast maxbredd
                    child: Column( // Kolumn för ledtråd och textfält+förslag
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Ledtrådskort
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.transparent, // Behålls transparent
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _newColor, width: 2), // Ändrad
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              AnimatedDefaultTextStyle(
                                duration: const Duration(milliseconds: 300),
                                style: GoogleFonts.ibmPlexMono(
                                  fontSize: 18,
                                  color: _newColor, // Ändrad
                                  height: 1.5,
                                ),
                                child: Text(
                                  _getClueText(),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Textfält och förslag
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              height: 60, padding: const EdgeInsets.symmetric(horizontal: 20),
                              decoration: BoxDecoration(
                                // Bakgrundsfärg för textfältet (ej ändrad från F8FAFC när korrekt)
                                color: _isIncorrect
                                    ? const Color.fromARGB(255, 235, 88, 88) // Behåll röd vid fel
                                    : _newColor,
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(
                                  // Ändrad från Colors.white.withOpacity(0.2) -> _newTextColor.withOpacity(0.2)
                                  color: _isIncorrect ? const Color.fromARGB(255, 235, 88, 88).withOpacity(0.3) : _newColor.withOpacity(0.2),
                                  width: 1),
                                boxShadow: _isIncorrect ? null : [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _searchController, focusNode: _searchFocusNode,
                                      textAlign: _isCorrect || _isIncorrect ? TextAlign.center : TextAlign.start,
                                      readOnly: _isCorrect || _isIncorrect, enabled: !_isCorrect && !_isIncorrect,
                                      style: GoogleFonts.ibmPlexMono(
                                        fontSize: 17,
                                        // Textfärg när fel (behålls vit för kontrast mot rött)
                                        color: _isIncorrect ? Colors.white : const Color(0xFF1F2937), // Behåll mörk text när korrekt
                                        fontWeight: FontWeight.w500),
                                      decoration: InputDecoration(
                                        hintText: widget.isEnglish ? 'Guess the animal' : 'Gissa djuret',
                                        hintStyle: GoogleFonts.ibmPlexMono(
                                          // Hint text färg när fel (använder nya färgen lätt transparent)
                                          color: _isIncorrect ? _newColor.withOpacity(0.7) : const Color(0xFF6B7280), // Behåll gråaktig när korrekt
                                          fontSize: 17, fontWeight: FontWeight.w400),
                                        border: InputBorder.none, isCollapsed: true,
                                      ),
                                    ),
                                  ),
                                  if (!_isIncorrect && !_isCorrect) ...[
                                    const SizedBox(width: 12),
                                    // Ikonfärg (behålls gråaktig)
                                    const Icon(Icons.search_rounded, color: Color(0xFF6B7280), size: 22),
                                  ],
                                ],
                              ),
                            ),
                            // Suggestions dropdown (oförändrad, använder redan den önskade färgen)
                            AnimatedSwitcher(
                                duration: const Duration(milliseconds: 180),
                                child: _filtered.isNotEmpty && _searchFocusNode.hasFocus && !_isIncorrect && !_isCorrect
                                    ? Container(
                                        key: const ValueKey('suggestions'),
                                        margin: const EdgeInsets.only(top: 8),
                                        // Här är färgen du ville använda: 0xFFE7EFE7
                                        decoration: BoxDecoration(color: const Color(0xFFE7EFE7), borderRadius: BorderRadius.circular(12)),
                                        
                                        // +++ LÖSNING 1: Begränsa höjden till ca 3 rader +++
                                        constraints: const BoxConstraints(
                                          // (Padding 14*2 + Text ~20) * 3 items + (Divider 1px * 2) ≈ 146
                                          maxHeight: 146.0,
                                        ),
                                        // +++ SLUT LÖSNING 1 +++

                                        child: ListView.separated(
                                          shrinkWrap: true,

                                          // +++ LÖSNING 2: Gör listan skrollbar +++
                                          physics: const ClampingScrollPhysics(), // Byt från NeverScrollableScrollPhysics
                                          // +++ SLUT LÖSNING 2 +++

                                          itemCount: _filtered.length,
                                          separatorBuilder: (_, __) => const Divider(height: 1, color: Colors.black12), // Behåll svart separator för kontrast
                                          itemBuilder: (context, index) {
                                            final suggestion = _filtered[index];
                                            return InkWell(
                                              borderRadius: index == 0 || index == _filtered.length - 1
                                                  ? BorderRadius.only(
                                                      topLeft: Radius.circular(index == 0 ? 12 : 0),
                                                      topRight: Radius.circular(index == 0 ? 12 : 0),
                                                      bottomLeft: Radius.circular(index == _filtered.length - 1 ? 12 : 0),
                                                      bottomRight: Radius.circular(index == _filtered.length - 1 ? 12 : 0),
                                                    )
                                                  : BorderRadius.zero,
                                              onTap: () {
                                                _searchController.text = suggestion; _searchFocusNode.unfocus();
                                                setState(() { _filtered = const []; _isIncorrect = false; _isCorrect = false; _selectedAnswer = suggestion; });
                                              },
                                              child: Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                                child: Align(
                                                  alignment: Alignment.centerLeft,
                                                  // Behåll svart text i förslagen för kontrast
                                                  child: Text(suggestion, style: GoogleFonts.ibmPlexMono(fontSize: 16, color: Colors.black)),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      )
                                    : const SizedBox.shrink(),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Rätt/Fel-meddelande
                ...(_isCorrect || _isIncorrect
                    ? [
                        const SizedBox(height: 24),
                        Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            decoration: const BoxDecoration(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(12)),
                            ),
                            child: Text(
                              _isCorrect
                                  ? (widget.isEnglish ? 'Correct!' : 'Rätt!')
                                  : (widget.isEnglish ? 'Incorrect!' : 'Fel!'),
                              style: GoogleFonts.ibmPlexMono(
                                color: _newColor, // Ändrad
                                fontSize: 24, // Större font
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const Spacer(), // Spacer efter meddelandet
                      ]
                    : [
                        const Spacer(), // Spacer när inget meddelande visas
                      ]),

                // Knappar
                Row(
                  children: [
                    if (!_isIncorrect && !_isCorrect) ...[
                      // "Jag vet inte" button
                      Expanded(
                        child: Container(
                          height: 56,
                          decoration: BoxDecoration(
                            color: _newColor.withOpacity(0.12), // Ändrad
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: _newColor.withOpacity(0.25), width: 1.5), // Ändrad
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () => _goToNextQuestion(context),
                              child: Center(
                                child: Text(
                                  widget.isEnglish ? "I don't know" : "Jag vet inte",
                                  style: GoogleFonts.ibmPlexMono(color: _newColor, fontSize: 16, fontWeight: FontWeight.w500), // Ändrad
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // "Gissa" button
                      Expanded(
                        child: Container(
                          height: 56,
                          decoration: BoxDecoration(
                            // Grön och grå knappfärg behålls för tydlighet
                            color: canGuess ? const Color(0xFF10B981) : const Color(0xFF6B7280),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: canGuess ? [BoxShadow(color: const Color(0xFF10B981).withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4))] : null,
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: canGuess ? _checkAnswer : null,
                              child: Center(
                                child: Text(
                                  widget.isEnglish ? 'Guess' : 'Gissa',
                                  // Textfärg i knapp behålls vit för kontrast
                                  style: GoogleFonts.ibmPlexMono(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ]
                    // "Nästa fråga" knappen (fel svar)
                    else if (_isIncorrect)
                      Expanded(
                        child: Container(
                          height: 56, padding: const EdgeInsets.symmetric(horizontal: 24),
                          decoration: BoxDecoration(
                            color: _newColor, // Ändrad
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2))],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () => _goToNextQuestion(context),
                              child: Center(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(widget.isEnglish ? 'Next question' : 'Nästa fråga',
                                      // Ändrat från Colors.black -> Svart för kontrast
                                      style: GoogleFonts.ibmPlexMono(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w600)),
                                    const SizedBox(width: 8),
                                    // Ändrat från Colors.black -> Svart för kontrast
                                    const Icon(Icons.arrow_forward_rounded, color: Colors.black, size: 18),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      )
                    // "Nästa fråga" knappen (rätt svar)
                    else if (_isCorrect)
                      Expanded(
                        child: Container(
                          height: 56, padding: const EdgeInsets.symmetric(horizontal: 24),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981), // Behålls grön
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [BoxShadow(color: const Color(0xFF10B981).withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () => _goToNextQuestion(context),
                              child: Center(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(widget.isEnglish ? 'Next question' : 'Nästa fråga',
                                      // Behålls vit för kontrast mot grönt
                                      style: GoogleFonts.ibmPlexMono(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                                    const SizedBox(width: 8),
                                    // Behålls vit för kontrast mot grönt
                                    const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Övriga metoder (_getClueText, _checkAnswer, _goToNextQuestion) är oförändrade ---
  String _getClueText() {
    if (widget.animal.hints.isNotEmpty) {
      final hintIndex = (widget.questionIndex - 1) % widget.animal.hints.length;
      return widget.animal.hints[hintIndex];
    }
    return widget.isEnglish ? 'Can you guess this animal?' : 'Kan du gissa detta djur?';
  }

  void _checkAnswer() {
    final answer = _searchController.text.trim().toLowerCase();
    final correctAnswer = widget.animal.name.toLowerCase();

    if (answer == correctAnswer || answer == widget.animal.scientificName.toLowerCase()) {
      setState(() {
        _isCorrect = true; _isIncorrect = false; _selectedAnswer = _searchController.text.trim();
        _searchFocusNode.unfocus();
      });
    } else {
      setState(() {
        _isIncorrect = true; _isCorrect = false;
        _searchFocusNode.unfocus(); _filtered = const [];
      });
    }
  }

 void _goToNextQuestion(BuildContext context) {
    final int nextIndex = widget.questionIndex + 1;

    // Kontrollera om vi är på sista frågan ELLER om svaret var korrekt
    if (nextIndex > widget.totalQuestions || _isCorrect) {
      // Gå till resultatskärmen
      Navigator.of(context).pushReplacement( // Använd pushReplacement för att ersätta quiz-skärmen
        MaterialPageRoute(
          builder: (_) => QuizResultScreen(
            animal: widget.animal, isEnglish: widget.isEnglish, isCorrect: _isCorrect,
            questionIndex: _isCorrect ? widget.questionIndex : widget.totalQuestions, // Korrekt index till resultat
            totalQuestions: widget.totalQuestions,
          ),
        ),
      );
    } else {
      // Gå till nästa fråga (ersätt nuvarande skärm)
      Navigator.of(context).pushReplacement( // Använd pushReplacement
        MaterialPageRoute(
          builder: (_) => QuizScreen(
            animal: widget.animal, isEnglish: widget.isEnglish,
            questionIndex: nextIndex, totalQuestions: widget.totalQuestions,
          ),
        ),
      );
    }
  }
} // Slut på _QuizScreenState