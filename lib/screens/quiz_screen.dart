import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/animal_data.dart';
import '../services/ai_clue_service.dart';
import '../services/api_service.dart';
import 'quiz_result_screen.dart';

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
  
  // Debouncing timer to prevent excessive API calls
  Timer? _searchDebounceTimer;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onQueryChanged);
    _generateAiClues();
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
        final results = await _apiService.searchSpecies(query);
        if (mounted) {
          setState(() {
            _searchResults = results;
            _filtered = results.map((animal) => animal.name).take(6).toList();
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

  @override
  Widget build(BuildContext context) {
    final String titleText = widget.isEnglish 
        ? 'Question ${widget.questionIndex}/${widget.totalQuestions}'
        : 'Fråga ${widget.questionIndex}/${widget.totalQuestions}';
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        color: Colors.black,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with back button
                Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                        color: Colors.white,
                        onPressed: () => Navigator.pop(context),
                        style: IconButton.styleFrom(
                          padding: const EdgeInsets.all(8),
                          minimumSize: const Size(40, 40),
                        ),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.info_outline_rounded, size: 20),
                        color: Colors.white,
                        onPressed: () {},
                        style: IconButton.styleFrom(
                          padding: const EdgeInsets.all(8),
                          minimumSize: const Size(40, 40),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                
                // Question title
                Center(
                  child: Text(
                    titleText,
                    style: GoogleFonts.ibmPlexMono(
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Clue card
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 380),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 300),
                            style: GoogleFonts.ibmPlexMono(
                              fontSize: 18,
                              color: Colors.white,
                              height: 1.5,
                            ),
                            child: Text(
                              _getClueText(),
                              textAlign: TextAlign.center,
                              maxLines: _searchController.text.isNotEmpty ? 1 : null,
                              overflow: _searchController.text.isNotEmpty ? TextOverflow.ellipsis : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: _searchController.text.isNotEmpty ? 10 : 24),
                
                // Search field and suggestions
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 380),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          height: 60,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          decoration: BoxDecoration(
                            color: _isIncorrect 
                                ? const Color.fromARGB(255, 235, 88, 88) 
                                : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: _isIncorrect 
                                  ? const Color.fromARGB(255, 235, 88, 88).withOpacity(0.3)
                                  : Colors.white.withOpacity(0.2),
                              width: 1,
                            ),
                            boxShadow: _isIncorrect ? null : [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _searchController,
                                  focusNode: _searchFocusNode,
                                  style: GoogleFonts.ibmPlexMono(
                                    fontSize: 17,
                                    color: _isIncorrect ? Colors.white : const Color(0xFF1F2937),
                                    fontWeight: FontWeight.w500,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: widget.isEnglish ? 'Guess the animal' : 'Gissa djuret',
                                    hintStyle: GoogleFonts.ibmPlexMono(
                                      color: _isIncorrect ? Colors.white70 : const Color(0xFF6B7280),
                                      fontSize: 17,
                                      fontWeight: FontWeight.w400,
                                    ),
                                    border: InputBorder.none,
                                    isCollapsed: true,
                                  ),
                                ),
                              ),
                              if (!_isIncorrect) ...[
                                const SizedBox(width: 12),
                                Icon(
                                  Icons.search_rounded,
                                  color: const Color(0xFF6B7280),
                                  size: 22,
                                ),
                              ],
                            ],
                          ),
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
                                          ? ListView.separated(
                                              shrinkWrap: true,
                                              physics: const NeverScrollableScrollPhysics(),
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
                
                // Show correct/incorrect answer
                if (_isCorrect || _isIncorrect) ...[
                  const SizedBox(height: 24),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _isCorrect 
                            ? (widget.isEnglish ? 'Correct!' : 'Rätt!')
                            : (widget.isEnglish ? 'Incorrect!' : 'Fel!'),
                        style: GoogleFonts.ibmPlexMono(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
                
                if (_isIncorrect) ...[
                  const SizedBox(height: 24),
                ] else if (_isCorrect) ...[
                  const SizedBox(height: 24),
                ] else ...[
                  const Spacer(),
                ],
                
                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (!_isIncorrect && !_isCorrect) ...[
                      Container(
                        height: 56,
                        width: 180,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.25),
                            width: 1.5,
                          ),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              _goToNextQuestion(context);
                            },
                            child: Center(
                              child: Text(
                                widget.isEnglish ? "I don't know" : "Jag vet inte",
                                style: GoogleFonts.ibmPlexMono(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                    ],
                    
                    if (_isIncorrect)
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Container(
                            height: 56,
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
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
                                      Text(
                                        widget.isEnglish ? 'Next question' : 'Nästa fråga',
                                        style: GoogleFonts.ibmPlexMono(
                                          color: Colors.black,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Icon(
                                        Icons.arrow_forward_rounded,
                                        color: Colors.black,
                                        size: 18,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      )
                    else if (_isCorrect)
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Container(
                            height: 56,
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF10B981).withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
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
                                      Text(
                                        widget.isEnglish ? 'Next question' : 'Nästa fråga',
                                        style: GoogleFonts.ibmPlexMono(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Icon(
                                        Icons.arrow_forward_rounded,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      )
                    else
                      Container(
                        height: 56,
                        width: 100,
                        margin: const EdgeInsets.only(left: 40),
                        decoration: BoxDecoration(
                          color: _hasChosenSuggestion 
                              ? const Color(0xFF10B981)
                              : const Color(0xFF6B7280),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: _hasChosenSuggestion ? [
                            BoxShadow(
                              color: const Color(0xFF10B981).withOpacity(0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ] : null,
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              _checkAnswer();
                            },
                            child: Center(
                              child: Text(
                                widget.isEnglish ? 'Guess' : 'Gissa',
                                style: GoogleFonts.ibmPlexMono(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
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

  String _getClueText() {
    // Show loading message while AI clues are being generated
    if (_isLoadingAiClues) {
      return widget.isEnglish 
          ? 'Generating AI clues...'
          : 'Genererar AI-ledtrådar...';
    }
    
    // Use AI clues if available
    if (_aiClues.isNotEmpty) {
      final clueIndex = (widget.questionIndex - 1) % _aiClues.length;
      return _aiClues[clueIndex];
    }
    
    // Fallback to API hints only if AI failed
    if (widget.animal.hints.isNotEmpty) {
      final hintIndex = (widget.questionIndex - 1) % widget.animal.hints.length;
      return widget.animal.hints[hintIndex];
    }
    
    return widget.isEnglish 
        ? 'Can you guess this animal?'
        : 'Kan du gissa detta djur?';
  }

  void _checkAnswer() {
    final answer = _searchController.text.trim().toLowerCase();
    final correctAnswer = widget.animal.name.toLowerCase();
    
    if (answer == correctAnswer || answer == widget.animal.scientificName.toLowerCase()) {
      setState(() {
        _isCorrect = true;
        _isIncorrect = false;
        _selectedAnswer = _searchController.text.trim();
      });
    } else {
      setState(() {
        _isIncorrect = true;
        _isCorrect = false;
        _searchFocusNode.unfocus();
        _filtered = const [];
      });
    }
  }

  void _goToNextQuestion(BuildContext context) {
    final int nextIndex = widget.questionIndex + 1;
    if (nextIndex <= widget.totalQuestions) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => QuizScreen(
            animal: widget.animal,
            isEnglish: widget.isEnglish,
            questionIndex: nextIndex,
            totalQuestions: widget.totalQuestions,
          ),
        ),
      );
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => QuizResultScreen(
            animal: widget.animal,
            isEnglish: widget.isEnglish,
            isCorrect: _isCorrect,
            questionIndex: widget.questionIndex,
            totalQuestions: widget.totalQuestions,
          ),
        ),
      );
    }
  }
}
