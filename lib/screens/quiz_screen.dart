import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/animal_data.dart';
import '../services/ai_clue_service.dart';
import '../services/api_service.dart';
import 'quiz_result_screen.dart';
import 'home_screen.dart';
import 'package:confetti/confetti.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  final AiClueService _aiClueService = AiClueService();
  final ApiService _apiService = ApiService();

  List<String> _aiClues = [];
  bool _isLoadingAiClues = false;

  List<AnimalData> _searchResults = [];
  List<String> _filtered = const [];
  bool _isSearching = false;
  bool _hasChosenSuggestion = false;
  bool _isIncorrect = false;
  bool _isCorrect = false;
  String? _selectedAnswer;
  bool _pressedIDontKnow = false; // Track if user pressed "I don't know" button
  
  // Level system state - simplified
  int _currentLevel = 1;
  int _maxReachedLevel = 1; // Track the furthest level reached
  bool _isViewingPreviousLevel = false;
  List<Map<String, dynamic>> _levelHistory = []; // Store previous level answers
  
  // Confetti controller
  late ConfettiController _confettiController;
  
  // Debouncing timer to prevent excessive API calls
  Timer? _searchDebounceTimer;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onQueryChanged);
    _generateAiClues();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
    
    // Initialize level system
    _currentLevel = widget.questionIndex;
    _maxReachedLevel = widget.questionIndex;
    _loadLevelHistory();
  }

  Future<void> _generateAiClues() async {
    if (_aiClues.isNotEmpty) return; // Already generated
    
    setState(() {
      _isLoadingAiClues = true;
    });

    try {
      final clues = await _aiClueService.generateClues(
        widget.animal,
        isEnglish: widget.isEnglish,
      );
      
      if (mounted) {
        setState(() {
          _aiClues = clues;
          _isLoadingAiClues = false;
        });
      }
    } catch (e) {
      print('Failed to generate AI clues: $e');
      if (mounted) {
        setState(() {
          _isLoadingAiClues = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
    _searchController.removeListener(_onQueryChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    _aiClueService.dispose();
    _apiService.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  void _onQueryChanged() {
    final query = _searchController.text.trim();
    
    // Cancel previous timer
    _searchDebounceTimer?.cancel();
    
    if (query.isEmpty) {
      setState(() {
        _filtered = const [];
        _searchResults = [];
        _hasChosenSuggestion = false;
        _isIncorrect = false;
        _isCorrect = false;
        _selectedAnswer = null;
        _isSearching = false;
      });
      return;
    }
    
    if (query.length < 2) {
      setState(() {
        _filtered = const [];
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }
    
    // Debounce the search - wait 300ms after user stops typing
    _searchDebounceTimer = Timer(const Duration(milliseconds: 300), () async {
      if (!mounted) return;
      
      setState(() {
        _isSearching = true;
        _hasChosenSuggestion = false;
        _isIncorrect = false;
        _isCorrect = false;
        _selectedAnswer = null;
      });
      
      try {
        final results = await _apiService.searchSpecies(query, isEnglish: widget.isEnglish);
        if (mounted) {
          setState(() {
            _searchResults = results;
            _filtered = results.map((animal) => animal.name).take(3).toList();
            _isSearching = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _searchResults = [];
            _filtered = const [];
            _isSearching = false;
          });
          print('Search error: $e');
        }
      }
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
        ? 'Clue ${_currentLevel}/${widget.totalQuestions}'
        : 'Ledtråd ${_currentLevel}/${widget.totalQuestions}';

    final bool canGuess = _searchController.text.trim().isNotEmpty && !_isViewingPreviousLevel;

    return Scaffold(
      backgroundColor: Colors.black, // Behålls svart
      body: Stack(
        children: [
          Container(
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

                // Level navigation indicators
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(widget.totalQuestions, (index) {
                      final clueNumber = index + 1;
                      final isCurrentLevel = clueNumber == _currentLevel;
                      final isUnlocked = clueNumber <= _maxReachedLevel;
                      final hasAnswer = _levelHistory.any((level) => level['levelIndex'] == clueNumber);
                      final isCorrect = hasAnswer ? _levelHistory.firstWhere((level) => level['levelIndex'] == clueNumber)['isCorrect'] : false;

                      return GestureDetector(
                        onTap: clueNumber <= _maxReachedLevel ? () => _goToLevel(clueNumber) : null,
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: isCurrentLevel ? 50 : 40,
                          height: isCurrentLevel ? 50 : 40,
                          decoration: BoxDecoration(
                            color: isCurrentLevel
                                ? Colors.white // white=current
                                : hasAnswer
                                    ? (isCorrect ? Colors.green : Colors.red) // green=correct, red=incorrect
                                    : Colors.grey[600], // gray=untouched
                            borderRadius: BorderRadius.circular(isCurrentLevel ? 25 : 20),
                            border: isCurrentLevel
                                ? Border.all(color: _newColor, width: 3)
                                : null,
                            boxShadow: isCurrentLevel
                                ? [
                                    BoxShadow(
                                      color: _newColor.withOpacity(0.5),
                                      blurRadius: 8,
                                      spreadRadius: 2,
                                    )
                                  ]
                                : null,
                          ),
                          child: Center(
                            child: hasAnswer && !isCurrentLevel
                                ? Icon(
                                    _levelHistory.firstWhere((level) => level['levelIndex'] == clueNumber)['isCorrect']
                                        ? Icons.check
                                        : Icons.close,
                                    color: Colors.white,
                                    size: 20,
                                  )
                                : Text(
                                    '$clueNumber',
                                    style: GoogleFonts.ibmPlexMono(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: isCurrentLevel
                                          ? Colors.black
                                          : isUnlocked
                                              ? Colors.white
                                              : Colors.grey[500], // Locked clues are greyed out
                                    ),
                                  ),
                          ),
                        ),
                      );
                    }),
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
                            color: Colors.black, // Always black
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              AnimatedDefaultTextStyle(
                                duration: const Duration(milliseconds: 300),
                                style: GoogleFonts.ibmPlexMono(
                                  fontSize: 18,
                                  color: Colors.white, // Changed to white for black background
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
                        
                        const SizedBox(height: 16),
                        
                        // Search input field
                        TextField(
                          controller: _searchController,
                          focusNode: _searchFocusNode,
                          enabled: !_isViewingPreviousLevel, // Disable when viewing previous levels
                          decoration: InputDecoration(
                            hintText: _isViewingPreviousLevel
                                ? (widget.isEnglish
                                    ? 'Previous answer shown above'
                                    : 'Tidigare svar visas ovan')
                                : (widget.isEnglish
                                    ? 'Type your guess here...'
                                    : 'Skriv din gissning här...'),
                            hintStyle: GoogleFonts.ibmPlexMono(
                              color: _isViewingPreviousLevel ? Colors.grey[400] : Colors.grey[500],
                              fontSize: 16,
                            ),
                            filled: true,
                            fillColor: _isViewingPreviousLevel ? Colors.grey[200] : Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                            prefixIcon: Icon(
                              _isViewingPreviousLevel ? Icons.history : Icons.search,
                              color: _isViewingPreviousLevel ? Colors.grey[400] : Colors.grey,
                            ),
                          ),
                          style: GoogleFonts.ibmPlexMono(
                            fontSize: 16,
                            color: _isViewingPreviousLevel ? Colors.black : Colors.black,
                            fontWeight: _isViewingPreviousLevel ? FontWeight.w600 : FontWeight.normal,
                          ),
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _checkAnswer(),
                        ),
                        
                        // Search suggestions dropdown
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 180),
                          child: _searchFocusNode.hasFocus && !_isIncorrect && !_isCorrect
                              ? Container(
                                  key: const ValueKey('suggestions'),
                                  margin: const EdgeInsets.only(top: 8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE7EFE7),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: _isSearching
                                      ? Padding(
                                          padding: const EdgeInsets.all(16),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              const SizedBox(
                                                width: 16,
                                                height: 16,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1F2937)),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Text(
                                                'Söker arter...',
                                                style: GoogleFonts.ibmPlexMono(
                                                  fontSize: 14,
                                                  color: const Color(0xFF1F2937),
                                                ),
                                              ),
                                            ],
                                          ),
                                        )
                                      : _filtered.isNotEmpty
                                          ? Container(
                                              constraints: BoxConstraints(
                                                maxHeight: _filtered.length == 1 ? 60 : 200,
                                                minHeight: _filtered.length == 1 ? 60 : 0,
                                              ),
                                              decoration: BoxDecoration(
                                                border: Border.all(color: Colors.black12),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: ListView.separated(
                                                physics: const BouncingScrollPhysics(),
                                                itemCount: _filtered.length,
                                                separatorBuilder: (_, __) => const Divider(height: 1, color: Colors.black12),
                                                itemBuilder: (context, index) {
                                                  final suggestion = _filtered[index];
                                                  final animalData = _searchResults.length > index ? _searchResults[index] : null;
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
                                                      _searchController.text = suggestion;
                                                      _searchFocusNode.unfocus();
                                                      setState(() {
                                                        _filtered = const [];
                                                        _searchResults = [];
                                                        _hasChosenSuggestion = true;
                                                        _isIncorrect = false;
                                                        _isCorrect = false;
                                                        _selectedAnswer = suggestion;
                                                      });
                                                    },
                                                    child: Padding(
                                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Text(
                                                            suggestion,
                                                            style: GoogleFonts.ibmPlexMono(
                                                              fontSize: 15,
                                                              color: const Color(0xFF1F2937),
                                                              fontWeight: FontWeight.w600,
                                                            ),
                                                          ),
                                                          if (animalData?.scientificName.isNotEmpty == true) ...[
                                                            const SizedBox(height: 2),
                                                            Text(
                                                              animalData!.scientificName,
                                                              style: GoogleFonts.ibmPlexMono(
                                                                fontSize: 13,
                                                                color: const Color(0xFF6B7280),
                                                                fontStyle: FontStyle.italic,
                                                              ),
                                                            ),
                                                          ],
                                                        ],
                                                      ),
                                                    ),
                                                  );
                                                },
                                              ),
                                            )
                                          : _searchController.text.length >= 2
                                              ? Padding(
                                                  padding: const EdgeInsets.all(16),
                                                  child: Text(
                                                    'Inga arter hittades för "${_searchController.text}"',
                                                    style: GoogleFonts.ibmPlexMono(
                                                      fontSize: 14,
                                                      color: const Color(0xFF6B7280),
                                                    ),
                                                  ),
                                                )
                                              : const SizedBox.shrink(),
                                )
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),
                ),

                // Rätt/Fel-meddelande
                ...(_isCorrect || _isIncorrect || (_isViewingPreviousLevel && _shouldShowPreviousLevelMessage())
                    ? [
                        const SizedBox(height: 24),
                        Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: _isViewingPreviousLevel
                                  ? _getPreviousLevelColor()
                                  : _isCorrect
                                      ? Colors.green // Green background for correct
                                      : const Color.fromARGB(255, 223, 102, 102), // Red background for incorrect
                              borderRadius:
                                  BorderRadius.all(Radius.circular(12)),
                              boxShadow: [
                                BoxShadow(
                                  color: (_isViewingPreviousLevel
                                      ? _getPreviousLevelColor()
                                      : _isCorrect
                                          ? Colors.green
                                          : const Color.fromARGB(255, 223, 102, 102)).withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              _isViewingPreviousLevel
                                  ? _getPreviousLevelMessage()
                                  : _isCorrect
                                      ? (widget.isEnglish ? 'Correct!' : 'Rätt!')
                                      : (widget.isEnglish ? 'Incorrect!' : 'Fel!'),
                              style: GoogleFonts.ibmPlexMono(
                                color: Colors.white, // White text for contrast
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
                    if (!_isIncorrect && !_isCorrect && !_isViewingPreviousLevel) ...[
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
                              onTap: () async {
                                setState(() {
                                  _isIncorrect = false; // Don't show "Fel" for "I don't know"
                                  _isCorrect = false;
                                  _pressedIDontKnow = true;
                                });
                                await _saveLevelHistory();
                                _goToNextQuestion(context);
                              },
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
                    // "Nästa fråga" knappen (fel svar eller "jag vet inte")
                    else if ((_isIncorrect || _pressedIDontKnow) && !_isViewingPreviousLevel)
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
                    else if (_isCorrect && !_isViewingPreviousLevel)
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
                      )
                    // "Back to current level" button when viewing previous levels
                    else if (_isViewingPreviousLevel)
                      Expanded(
                        child: Container(
                          height: 56,
                          decoration: BoxDecoration(
                            color: _newColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: _newColor.withOpacity(0.25), width: 1.5),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () => _goToLevel(_maxReachedLevel),
                              child: Center(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      widget.isEnglish
                                          ? 'Back to Level $_maxReachedLevel'
                                          : 'Tillbaka till Nivå $_maxReachedLevel',
                                      style: GoogleFonts.ibmPlexMono(
                                        color: _newColor,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Icon(Icons.arrow_forward_rounded, color: _newColor, size: 18),
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
          // Confetti widget
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: 1.57, // Downward
              particleDrag: 0.05,
              emissionFrequency: 0.05,
              numberOfParticles: 50,
              gravity: 0.3,
              shouldLoop: false,
              colors: const [
                Colors.green,
                Colors.blue,
                Colors.pink,
                Colors.orange,
                Colors.purple,
                Colors.yellow,
                Colors.red,
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Övriga metoder (_getClueText, _checkAnswer, _goToNextQuestion) är oförändrade ---
  String _getClueText() {
    // Show loading message while AI clues are being generated
    if (_isLoadingAiClues) {
      return widget.isEnglish 
          ? 'Generating clues...'
          : 'Genererar ledtrådar...';
    }
    
    // Use AI clues if available
    if (_aiClues.isNotEmpty) {
      final clueIndex = (_currentLevel - 1) % _aiClues.length;
      return _aiClues[clueIndex];
    }
    
    // Fallback to API hints only if AI failed
    if (widget.animal.hints.isNotEmpty) {
      final hintIndex = (_currentLevel - 1) % widget.animal.hints.length;
      return widget.animal.hints[hintIndex];
    }
    
    return widget.isEnglish 
        ? 'Can you guess this animal?'
        : 'Kan du gissa detta djur?';
  }

  Future<void> _checkAnswer() async {
    // Don't check answers when viewing previous levels
    if (_isViewingPreviousLevel) {
      return;
    }
    
    final answer = _searchController.text.trim().toLowerCase();
    final correctAnswer = widget.animal.name.toLowerCase();

    if (answer == correctAnswer || answer == widget.animal.scientificName.toLowerCase()) {
      setState(() {
        _isCorrect = true; _isIncorrect = false; _selectedAnswer = _searchController.text.trim();
        _pressedIDontKnow = false;
        _searchFocusNode.unfocus();
      });

      // Trigger confetti animation
      _confettiController.play();

      // Add delay before transitioning to result screen
      Timer(const Duration(milliseconds: 1500), () {
        if (mounted) {
          _goToResultScreen(context);
        }
      });
    } else {
      setState(() {
        _isIncorrect = true; _isCorrect = false;
        _pressedIDontKnow = false;
        _searchFocusNode.unfocus(); _filtered = const [];
      });
    }
    await _saveLevelHistory();
  }
  
  void _goToResultScreen(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => QuizResultScreen(
          animal: widget.animal,
          isEnglish: widget.isEnglish,
          isCorrect: _isCorrect,
          hintIndex: widget.questionIndex,
          totalHints: widget.totalQuestions,
          aiClues: _aiClues,
        ),
      ),
    );
  }

 void _goToNextQuestion(BuildContext context) {
    final int nextIndex = _currentLevel + 1;

    print('DEBUG: Going to next question. Current: $_currentLevel, Next: $nextIndex');
    // Kontrollera om vi är på sista frågan ELLER om svaret var korrekt
    if (nextIndex > widget.totalQuestions || _isCorrect) {
      // Gå till resultatskärmen
      Navigator.of(context).pushReplacement( // Använd pushReplacement för att ersätta quiz-skärmen
        MaterialPageRoute(
          builder: (_) => QuizResultScreen(
            animal: widget.animal, 
            isEnglish: widget.isEnglish, 
            isCorrect: _isCorrect,
            hintIndex: _isCorrect ? _currentLevel : widget.totalQuestions, // Korrekt index till resultat
            totalHints: widget.totalQuestions,
            aiClues: _aiClues, // Add the missing aiClues parameter
          ),
        ),
      );
    } else {
      // Gå till nästa fråga (ersätt nuvarande skärm)
      setState(() {
        _currentLevel = nextIndex;
        _maxReachedLevel = nextIndex; // Update max reached level to the new level
        _isViewingPreviousLevel = false;
      });
      _loadLevelData(); // Call _loadLevelData
    }
  }

  // Level navigation methods
  void _goToLevel(int levelNumber) {
    print('DEBUG: Attempting to navigate to level $levelNumber');
    print('DEBUG: Max reached level: $_maxReachedLevel');
    print('DEBUG: Current level history: $_levelHistory');

    if (levelNumber <= _maxReachedLevel) {
      setState(() {
        _currentLevel = levelNumber;
        _isViewingPreviousLevel = levelNumber < _maxReachedLevel;
        print('DEBUG: Successfully navigated to level $levelNumber');
        print('DEBUG: isViewingPreviousLevel: $_isViewingPreviousLevel');
      });
      _loadLevelData();
    } else {
      print('DEBUG: Cannot navigate to level $levelNumber - not yet reached');
    }
  }

  void _loadLevelHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final levelHistoryJson = prefs.getString('level_history_${widget.animal.name}');
    final maxReached = prefs.getInt('max_reached_level_${widget.animal.name}') ?? widget.questionIndex;

    if (levelHistoryJson != null) {
      try {
        final List<dynamic> levelHistoryList = jsonDecode(levelHistoryJson);
        _levelHistory = levelHistoryList.cast<Map<String, dynamic>>();
        _maxReachedLevel = maxReached;
      } catch (e) {
        _levelHistory = [];
      }
    }
    _loadLevelData();
  }

  void _loadLevelData() {
    print('DEBUG: Loading level data for level $_currentLevel');
    print('DEBUG: Full level history: $_levelHistory');

    Map<String, dynamic>? levelData;
    try {
      levelData = _levelHistory.firstWhere(
        (level) => level['levelIndex'] == _currentLevel,
      );
    } catch (e) {
      levelData = null;
    }

    print('DEBUG: Level data found: $levelData');

    if (levelData != null && levelData.isNotEmpty) {
      final answer = levelData['answer'] ?? '';
      final isCorrect = levelData['isCorrect'] ?? false;
      final isIncorrect = levelData['isIncorrect'] ?? false;
      final pressedIDontKnow = levelData['pressedIDontKnow'] ?? false;

      print('DEBUG: Loading previous answer: "$answer", isCorrect: $isCorrect, isIncorrect: $isIncorrect, pressedIDontKnow: $pressedIDontKnow');

      setState(() {
        if (pressedIDontKnow) {
          _searchController.text = widget.isEnglish ? 'did not answer' : 'svarade inte';
        } else {
          _searchController.text = answer;
        }
        _isCorrect = isCorrect;
        _isIncorrect = isIncorrect;
        _pressedIDontKnow = pressedIDontKnow;
      });
    } else {
      print('DEBUG: No level data found, showing blank field');
      setState(() {
        _searchController.clear();
        _isCorrect = false;
        _isIncorrect = false;
        _selectedAnswer = null;
      });
    }
  }

  Future<void> _saveLevelHistory() async {
    final answer = _searchController.text.trim();

    final levelData = {
      'levelIndex': _currentLevel,
      'answer': answer,
      'isCorrect': _isCorrect,
      'isIncorrect': _isIncorrect,
      'pressedIDontKnow': _pressedIDontKnow,
      'timestamp': DateTime.now().toIso8601String(),
    };

    _levelHistory.removeWhere((level) => level['levelIndex'] == _currentLevel);
    _levelHistory.add(levelData);

    final prefs = await SharedPreferences.getInstance();
    final levelHistoryJson = jsonEncode(_levelHistory);
    await prefs.setString('level_history_${widget.animal.name}', levelHistoryJson);
    await prefs.setInt('max_reached_level_${widget.animal.name}', _maxReachedLevel);

    // Update the max reached level if we're on the current level (not viewing previous levels)
    if (!_isViewingPreviousLevel) {
      _maxReachedLevel = _currentLevel; // Update max reached level to the current level
      print('DEBUG: Updated max reached level to: $_maxReachedLevel');
    }
  }

  // Helper methods for previous level display
  String _getPreviousLevelMessage() {
    try {
      final levelData = _levelHistory.firstWhere(
        (level) => level['levelIndex'] == _currentLevel,
      );
      
      final isCorrect = levelData['isCorrect'] ?? false;
      final pressedIDontKnow = levelData['pressedIDontKnow'] ?? false;
      
      if (isCorrect) {
        return widget.isEnglish ? 'Correct!' : 'Rätt!';
      } else if (pressedIDontKnow) {
        return ''; // No message for "I don't know"
      } else {
        return widget.isEnglish ? 'Incorrect!' : 'Fel!';
      }
    } catch (e) {
      return widget.isEnglish ? 'No answer' : 'Inget svar';
    }
  }

  Color _getPreviousLevelColor() {
    try {
      final levelData = _levelHistory.firstWhere(
        (level) => level['levelIndex'] == _currentLevel,
      );
      
      final isCorrect = levelData['isCorrect'] ?? false;
      final pressedIDontKnow = levelData['pressedIDontKnow'] ?? false;
      
      if (isCorrect) {
        return Colors.green;
      } else if (pressedIDontKnow) {
        return Colors.transparent; // No background for "I don't know"
      } else {
        return const Color.fromARGB(255, 223, 102, 102); // Red for incorrect
      }
    } catch (e) {
      return Colors.grey;
    }
  }

  bool _shouldShowPreviousLevelMessage() {
    try {
      final levelData = _levelHistory.firstWhere(
        (level) => level['levelIndex'] == _currentLevel,
      );
      
      final isCorrect = levelData['isCorrect'] ?? false;
      final pressedIDontKnow = levelData['pressedIDontKnow'] ?? false;
      
      // Only show message for correct or incorrect answers, not for "I don't know"
      return isCorrect || (!pressedIDontKnow && !isCorrect);
    } catch (e) {
      return false;
    }
  }
} // Slut på _QuizScreenState