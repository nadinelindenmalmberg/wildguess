import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/animal_data.dart';
import '../services/history_service.dart';
import 'home_screen.dart';
import 'quiz_screen.dart';

class QuizResultScreen extends StatefulWidget {
  final AnimalData animal;
  final bool isEnglish;
  final bool isCorrect;
  final int questionIndex;
  final int totalQuestions;
  final List<String> aiClues;

  const QuizResultScreen({
    super.key,
    required this.animal,
    required this.isEnglish,
    required this.isCorrect,
    required this.questionIndex,
    required this.totalQuestions,
    required this.aiClues,
  });

  @override
  State<QuizResultScreen> createState() => _QuizResultScreenState();
}

class _QuizResultScreenState extends State<QuizResultScreen> {
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _saveGameHistory();
  }

  Future<void> _saveGameHistory() async {
    await HistoryService.saveGameHistory(
      animal: widget.animal,
      isCorrect: widget.isCorrect,
      questionIndex: widget.questionIndex,
      totalQuestions: widget.totalQuestions,
      completedAt: DateTime.now(),
    );
  }

  void _showCluesDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFFE7EFE7),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            widget.isEnglish ? 'AI Clues' : 'AI-ledtrådar',
            style: GoogleFonts.ibmPlexMono(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.animal.name,
                  style: GoogleFonts.ibmPlexMono(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                if (widget.animal.scientificName.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    widget.animal.scientificName,
                    style: GoogleFonts.ibmPlexMono(
                      fontSize: 14,
                      color: Colors.black87,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                // Display AI clues in the same style as the game
                ...widget.aiClues.asMap().entries.map((entry) {
                  int index = entry.key;
                  String hint = entry.value;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.black12, width: 1),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.black,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: GoogleFonts.ibmPlexMono(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            hint,
                            style: GoogleFonts.ibmPlexMono(
                              fontSize: 16,
                              color: Colors.black,
                              height: 1.4,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                widget.isEnglish ? 'Close' : 'Stäng',
                style: GoogleFonts.ibmPlexMono(
                  color: Colors.blue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showFullScreenImage(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Stack(
            children: [
              // Full screen image
              Center(
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 3.0,
                  child: Image.network(
                    widget.animal.imageUrl,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        width: 300,
                        height: 300,
                        color: Colors.black54,
                        child: const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 300,
                        height: 300,
                        color: Colors.black54,
                        child: const Center(
                          child: Icon(Icons.pets, size: 64, color: Colors.white),
                        ),
                      );
                    },
                  ),
                ),
              ),
              // Close button
              Positioned(
                top: 50,
                right: 20,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
              // Animal name overlay
              Positioned(
                bottom: 50,
                left: 20,
                right: 20,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.animal.name,
                        style: GoogleFonts.ibmPlexMono(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (widget.animal.scientificName.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          widget.animal.scientificName,
                          style: GoogleFonts.ibmPlexMono(
                            color: Colors.white70,
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        color: Colors.black,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header - No back button, game is over
                const SizedBox(height: 20),
                
                // Result title
                Text(
                  widget.isCorrect 
                      ? (widget.isEnglish ? 'You are correct!' : 'Du har rätt!')
                      : (widget.isEnglish ? 'Game Over!' : 'Spelet är slut!'),
                  style: GoogleFonts.ibmPlexMono(
                    fontSize: 32,
                    fontWeight: FontWeight.w400,
                    color: Colors.white,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Animal card
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFE7EFE7),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Animal image (if available)
                      if (widget.animal.imageUrl.isNotEmpty) ...[
                        GestureDetector(
                          onTap: () => _showFullScreenImage(context),
                          child: ClipRRect(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(16),
                              topRight: Radius.circular(16),
                            ),
                            child: Image.network(
                              widget.animal.imageUrl,
                              width: double.infinity,
                              height: 200,
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Container(
                                  height: 200,
                                  color: Colors.grey[200],
                                  child: const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  height: 200,
                                  color: Colors.grey[200],
                                  child: const Center(
                                    child: Icon(Icons.pets, size: 48, color: Colors.grey),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _isExpanded = !_isExpanded;
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.animal.name.isNotEmpty ? widget.animal.name : 'Unknown Animal',
                                      style: GoogleFonts.ibmPlexMono(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black,
                                      ),
                                    ),
                                    if (widget.animal.scientificName.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        widget.animal.scientificName,
                                        style: GoogleFonts.ibmPlexMono(
                                          fontSize: 14,
                                          color: Colors.black87,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              AnimatedRotation(
                                turns: _isExpanded ? 0.5 : 0,
                                duration: const Duration(milliseconds: 200),
                                child: const Icon(Icons.expand_more, color: Colors.black87),
                              ),
                            ],
                          ),
                        ),
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: _isExpanded ? null : 0,
                        child: _isExpanded ? Column(
                          children: [
                            if (widget.animal.description.isNotEmpty) ...[
                              const Divider(height: 1, color: Colors.black12),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.isEnglish ? 'Description' : 'Beskrivning',
                                      style: GoogleFonts.ibmPlexMono(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      widget.animal.description,
                                      style: GoogleFonts.ibmPlexMono(
                                        fontSize: 14,
                                        color: Colors.black87,
                                        height: 1.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            if (widget.animal.hints.isNotEmpty) ...[
                              const Divider(height: 1, color: Colors.black12),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.isEnglish ? 'Interesting Facts' : 'Intressanta fakta',
                                      style: GoogleFonts.ibmPlexMono(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    ...widget.animal.hints.take(3).map((hint) => Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            margin: const EdgeInsets.only(top: 6, right: 8),
                                            width: 4,
                                            height: 4,
                                            decoration: const BoxDecoration(
                                              color: Colors.black54,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          Expanded(
                                            child: Text(
                                              hint,
                                              style: GoogleFonts.ibmPlexMono(
                                                fontSize: 13,
                                                color: Colors.black87,
                                                height: 1.4,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    )),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ) : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // Statistics section
                Center(
                  child: Text(
                    widget.isEnglish ? 'daily statistics' : 'daglig statistik',
                    style: GoogleFonts.ibmPlexMono(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    widget.isEnglish 
                        ? "You and 52% of other players guessed on the ${widget.questionIndex}rd try!"
                        : "Du och 52% av andra spelare gissade på ${widget.questionIndex}:e försöket!",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.ibmPlexMono(color: Colors.white70, fontSize: 12),
                  ),
                ),
                const SizedBox(height: 12),
                
                // Statistics bars
                _StatsRow(attempt: '1', percent: 8, isEnglish: widget.isEnglish),
                _StatsRow(attempt: '2', percent: 11, isEnglish: widget.isEnglish),
                _StatsRow(attempt: '3', percent: 52, highlight: true, isEnglish: widget.isEnglish),
                _StatsRow(attempt: '4', percent: 20, isEnglish: widget.isEnglish),
                _StatsRow(attempt: '5', percent: 9, isEnglish: widget.isEnglish),
                const SizedBox(height: 24),
                
                // Action buttons
                Align(
                  alignment: Alignment.centerLeft,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => QuizScreen(
                              animal: widget.animal,
                              isEnglish: widget.isEnglish,
                              questionIndex: 1,
                              totalQuestions: widget.totalQuestions,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        height: 56,
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.isEnglish ? 'Play again' : 'Spela igen',
                              style: GoogleFonts.ibmPlexMono(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.refresh, color: Colors.white),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // View Clues button
                Align(
                  alignment: Alignment.centerLeft,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => _showCluesDialog(context),
                      child: Container(
                        height: 56,
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.isEnglish ? 'View Clues' : 'Visa ledtrådar',
                              style: GoogleFonts.ibmPlexMono(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.lightbulb_outline, color: Colors.white),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        Navigator.pushAndRemoveUntil(
                          context,
                        MaterialPageRoute(
                          builder: (context) => const HomeScreen(),
                          ),
                          (route) => false,
                        );
                      },
                      child: Container(
                        height: 56,
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.isEnglish ? 'Back to home' : 'Tillbaka hem',
                              style: GoogleFonts.ibmPlexMono(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.home, color: Colors.white),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final String attempt;
  final int percent;
  final bool highlight;
  final bool isEnglish;

  const _StatsRow({
    required this.attempt,
    required this.percent,
    this.highlight = false,
    required this.isEnglish,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: Text(
              attempt,
              style: GoogleFonts.ibmPlexMono(
                color: highlight ? Colors.white : Colors.white70,
                fontSize: 14,
                fontWeight: highlight ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 8,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(4),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: percent / 100,
                child: Container(
                  decoration: BoxDecoration(
                    color: highlight ? Colors.white : Colors.white70,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '$percent%',
            style: GoogleFonts.ibmPlexMono(
              color: highlight ? Colors.white : Colors.white70,
              fontSize: 14,
              fontWeight: highlight ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
