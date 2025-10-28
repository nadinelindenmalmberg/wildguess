import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/animal_data.dart';
import '../services/history_service.dart';
import 'home_screen.dart';
import '../services/ai_clue_service.dart';
import '../services/statistics_service.dart';

class QuizResultScreen extends StatefulWidget {
  final AnimalData animal;
  final bool isEnglish;
  final bool isCorrect;
  final int hintIndex;
  final int totalHints;
  final List<String> aiClues;
  final int totalTimeMs;

  const QuizResultScreen({
    super.key,
    required this.animal,
    required this.isEnglish,
    required this.isCorrect,
    required this.hintIndex,
    required this.totalHints,
    required this.aiClues,
    required this.totalTimeMs,
  });

  @override
  State<QuizResultScreen> createState() => _QuizResultScreenState();
}

class _QuizResultScreenState extends State<QuizResultScreen> {
  bool _isExpanded = false;
  Map<String, dynamic> _dailyStats = {};
  bool _isLoadingStats = true;

  // AI facts variables
  final AiClueService _aiClueService = AiClueService();
  List<String> _aiFacts = [];
  bool _isLoadingFacts = true;

  @override
  void initState() {
    super.initState();
    _saveGameHistory();
    _loadDailyStatistics();
    _loadAiFacts();
  }

  @override
  void dispose() {
    _aiClueService.dispose();
    super.dispose();
  }

  Future<void> _saveGameHistory() async {
    try {
      await HistoryService.saveGameHistory(
        animal: widget.animal,
        completedAt: DateTime.now(),
        questionIndex: widget.hintIndex,
        totalQuestions: widget.totalHints,
        isCorrect: widget.isCorrect,
      );
    } catch (e) {
      print('Error saving game history: $e');
    }
  }

  Future<void> _loadDailyStatistics() async {
    try {
      final stats = await StatisticsService.getDailyStatistics(widget.hintIndex);
      if (mounted) {
        setState(() {
          _dailyStats = stats;
          _isLoadingStats = false;
        });
      }
    } catch (e) {
      print('Error loading daily statistics: $e');
      if (mounted) {
        setState(() {
          _isLoadingStats = false;
        });
      }
    }
  }

  Future<void> _loadAiFacts() async {
    if (!mounted) return;
    setState(() {
      _isLoadingFacts = true;
    });
    try {
      final facts = await _aiClueService.generateFacts(
        widget.animal,
        isEnglish: widget.isEnglish,
      );
      if (mounted) {
        setState(() {
          _aiFacts = facts;
          _isLoadingFacts = false;
        });
      }
    } catch (e) {
      print("Failed to load AI facts: $e");
      if (mounted) {
        setState(() {
          _isLoadingFacts = false;
        });
      }
    }
  }

  String _getStatisticsText() {
    if (_dailyStats.isEmpty) {
      if (widget.isCorrect) {
        return widget.isEnglish
            ? "You and 52% of other players solved today's animal on the ${widget.hintIndex}rd try!"
            : "Du och 52% av andra spelare löste dagens djur på ${widget.hintIndex}:e försöket!";
      } else {
        return widget.isEnglish
            ? "You and 10% of other players didn't solve today's animal!"
            : "Du och 10% av andra spelare löste inte dagens djur!";
      }
    }

    final percentage = _dailyStats['percentage'] ?? 52;
    final isDefault = _dailyStats['isDefault'] ?? false;
    final totalGames = _dailyStats['totalGames'] ?? 0;

    if (isDefault) {
      if (widget.isCorrect) {
        return widget.isEnglish
            ? "You and $percentage% of other players solved today's animal on the ${widget.hintIndex}rd try!"
            : "Du och $percentage% av andra spelare löste dagens djur på ${widget.hintIndex}:e försöket!";
      } else {
        return widget.isEnglish
            ? "You and $percentage% of other players didn't solve today's animal!"
            : "Du och $percentage% av andra spelare löste inte dagens djur!";
      }
    } else {
      if (totalGames < 5) {
        if (widget.isCorrect) {
          return widget.isEnglish
              ? "You and $percentage% of other players solved today's animal on the ${widget.hintIndex}rd try! ($totalGames players)"
              : "Du och $percentage% av andra spelare löste dagens djur på ${widget.hintIndex}:e försöket! ($totalGames spelare)";
        } else {
          return widget.isEnglish
              ? "You and $percentage% of other players didn't solve today's animal! ($totalGames players)"
              : "Du och $percentage% av andra spelare löste inte dagens djur! ($totalGames spelare)";
        }
      } else {
        if (widget.isCorrect) {
          return widget.isEnglish
              ? "You and $percentage% of other players solved today's animal on the ${widget.hintIndex}rd try! ($totalGames players)"
              : "Du och $percentage% av andra spelare löste dagens djur på ${widget.hintIndex}:e försöket! ($totalGames spelare)";
        } else {
          return widget.isEnglish
              ? "You and $percentage% of other players didn't solve today's animal! ($totalGames players)"
              : "Du och $percentage% av andra spelare löste inte dagens djur! ($totalGames spelare)";
        }
      }
    }
  }

  Widget _buildStatisticsBars() {
    if (_dailyStats.isEmpty) {
      return Column(
        children: [
          _StatsRow(attempt: '1', percent: 8, isEnglish: widget.isEnglish),
          _StatsRow(attempt: '2', percent: 11, isEnglish: widget.isEnglish),
          _StatsRow(attempt: '3', percent: 52, highlight: true, isEnglish: widget.isEnglish),
          _StatsRow(attempt: '4', percent: 20, isEnglish: widget.isEnglish),
          _StatsRow(attempt: '5', percent: 9, isEnglish: widget.isEnglish),
          _StatsRow(attempt: 'X', percent: 0, isEnglish: widget.isEnglish),
        ],
      );
    }

    final hintDistribution = _dailyStats['hintDistribution'] as Map<int, int>? ?? {};
    final failedCount = _dailyStats['failedCount'] ?? 0;
    final totalGames = _dailyStats['totalGames'] ?? 1;

    return Column(
      children: [
        // Rows 1-5 for successful attempts
        for (int i = 1; i <= 5; i++) ...[
          () {
            final percent = totalGames > 0 ? ((hintDistribution[i] ?? 0) / totalGames * 100).round() : 0;
            final highlight = i == widget.hintIndex && widget.isCorrect;
            return _StatsRow(
              attempt: i.toString(), 
              percent: percent, 
              highlight: highlight,
              isEnglish: widget.isEnglish,
            );
          }(),
        ],
        // Row X for failed attempts
        () {
          final percent = totalGames > 0 ? (failedCount / totalGames * 100).round() : 0;
          final highlight = !widget.isCorrect;
          return _StatsRow(
            attempt: 'X', 
            percent: percent, 
            highlight: highlight,
            isEnglish: widget.isEnglish,
          );
        }(),
      ],
    );
  }

  void _showCluesDialog(BuildContext context) {
    const Color dialogBackgroundColor = Color(0xFF1C1C1E);
    const Color primaryTextColor = Colors.white;
    const Color secondaryTextColor = Color(0xFFEBEBF5);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: dialogBackgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            widget.isEnglish ? 'Clues' : 'Ledtrådar',
            style: GoogleFonts.ibmPlexMono(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: primaryTextColor,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                ...widget.aiClues.asMap().entries.map((entry) {
                  int index = entry.key;
                  String hint = entry.value;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.isEnglish
                              ? 'Clue ${index + 1}'
                              : 'Ledtråd ${index + 1}',
                          style: GoogleFonts.ibmPlexMono(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: primaryTextColor,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          hint,
                          style: GoogleFonts.ibmPlexMono(
                            fontSize: 14,
                            color: secondaryTextColor.withOpacity(0.7),
                            height: 1.4,
                            fontWeight: FontWeight.w400,
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
                'OK',
                style: GoogleFonts.ibmPlexMono(
                  color: primaryTextColor.withOpacity(0.9),
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFactItem(String fact) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6, right: 10),
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Colors.black54,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              fact,
              style: GoogleFonts.ibmPlexMono(
                fontSize: 14,
                color: Colors.black.withOpacity(0.8),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFullScreenImage(BuildContext context) {
    final Widget animalInfoCard = Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFE7EFE7),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.animal.name,
                  style: GoogleFonts.ibmPlexMono(
                    color: Colors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.left,
                ),
                if (widget.animal.scientificName.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    widget.animal.scientificName,
                    style: GoogleFonts.ibmPlexMono(
                      color: Colors.black87,
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.left,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                color: Colors.black87,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.zero,
          child: Stack(
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  color: Colors.transparent,
                ),
              ),
              Center(
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 3.0,
                  child: IntrinsicWidth(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        animalInfoCard,
                        ClipRRect(
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(16),
                            bottomRight: Radius.circular(16),
                          ),
                          child: Image.network(
                            widget.animal.imageUrl,
                            fit: BoxFit.contain,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                height: 300,
                                color: Colors.black54,
                                child: const Center(
                                  child: CircularProgressIndicator(color: Colors.white),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 300,
                                color: Colors.black54,
                                child: const Center(
                                  child: Icon(Icons.pets, size: 64, color: Colors.white),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  int calculateScore({required int attempts, required int timeMs, required bool solved}) {
    if (!solved) return 0;
    
    int baseScore = 100;
    int attemptPenalty = (attempts - 1) * 10;
    int timePenalty = (timeMs ~/ 1000) ~/ 10;
    
    int finalScore = baseScore - attemptPenalty - timePenalty;
    return finalScore.clamp(0, 100);
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
                // Header
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
                                    
                                    // Show loading indicator or AI facts
                                    if (_isLoadingFacts)
                                      const Center(
                                        child: Padding(
                                          padding: EdgeInsets.symmetric(vertical: 20.0),
                                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black54),
                                        ),
                                      )
                                    else if (_aiFacts.isNotEmpty)
                                      Column(
                                        children: _aiFacts.map((fact) => Padding(
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
                                                  fact,
                                                  style: GoogleFonts.ibmPlexMono(
                                                    fontSize: 13,
                                                    color: Colors.black87,
                                                    height: 1.4,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        )).toList(),
                                      )
                                    else if (widget.animal.hints.isNotEmpty)
                                      Column(
                                        children: widget.animal.hints.take(3).map((hint) => Padding(
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
                                        )).toList(),
                                      )
                                    else
                                      Text(
                                        widget.isEnglish ? 'No interesting facts available.' : 'Inga intressanta fakta tillgängliga.',
                                        style: GoogleFonts.ibmPlexMono(fontSize: 13, color: Colors.black54),
                                      ),
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

                // Score section
                if (widget.isCorrect) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.withOpacity(0.3)),
                    ),
                    child: Text(
                      widget.isEnglish
                          ? 'Your Score: ${calculateScore(attempts: widget.hintIndex, timeMs: widget.totalTimeMs, solved: widget.isCorrect)}/100'
                          : 'Din poäng: ${calculateScore(attempts: widget.hintIndex, timeMs: widget.totalTimeMs, solved: widget.isCorrect)}/100',
                      style: GoogleFonts.ibmPlexMono(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.green[700],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Statistics section - Clean design matching app style
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1F2937).withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.isEnglish ? "Today's Statistics" : 'Dagens statistik',
                        style: GoogleFonts.ibmPlexMono(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      _isLoadingStats
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 20.0),
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : Column(
                              children: [
                                Text(
                                  _getStatisticsText(),
                                  style: GoogleFonts.ibmPlexMono(
                                    fontSize: 14,
                                    color: Colors.white70,
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _buildStatisticsBars(),
                              ],
                            ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

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
                // Back to home button
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

                const SizedBox(height: 32),
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
    final textColor = highlight ? Colors.white : Colors.white60;
    final barColor = highlight ? const Color(0xFF10B981) : const Color(0xFF6B7280);
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 1),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: highlight ? const Color(0xFF1F2937).withOpacity(0.8) : Colors.transparent,
        borderRadius: BorderRadius.circular(4),
        border: highlight ? Border.all(color: const Color(0xFF10B981), width: 0.5) : null,
      ),
      child: Row(
        children: [
          // Attempt number
          SizedBox(
            width: 20,
            child: Text(
              attempt,
              style: GoogleFonts.ibmPlexMono(
                color: textColor,
                fontSize: 12,
                fontWeight: highlight ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
          const SizedBox(width: 8),
          
          // Progress bar
          Expanded(
            child: Container(
              height: 6,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(3),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: (percent / 100).clamp(0.0, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: barColor,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          
          // Percentage
          SizedBox(
            width: 35,
            child: Text(
              '$percent%',
              textAlign: TextAlign.right,
              style: GoogleFonts.ibmPlexMono(
                color: textColor,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}