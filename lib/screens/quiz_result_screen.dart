import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/animal_data.dart';
import 'home_screen.dart';
import 'quiz_screen.dart';

class QuizResultScreen extends StatelessWidget {
  final AnimalData animal;
  final bool isEnglish;
  final bool isCorrect;
  final int questionIndex;
  final int totalQuestions;

  const QuizResultScreen({
    super.key,
    required this.animal,
    required this.isEnglish,
    required this.isCorrect,
    required this.questionIndex,
    required this.totalQuestions,
  });

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
                // Header
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      color: Colors.white,
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.info_outline),
                      color: Colors.white,
                      onPressed: () {},
                    ),
                  ],
                ),
                
                // Result title
                Text(
                  isCorrect 
                      ? (isEnglish ? 'You are correct!' : 'Du har rätt!')
                      : (isEnglish ? 'Time\'s up!' : 'Tiden är ute!'),
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
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    animal.name.isNotEmpty ? animal.name : 'Unknown Animal',
                                    style: GoogleFonts.ibmPlexMono(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black,
                                    ),
                                  ),
                                  if (animal.scientificName.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      animal.scientificName,
                                      style: GoogleFonts.ibmPlexMono(
                                        fontSize: 13,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const Icon(Icons.expand_more, color: Colors.black87),
                          ],
                        ),
                      ),
                      if (animal.description.isNotEmpty) ...[
                        const Divider(height: 1, color: Colors.black12),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            animal.description,
                            style: GoogleFonts.ibmPlexMono(
                              fontSize: 14,
                              color: Colors.black87,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // Statistics section
                Center(
                  child: Text(
                    isEnglish ? 'daily statistics' : 'daglig statistik',
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
                    isEnglish 
                        ? "You and 52% of other players guessed on the ${questionIndex}rd try!"
                        : "Du och 52% av andra spelare gissade på ${questionIndex}:e försöket!",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.ibmPlexMono(color: Colors.white70, fontSize: 12),
                  ),
                ),
                const SizedBox(height: 12),
                
                // Statistics bars
                _StatsRow(attempt: '1', percent: 8, isEnglish: isEnglish),
                _StatsRow(attempt: '2', percent: 11, isEnglish: isEnglish),
                _StatsRow(attempt: '3', percent: 52, highlight: true, isEnglish: isEnglish),
                _StatsRow(attempt: '4', percent: 20, isEnglish: isEnglish),
                _StatsRow(attempt: '5', percent: 9, isEnglish: isEnglish),
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
                              animal: animal,
                              isEnglish: isEnglish,
                              questionIndex: 1,
                              totalQuestions: totalQuestions,
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
                              isEnglish ? 'Play again' : 'Spela igen',
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
                              isEnglish ? 'Back to home' : 'Tillbaka hem',
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
