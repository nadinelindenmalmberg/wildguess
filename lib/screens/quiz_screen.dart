import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/animal_data.dart';
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

  final List<String> _allAnimals = const [
    'Rabbit',
    'White tailed rabbit',
    'Brown Canadian rabbit',
    'Hare',
    'Arctic hare',
    'Mountain hare',
    'Pika',
    'Mouse',
    'Rat',
    'Squirrel',
    'Fox',
    'Red fox',
    'Arctic fox',
    'Wolf',
    'Bear',
    'Brown bear',
    'Polar bear',
    'Deer',
    'Moose',
    'Elk',
  ];

  List<String> _filtered = const [];
  bool _hasChosenSuggestion = false;
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
        _hasChosenSuggestion = false;
        _isIncorrect = false;
        _isCorrect = false;
        _selectedAnswer = null;
      });
      return;
    }
    setState(() {
      _filtered = _allAnimals
          .where((name) => name.toLowerCase().contains(query))
          .take(6)
          .toList();
      _hasChosenSuggestion = false;
      _isIncorrect = false;
      _isCorrect = false;
      _selectedAnswer = null;
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
                                ? const Color.fromARGB(255, 223, 102, 102) 
                                : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: _isIncorrect 
                                  ? const Color.fromARGB(255, 223, 102, 102).withOpacity(0.3)
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
                        
                        // Suggestions dropdown
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 180),
                          child: _filtered.isNotEmpty && _searchFocusNode.hasFocus && !_isIncorrect && !_isCorrect
                              ? Container(
                                  key: const ValueKey('suggestions'),
                                  margin: const EdgeInsets.only(top: 8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE7EFE7),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: ListView.separated(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: _filtered.length,
                                    separatorBuilder: (_, __) => const Divider(height: 1, color: Colors.black12),
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
                                          _searchController.text = suggestion;
                                          _searchFocusNode.unfocus();
                                          setState(() {
                                            _filtered = const [];
                                            _hasChosenSuggestion = true;
                                            _isIncorrect = false;
                                            _isCorrect = false;
                                            _selectedAnswer = suggestion;
                                          });
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                          child: Align(
                                            alignment: Alignment.centerLeft,
                                            child: Text(
                                              suggestion,
                                              style: GoogleFonts.ibmPlexMono(
                                                fontSize: 16,
                                                color: Colors.black,
                                              ),
                                            ),
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
    if (widget.animal.hints.isNotEmpty) {
      // Show different hints based on question index
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
