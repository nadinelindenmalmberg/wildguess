import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart'; // <<< KORREKT IMPORT
import 'package:google_fonts/google_fonts.dart';
import '../models/animal_data.dart';
import '../services/ai_clue_service.dart';
import '../services/api_service.dart';
import '../core/theme.dart';
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
    super.key, // Använder super parameter
    required this.animal,
    required this.isEnglish,
    this.questionIndex = 1,
    this.totalQuestions = 5,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

// Extends State<QuizScreen> korrekt
class _QuizScreenState extends State<QuizScreen> {
  // Definiera färgen som ska ersätta vitt
  static const Color _newColor = Color(0xFFE7EFE7);

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final AiClueService _aiClueService = AiClueService();
  final ApiService _apiService = ApiService();

  List<String> _aiClues = [];
  bool _isLoadingAiClues = false;

  List<AnimalData> _searchResults = []; // Behålls för ev. framtida bruk
  List<String> _filtered = const [];
  bool _isSearching = false;
  bool _hasChosenSuggestion = false; // Behålls för ev. framtida bruk
  bool _isIncorrect = false;
  bool _isCorrect = false;
  
  // Time tracking for scoring
  DateTime? _quizStartTime;
  int _totalTimeMs = 0;
  String? _selectedAnswer; // Behålls för ev. framtida bruk
  bool _pressedIDontKnow = false;
  
  int _currentLevel = 1;
  int _maxReachedLevel = 1;
  bool _isViewingPreviousLevel = false;
  List<Map<String, dynamic>> _levelHistory = [];
  
  late ConfettiController _confettiController;
  Timer? _searchDebounceTimer;
  bool _isKeyboardVisible = false;

  @override
  void initState() {
    super.initState(); // Korrekt super-anrop
    _searchController.addListener(_onQueryChanged);
    _searchFocusNode.addListener(_onFocusChange);
    _generateAiClues();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
    
    _currentLevel = widget.questionIndex;
    _maxReachedLevel = widget.questionIndex;
    _loadLevelHistory();
    
    // Start time tracking
    _quizStartTime = DateTime.now();
  }

  void _onFocusChange() {
    if (mounted) { // mounted är tillgänglig i State klassen
      setState(() { // setState är tillgänglig i State klassen
        _isKeyboardVisible = _searchFocusNode.hasFocus;
      });
    }
  }

  Future<void> _generateAiClues() async {
    if (_aiClues.isNotEmpty) return;
    
    setState(() {
      _isLoadingAiClues = true;
    });

    try {
      final clues = await _aiClueService.generateClues(
        widget.animal, // widget är tillgänglig i State klassen
        isEnglish: widget.isEnglish,
      );
      
      if (mounted) {
        setState(() {
          _aiClues = clues;
          _isLoadingAiClues = false;
        });
      }
    } catch (e) {
      print('Failed to generate AI clues: $e'); // Print är ok under utveckling
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
    _searchFocusNode.removeListener(_onFocusChange);
    _searchController.dispose();
    _searchFocusNode.dispose();
    _aiClueService.dispose();
    _apiService.dispose();
    _confettiController.dispose();
    super.dispose(); // Korrekt super-anrop
  }

  void _clearSearchResults() {
    setState(() {
      _filtered = const [];
      _searchResults = [];
      _hasChosenSuggestion = false;
      _isIncorrect = false;
      _isCorrect = false;
      _selectedAnswer = null;
      _isSearching = false;
    });
  }

  void _onQueryChanged() {
    final query = _searchController.text.trim();
    _searchDebounceTimer?.cancel();
    
    if (query.isEmpty) {
      _clearSearchResults();
      return;
    }
    
    if (query.length < 2) {
      _clearSearchResults();
      return;
    }
    
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
            // *** UPPDATERAD (från tidigare): .take(3) borttagen ***
            _filtered = results.map((animal) => animal.name).toList();
            _isSearching = false;
          });
        }
      } catch (e) {
        if (mounted) {
          _clearSearchResults();
          print('Search error: $e'); // Print är ok under utveckling
        }
      }
    });
  }

  void _showHowToPlayDialog(BuildContext context) {
    final String title = widget.isEnglish ? 'How to Play' : 'Hur man spelar';
    final List<Map<String, String>> instructions = [
       {
        'title_en': 'Guess the Animal', 'title_sv': 'Gissa Djuret',
        'body_en': 'You will be presented with 5 questions in decreasing difficulty, about a specific swedish mammal. Your goal is simple: guess the animal!',
        'body_sv': 'Du kommer att presenteras med 5 frågor i fallande svårighetsgrad, om ett specifikt svenskt däggdjur. Ditt mål är enkelt: gissa djuret!',
      },
      {
        'title_en': 'Daily game', 'title_sv': 'Dagligt spel',
        'body_en': 'You can play the game once per day. After 24 hours, you will be able to play the game again, with a new animal.',
        'body_sv': 'Du kan spela spelet en gång per dag. Efter 24 timmar kommer du att kunna spela spelet igen, med ett nytt djur.',
      },
      {
        'title_en': 'Highest Score', 'title_sv': 'Högsta Poängen',
        'body_en': 'The fewer guesses it takes to guess the correct animal, the higher your score will be!',
        'body_sv': 'Ju färre frågor du använder för att gissa det korrekta djuret, desto högre blir din poäng!',
      },
      {
        'title_en': 'One Chance Only', 'title_sv': 'Bara en chans',
        'body_en': 'You get only one attempt to submit your final guess per question. Make sure you are confident before you lock it in!',
        'body_sv': 'Du får bara ett försök att skicka in din slutgiltiga gissning per fråga. Se till att du är säker innan du låser den!',
      },
    ];

    showDialog( // showDialog är tillgänglig via material.dart
      context: context,
      barrierColor: Colors.black.withOpacity(0.75), // Colors är tillgänglig
      builder: (BuildContext context) {
        return Theme( // Theme är tillgänglig
          data: ThemeData.dark().copyWith( // ThemeData är tillgänglig
            textTheme: GoogleFonts.ibmPlexMonoTextTheme(
              ThemeData.dark().textTheme,
            ).copyWith(
              titleLarge: const TextStyle(color: _newColor, fontWeight: FontWeight.w700), // TextStyle, FontWeight är tillgängliga
              bodyMedium: TextStyle(color: _newColor.withOpacity(0.8)),
            ), dialogTheme: DialogThemeData(backgroundColor: const Color(0xFF1E1E1E)), // DialogThemeData är tillgänglig
          ),
          child: AlertDialog( // AlertDialog är tillgänglig
            shape: RoundedRectangleBorder( // RoundedRectangleBorder är tillgänglig
              borderRadius: BorderRadius.circular(16), // BorderRadius är tillgänglig
              side: BorderSide(color: _newColor.withOpacity(0.2)), // BorderSide är tillgänglig
            ),
            title: Text( // Text är tillgänglig
              title,
              textAlign: TextAlign.center, // TextAlign är tillgänglig
              ),
            titlePadding: const EdgeInsets.only(top: 24, bottom: 16), // EdgeInsets är tillgänglig
            contentPadding: const EdgeInsets.only(left: 24, right: 24, top: 20),
            content: ConstrainedBox( // ConstrainedBox är tillgänglig
              constraints: BoxConstraints( // BoxConstraints är tillgänglig
                maxHeight: MediaQuery.of(context).size.height * 0.7, // MediaQuery är tillgänglig
              ),
              child: SingleChildScrollView( // SingleChildScrollView är tillgänglig
                child: Column( // Column är tillgänglig
                  mainAxisSize: MainAxisSize.min, // MainAxisSize är tillgänglig
                  children: instructions.map((step) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Row( // Row är tillgänglig
                        crossAxisAlignment: CrossAxisAlignment.start, // CrossAxisAlignment är tillgänglig
                        children: [
                          const Icon( // Icon är tillgänglig
                            Icons.check_circle_outline, // Icons är tillgänglig
                            color: Color(0xFF10B981),
                            size: 22,
                          ),
                          const SizedBox(width: 12), // SizedBox är tillgänglig
                          Expanded( // Expanded är tillgänglig
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
                                    color: _newColor,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  widget.isEnglish
                                      ? step['body_en']!
                                      : step['body_sv']!,
                                  style: GoogleFonts.ibmPlexMono(
                                    fontSize: 15,
                                    color: _newColor.withOpacity(0.7),
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
              TextButton( // TextButton är tillgänglig
                child: Text(
                  'OK',
                  style: GoogleFonts.ibmPlexMono(
                    color: _newColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pop(); // Navigator är tillgänglig
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

    return Scaffold( // Scaffold är tillgänglig
      backgroundColor: Colors.black,
      body: Stack( // Stack är tillgänglig
        children: [
          Container( // Container är tillgänglig
        color: Colors.black,
            child: SafeArea( // SafeArea är tillgänglig
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
                // *** INGEN Expanded/SingleChildScrollView här ***
                child: Column( // Huvud-Column
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                    // Header med knappar
                Row(
                  children: [
                    Container(
                          decoration: BoxDecoration(color: _newColor.withOpacity(0.08), borderRadius: BorderRadius.circular(12)), // BoxDecoration är tillgänglig
                          child: IconButton( // IconButton är tillgänglig
                            icon: const Icon(Icons.home_rounded, size: 20),
                            color: _newColor,
                            onPressed: () => Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (context) => const HomeScreen()), (Route<dynamic> route) => false), // MaterialPageRoute, Route är tillgängliga
                            style: IconButton.styleFrom(padding: const EdgeInsets.all(8), minimumSize: const Size(40, 40)), // Size är tillgänglig
                          ),
                        ),
                        const Spacer(), // Spacer är tillgänglig
                    Container(
                          decoration: BoxDecoration(color: _newColor.withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
                      child: IconButton(
                        icon: const Icon(Icons.info_outline_rounded, size: 20),
                            color: _newColor,
                            onPressed: () => _showHowToPlayDialog(context),
                            style: IconButton.styleFrom(padding: const EdgeInsets.all(8), minimumSize: const Size(40, 40)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                
                    // Frågetitel
                    Center( // Center är tillgänglig
                  child: Text(
                    titleText,
                    style: GoogleFonts.ibmPlexMono(
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                          color: _newColor,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                    // Level navigation indicators (Göms med Visibility)
                    Visibility( // Visibility är tillgänglig
                      visible: !_isKeyboardVisible, // Använder state-variabeln
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(widget.totalQuestions, (index) {
                                final clueNumber = index + 1;
                                final isCurrentLevel = clueNumber == _currentLevel;
                                final isUnlocked = clueNumber <= _maxReachedLevel;
                                final hasAnswer = _levelHistory.any((level) => level['levelIndex'] == clueNumber);
                                final isCorrect = hasAnswer ? _levelHistory.firstWhere((level) => level['levelIndex'] == clueNumber)['isCorrect'] : false;

                                return GestureDetector( // GestureDetector är tillgänglig
                                  onTap: clueNumber <= _maxReachedLevel ? () => _goToLevel(clueNumber) : null,
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 4),
                                    width: isCurrentLevel ? 50 : 40,
                                    height: isCurrentLevel ? 50 : 40,
                      decoration: BoxDecoration(
                                      color: isCurrentLevel
                                          ? Colors.white
                                          : hasAnswer
                                              ? (isCorrect ? Colors.green : Colors.red)
                                              : Colors.grey[600],
                                      borderRadius: BorderRadius.circular(isCurrentLevel ? 25 : 20),
                                      border: isCurrentLevel
                                          ? Border.all(color: _newColor, width: 3) // Border är tillgänglig
                                          : null,
                                      boxShadow: isCurrentLevel
                                          ? [
                                              BoxShadow( // BoxShadow är tillgänglig
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
                                                        : Colors.grey[500],
                                              ),
                                            ),
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ),
                          const SizedBox(height: 24), // Denna SizedBox göms också
                        ],
                      ),
                    ),
                    

                    // Centrerad sektion
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 380),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                            // Ledtrådskort (Anpassas med _isKeyboardVisible)
                            AnimatedContainer( // AnimatedContainer är tillgänglig
                              duration: const Duration(milliseconds: 300), // Duration är tillgänglig
                              width: double.infinity,
                              padding: EdgeInsets.all(_isKeyboardVisible ? 12 : 18), // Dynamisk padding
                          decoration: BoxDecoration(
                                color: Colors.black,
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                                  color: Colors.white.withOpacity(0.2),
                              width: 1,
                            ),
                                boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                    offset: const Offset(0, 4), // Offset är tillgänglig
                              ),
                            ],
                          ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                                  AnimatedDefaultTextStyle( // AnimatedDefaultTextStyle är tillgänglig
                                    duration: const Duration(milliseconds: 300),
                                  style: GoogleFonts.ibmPlexMono(
                                      fontSize: 18,
                                      color: Colors.white,
                                      height: 1.5,
                                    ),
                                    child: Text(
                                      _getClueText(),
                                      textAlign: TextAlign.center,
                                      maxLines: _isKeyboardVisible ? 1 : 5, // Dynamisk maxLines
                                      overflow: _isKeyboardVisible         // Dynamisk overflow
                                          ? TextOverflow.ellipsis         // TextOverflow är tillgänglig
                                          : TextOverflow.visible,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Search input field
                            TextField( // TextField är tillgänglig
                              controller: _searchController,
                              focusNode: _searchFocusNode,
                              enabled: !_isViewingPreviousLevel,
                              decoration: InputDecoration( // InputDecoration är tillgänglig
                                hintText: _isViewingPreviousLevel
                                    ? (widget.isEnglish ? 'Previous answer shown above' : 'Tidigare svar visas ovan')
                                    : (widget.isEnglish ? 'Type your guess here...' : 'Skriv din gissning här...'),
                                    hintStyle: GoogleFonts.ibmPlexMono(
                                  color: _isViewingPreviousLevel ? Colors.grey[400] : Colors.grey[500],
                                  fontSize: 16,
                                ),
                                filled: true,
                                fillColor: _isViewingPreviousLevel ? Colors.grey[200] : Colors.white,
                                border: OutlineInputBorder( // OutlineInputBorder är tillgänglig
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
                              textInputAction: TextInputAction.done, // TextInputAction är tillgänglig
                              onSubmitted: (_) => _checkAnswer(),
                            ),
                            
                            // Search suggestions dropdown
                            AnimatedSwitcher( // AnimatedSwitcher är tillgänglig
                          duration: const Duration(milliseconds: 180),
                              child: _searchFocusNode.hasFocus && !_isIncorrect && !_isCorrect
                              ? Container(
                                      key: const ValueKey('suggestions'), // ValueKey är tillgänglig
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
                                                    width: 16, height: 16,
                                                    child: CircularProgressIndicator( // CircularProgressIndicator är tillgänglig
                                                      strokeWidth: 2,
                                                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1F2937)), // AlwaysStoppedAnimation är tillgänglig
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
                                                  constraints: const BoxConstraints(
                                                    maxHeight: 150, // Fast maxhöjd för skroll
                                                  ),
                                                  decoration: BoxDecoration(
                                                    border: Border.all(color: Colors.black12),
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  child: ListView.separated( // ListView är tillgänglig
                                                    physics: const BouncingScrollPhysics(), // ScrollPhysics är tillgänglig
                                    shrinkWrap: true,
                                    itemCount: _filtered.length,
                                                    separatorBuilder: (_, __) => const Divider(height: 1, color: Colors.black12), // Divider är tillgänglig
                                                    // *** UPPDATERAD ITEMBUILDER: Latinskt namn borttaget ***
                                    itemBuilder: (context, index) {
                                      final suggestion = _filtered[index];
                                                      return InkWell( // InkWell är tillgänglig
                                        borderRadius: index == 0 || index == _filtered.length - 1
                                            ? BorderRadius.only(
                                                                topLeft: Radius.circular(index == 0 ? 12 : 0), // Radius är tillgänglig
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
                                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), // Justerad padding
                                                          child: Text( // Endast Text-widgeten kvar
                                              suggestion,
                                              style: GoogleFonts.ibmPlexMono(
                                                              fontSize: 15,
                                                              color: const Color(0xFF1F2937),
                                                              fontWeight: FontWeight.w600,
                                              ),
                                                            maxLines: 1,
                                                            overflow: TextOverflow.ellipsis,
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
                                                  : const SizedBox.shrink(), // .shrink() är en const constructor
                                )
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),
                ),
                
                    // *** BEHÅLLER SPACER HÄR ***
                    // Rätt/Fel-meddelande eller Spacer
                    if (_isCorrect || _isIncorrect || (_isViewingPreviousLevel && _shouldShowPreviousLevelMessage())) ...[
                  const SizedBox(height: 24),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                              color: _isViewingPreviousLevel
                                  ? _getPreviousLevelColor()
                                  : _isCorrect
                                      ? Colors.green
                                      : const Color.fromARGB(255, 223, 102, 102),
                        borderRadius: BorderRadius.circular(12),
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
                          color: Colors.white,
                                fontSize: 24,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                        const Spacer(), // Spacer efter meddelandet
                ] else ...[
                        const Spacer(), // Spacer när inget meddelande visas
                ],
                

                    // Knappar (ligger kvar längst ner tack vare Spacer)
                Row(
                  children: [
                        if (!_isIncorrect && !_isCorrect && !_isViewingPreviousLevel) ...[
                          // "Jag vet inte" button
                          Expanded(
                            child: Container(
                        height: 56,
                        decoration: BoxDecoration(
                                color: _newColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: _newColor.withOpacity(0.25), width: 1.5),
                          ),
                              child: Material( // Material är tillgänglig
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                                  onTap: () async {
                                    setState(() {
                                      _isIncorrect = false;
                                      _isCorrect = false;
                                      _pressedIDontKnow = true;
                                    });
                                    await _saveLevelHistory();
                              _goToNextQuestion(context);
                            },
                            child: Center(
                              child: Text(
                                widget.isEnglish ? "I don't know" : "Jag vet inte",
                                      style: GoogleFonts.ibmPlexMono(color: _newColor, fontSize: 16, fontWeight: FontWeight.w500),
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
                                color: _newColor,
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
                                        Text(widget.totalQuestions >= _currentLevel + 1 // Fixat logik
                                            ? (widget.isEnglish ? 'Next question' : 'Nästa fråga')
                                            : (widget.isEnglish ? 'Finish & See Results' : 'Slutför och se resultat'),
                                          style: GoogleFonts.ibmPlexMono(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w600)),
                                      const SizedBox(width: 8),
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
                              color: const Color(0xFF10B981),
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
                                        Text(widget.totalQuestions >= _currentLevel + 1 // Fixat logik
                                            ? (widget.isEnglish ? 'Next question' : 'Nästa fråga')
                                            : (widget.isEnglish ? 'Finish & See Results' : 'Slutför och se resultat'),
                                          style: GoogleFonts.ibmPlexMono(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                                      const SizedBox(width: 8),
                                        const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                                      ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      )
                        // "Back to current level" button
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
                                          widget.isEnglish ? 'Back to Level $_maxReachedLevel' : 'Tillbaka till Nivå $_maxReachedLevel',
                                style: GoogleFonts.ibmPlexMono(
                                            color: _newColor, fontSize: 16, fontWeight: FontWeight.w600
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
                    const SizedBox(height: 16), // Padding längst ner
              ],
            ),
          ),
        ),
          ),
          // Confetti widget
          Align( // Align är tillgänglig
            alignment: Alignment.topCenter, // Alignment är tillgänglig
            child: ConfettiWidget( // ConfettiWidget från externt paket
              confettiController: _confettiController,
              blastDirection: 1.57, // pi/2
              particleDrag: 0.05,
              emissionFrequency: 0.05,
              numberOfParticles: 50,
              gravity: 0.3,
              shouldLoop: false,
              colors: const [ // Konstanter för färger
                Colors.green, Colors.blue, Colors.pink, Colors.orange, Colors.purple, Colors.yellow, Colors.red,
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Övriga metoder (oförändrade från tidigare, inga layout-widgets här) ---
  String _getClueText() {
    if (_isLoadingAiClues) {
      return widget.isEnglish ? 'Generating clues...' : 'Genererar ledtrådar...';
    }
    if (_aiClues.isNotEmpty) {
      final clueIndex = (_currentLevel - 1) % _aiClues.length;
      return _aiClues[clueIndex];
    }
    if (widget.animal.hints.isNotEmpty) {
      final hintIndex = (_currentLevel - 1) % widget.animal.hints.length;
      return widget.animal.hints[hintIndex];
    }
    return widget.isEnglish ? 'Can you guess this animal?' : 'Kan du gissa detta djur?';
  }

  Future<void> _checkAnswer() async {
    if (_isViewingPreviousLevel) return;
    
    final answer = _searchController.text.trim().toLowerCase();
    final correctAnswer = widget.animal.name.toLowerCase();
    final correctSciName = widget.animal.scientificName.toLowerCase();
    
    if (answer == correctAnswer || (correctSciName.isNotEmpty && answer == correctSciName)) {
      setState(() {
        _isCorrect = true; _isIncorrect = false; _selectedAnswer = _searchController.text.trim();
        _pressedIDontKnow = false;
        _searchFocusNode.unfocus();
      });
      _confettiController.play();
      // Add a delay to let the user see the confetti and correct answer
      Future.delayed(const Duration(milliseconds: 2000), () {
        if (mounted) {
          _goToResultScreen(context);
        }
      });
    } else {
      setState(() {
        _isIncorrect = true; _isCorrect = false;
        _pressedIDontKnow = false;
        _searchFocusNode.unfocus(); 
        _filtered = const [];
        _searchResults = [];
      });
      // If this is the last question and answer is wrong, go to next question to trigger failure logic
      if (_currentLevel >= widget.totalQuestions) {
        _goToNextQuestion(context);
      }
    }
    await _saveLevelHistory();
  }
  
  void _goToResultScreen(BuildContext context) {
    // Calculate total time
    final int totalTimeMs = _quizStartTime != null 
        ? DateTime.now().difference(_quizStartTime!).inMilliseconds
        : 0;
    
    Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => QuizResultScreen(
            animal: widget.animal,
            isEnglish: widget.isEnglish,
            isCorrect: _isCorrect,
            hintIndex: _isCorrect ? _currentLevel : _currentLevel, // Use actual current level for both success and failure
            totalHints: widget.totalQuestions,
            aiClues: _aiClues,
            totalTimeMs: totalTimeMs,
          ),
        ),
      );
    }

 void _goToNextQuestion(BuildContext context) {
    final int nextIndex = _currentLevel + 1;

    // Om svaret var korrekt, gå ALLTID till resultat
    if (_isCorrect) {
       _goToResultScreen(context);
       return;
    }

    // Om det var sista frågan (och svaret var fel eller "vet inte")
    if (nextIndex > widget.totalQuestions) {
       // User failed on the last question, mark as not solved
       setState(() {
         _isCorrect = false;
         _isIncorrect = false; // Clear incorrect state for final result
       });
       _goToResultScreen(context); // Gå till resultat ändå
    } else {
      // Gå till nästa fråga
      setState(() {
        _currentLevel = nextIndex;
        _maxReachedLevel = nextIndex;
        _isViewingPreviousLevel = false;
        // Återställ fält och status för nästa fråga
        _searchController.clear();
        _isCorrect = false;
        _isIncorrect = false;
        _pressedIDontKnow = false;
        _clearSearchResults();
      });
      // Behöver inte ladda level data eftersom vi går till en ny, tom nivå
      // _loadLevelData(); // Tas bort
    }
  }

  void _goToLevel(int levelNumber) {
    if (levelNumber <= _maxReachedLevel) {
      setState(() {
        _currentLevel = levelNumber;
        _isViewingPreviousLevel = levelNumber < _maxReachedLevel;
      });
      _loadLevelData(); // Ladda data för den valda nivån
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
        _maxReachedLevel = maxReached > _currentLevel ? maxReached : _currentLevel; // Säkerställ att maxReached är minst current
      } catch (e) {
        _levelHistory = [];
        _maxReachedLevel = _currentLevel;
      }
    } else {
        _maxReachedLevel = _currentLevel;
    }
    // Ladda data för aktuell nivå efter att historiken är laddad
    _loadLevelData();
  }

  void _loadLevelData() {
     Map<String, dynamic>? levelData;
    try {
      levelData = _levelHistory.firstWhere(
        (level) => level['levelIndex'] == _currentLevel,
        orElse: () => {}, // Returnera tom map om inget hittas
      );
    } catch (e) {
      levelData = {}; // Fånga ev. fel och returnera tom map
    }

    if (levelData != null && levelData.isNotEmpty) {
      final answer = levelData['answer'] ?? '';
      final isCorrect = levelData['isCorrect'] ?? false;
      final isIncorrect = levelData['isIncorrect'] ?? false;
      final pressedIDontKnow = levelData['pressedIDontKnow'] ?? false;

      setState(() {
        if (pressedIDontKnow) {
          _searchController.text = widget.isEnglish ? 'Skipped' : 'svarade inte'; // Tydligare text
        } else {
          _searchController.text = answer;
        }
        _isCorrect = isCorrect;
        _isIncorrect = isIncorrect;
        _pressedIDontKnow = pressedIDontKnow;
      });
    } else {
      // Om ingen data finns (ny nivå eller historik saknas)
      setState(() {
        _searchController.clear();
        _isCorrect = false;
        _isIncorrect = false;
        _pressedIDontKnow = false; // Säkerställ återställning
        _selectedAnswer = null;
      });
    }
  }

  Future<void> _saveLevelHistory() async {
    // Spara endast om vi är på den aktuella max-nivån (inte tittar bakåt)
    if (_isViewingPreviousLevel) return;

    final answer = _searchController.text.trim();

    // Hantera fallet där användaren tryckte "Jag vet inte"
    final currentAnswer = _pressedIDontKnow ? '' : answer; // Spara tom sträng vid "vet inte"

    final levelData = {
      'levelIndex': _currentLevel,
      'answer': currentAnswer,
      'isCorrect': _isCorrect,
      'isIncorrect': _isIncorrect, // Spara även om det var fel
      'pressedIDontKnow': _pressedIDontKnow, // Spara om man tryckte "vet inte"
      'timestamp': DateTime.now().toIso8601String(),
    };

    // Uppdatera eller lägg till nivån i historiken
    final index = _levelHistory.indexWhere((level) => level['levelIndex'] == _currentLevel);
    if (index != -1) {
      _levelHistory[index] = levelData; // Uppdatera befintlig
    } else {
      _levelHistory.add(levelData); // Lägg till ny
    }

    // Uppdatera maxReachedLevel endast om vi går framåt
     if (_currentLevel >= _maxReachedLevel) {
       _maxReachedLevel = _currentLevel;
       // Om svaret INTE är korrekt OCH vi INTE är på sista nivån, öka maxReachedLevel för nästa försök
       if (!_isCorrect && _currentLevel < widget.totalQuestions) {
          _maxReachedLevel = _currentLevel + 1;
       }
     }


    final prefs = await SharedPreferences.getInstance();
    final levelHistoryJson = jsonEncode(_levelHistory);
    await prefs.setString('level_history_${widget.animal.name}', levelHistoryJson);
    await prefs.setInt('max_reached_level_${widget.animal.name}', _maxReachedLevel);
  }

  // Helper methods for previous level display
  String _getPreviousLevelMessage() {
    try {
      final levelData = _levelHistory.firstWhere((level) => level['levelIndex'] == _currentLevel);
      final isCorrect = levelData['isCorrect'] ?? false;
      final pressedIDontKnow = levelData['pressedIDontKnow'] ?? false;
      
      if (isCorrect) return widget.isEnglish ? 'Correct!' : 'Rätt!';
      if (pressedIDontKnow) return ''; // Ingen text för "vet inte"
      return widget.isEnglish ? 'Incorrect!' : 'Fel!';
    } catch (e) { return ''; } // Ingen text om data saknas
  }

  Color _getPreviousLevelColor() {
    try {
      final levelData = _levelHistory.firstWhere((level) => level['levelIndex'] == _currentLevel);
      final isCorrect = levelData['isCorrect'] ?? false;
      final pressedIDontKnow = levelData['pressedIDontKnow'] ?? false;
      
      if (isCorrect) return Colors.green;
      if (pressedIDontKnow) return Colors.transparent; // Ingen bakgrund för "vet inte"
      return const Color.fromARGB(255, 223, 102, 102); // Röd för fel
    } catch (e) { return Colors.transparent;} // Ingen bakgrund om data saknas
  }

   bool _shouldShowPreviousLevelMessage() {
    try {
      final levelData = _levelHistory.firstWhere((level) => level['levelIndex'] == _currentLevel);
      // Visa endast meddelande om det INTE var "vet inte"
      return !(levelData['pressedIDontKnow'] ?? false);
    } catch (e) { return false; } // Visa inte om data saknas
  }
} // Slut på _QuizScreenState