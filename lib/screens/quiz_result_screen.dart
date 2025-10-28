import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/animal_data.dart';
import '../services/history_service.dart';
import '../services/statistics_service.dart';
import 'home_screen.dart';
import 'quiz_screen.dart'; // Behövs troligen inte här, men skadar inte
import '../services/ai_clue_service.dart'; // *** NYTT: Importera AiClueService ***

class QuizResultScreen extends StatefulWidget {
  final AnimalData animal;
  final bool isEnglish;
  final bool isCorrect;
  final int hintIndex;
  final int totalHints;
  final List<String> aiClues; // Dessa är ledtrådarna, inte fakta
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

  // *** NYTT: Variabler för AI-fakta ***
  final AiClueService _aiClueService = AiClueService(); // Skapa instans
  List<String> _aiFacts = [];
  bool _isLoadingFacts = true;
  // *** SLUT NYTT ***

  @override
  void initState() {
    super.initState();
    _saveGameHistory();
    _loadDailyStatistics();
    _loadAiFacts(); // *** NYTT: Anropa metoden för att ladda fakta ***
  }

  // *** NYTT: dispose för AiClueService ***
  @override
  void dispose() {
    _aiClueService.dispose(); // Glöm inte dispose
    // Befintliga dispose-anrop (om några) ska vara kvar
    super.dispose();
  }
  // *** SLUT NYTT ***

  Future<void> _loadDailyStatistics() async {
    // Befintlig kod... (ingen ändring här)
     try {
      // Try to get global statistics from Supabase first
      try {
        final leaderboard = await getTopToday(
          limit: 100,
          animalForTesting: testingMode ? widget.animal.name : null,
          animalName: widget.animal.name,
        );

        if (leaderboard.isNotEmpty) {
          // Calculate global statistics from leaderboard data
          final totalPlayers = leaderboard.length;
          final hintDistribution = <int, int>{};

          print('[QuizResultScreen] Loading global stats: totalPlayers=$totalPlayers, isCorrect=${widget.isCorrect}, hintIndex=${widget.hintIndex}');
          print('[QuizResultScreen] Raw leaderboard data: $leaderboard');

          // Count successful attempts for each hint level (only solved = true)
          for (int i = 1; i <= 5; i++) {
            hintDistribution[i] = leaderboard.where((entry) =>
              entry['attempts'] == i && entry['solved'] == true).length;
            print('[QuizResultScreen] Hint $i successful: ${hintDistribution[i]}');
          }

          // Count failed attempts (solved = false)
          final failedCount = leaderboard.where((entry) =>
            entry['solved'] == false).length;
          print('[QuizResultScreen] Failed attempts: $failedCount');

          // For daily animal system: calculate percentage based on success/failure
          int currentCount;
          if (widget.isCorrect) {
            // User succeeded, count successful attempts at their hint level
            currentCount = hintDistribution[widget.hintIndex] ?? 0;
            print('[QuizResultScreen] User succeeded, counting hint ${widget.hintIndex}: $currentCount');
          } else {
            // User failed, count failed attempts
            currentCount = failedCount;
            print('[QuizResultScreen] User failed, counting failed attempts: $currentCount');
          }
          final percentage = totalPlayers > 0 ? (currentCount / totalPlayers * 100).round() : 0;
          print('[QuizResultScreen] Final percentage: $percentage%');

          if (mounted) {
            setState(() {
              _dailyStats = {
                'percentage': percentage,
                'totalGames': totalPlayers,
                'hintDistribution': hintDistribution,
                'failedCount': failedCount,
                'isLocal': false,
                'isDefault': false,
                'isGlobal': true,
              };
              _isLoadingStats = false;
            });
          }
          return;
        }
      } catch (e) {
        print('Error loading global statistics: $e');
        // Fall back to local statistics
      }

      // Fallback to local statistics if Supabase fails
      final stats = await StatisticsService.getDailyStatistics(widget.hintIndex);
      // Add failed count for local statistics
      final localStats = Map<String, dynamic>.from(stats);
      localStats['failedCount'] = stats['failedCount'] ?? 0;

      if (mounted) {
        setState(() {
          _dailyStats = localStats;
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

  Future<void> _saveGameHistory() async {
    // Befintlig kod... (ingen ändring här)
     // Save to local history
    await HistoryService.saveGameHistory(
      animal: widget.animal,
      isCorrect: widget.isCorrect,
      questionIndex: widget.hintIndex,
      totalQuestions: widget.totalHints,
      completedAt: DateTime.now(),
    );

    // Submit to Supabase with new scoring system
    try {
      print('[QuizResultScreen] Submitting score: attempts=${widget.hintIndex}, solved=${widget.isCorrect}, timeMs=${widget.totalTimeMs}');
      await submitScore(
        attempts: widget.hintIndex,
        solved: widget.isCorrect,
        timeMs: widget.totalTimeMs,
        animalForTesting: testingMode ? widget.animal.name : null,
        animalName: widget.animal.name, // Always pass animal name for daily tracking
      );
      print('[QuizResultScreen] Score submitted to Supabase successfully');
    } catch (e) {
      print('[QuizResultScreen] Error submitting score to Supabase: $e');
      // Don't show error to user, just log it
    }
  }

  // *** NY METOD: Ladda AI-fakta ***
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
          // Du kan välja att visa ett felmeddelande här om du vill, t.ex. med ScaffoldMessenger
          // ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Kunde inte ladda fakta.')));
        });
      }
    }
  }
  // *** SLUT NYTT ***


  String _getStatisticsText() {
    // Befintlig kod... (ingen ändring här)
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
    final isGlobal = _dailyStats['isGlobal'] ?? false;
    final totalGames = _dailyStats['totalGames'] ?? 0;

    String dataSource = isGlobal ? "players today" : "other players";
    String dataSourceSv = isGlobal ? "spelare idag" : "andra spelare";

    if (isDefault) {
      if (widget.isCorrect) {
        return widget.isEnglish
            ? "You and $percentage% of $dataSource solved today's animal on the ${widget.hintIndex}rd try!"
            : "Du och $percentage% av $dataSourceSv löste dagens djur på ${widget.hintIndex}:e försöket!";
      } else {
        return widget.isEnglish
            ? "You and $percentage% of $dataSource didn't solve today's animal!"
            : "Du och $percentage% av $dataSourceSv löste inte dagens djur!";
      }
    } else {
      if (totalGames < 5) {
        if (widget.isCorrect) {
          return widget.isEnglish
              ? "You and $percentage% of $dataSource solved today's animal on the ${widget.hintIndex}rd try! ($totalGames players)"
              : "Du och $percentage% av $dataSourceSv löste dagens djur på ${widget.hintIndex}:e försöket! ($totalGames spelare)";
        } else {
          return widget.isEnglish
              ? "You and $percentage% of $dataSource didn't solve today's animal! ($totalGames players)"
              : "Du och $percentage% av $dataSourceSv löste inte dagens djur! ($totalGames spelare)";
        }
      } else {
        if (widget.isCorrect) {
          return widget.isEnglish
              ? "You and $percentage% of $dataSource solved today's animal on the ${widget.hintIndex}rd try! ($totalGames players)"
              : "Du och $percentage% av $dataSourceSv löste dagens djur på ${widget.hintIndex}:e försöket! ($totalGames spelare)";
        } else {
          return widget.isEnglish
              ? "You and $percentage% of $dataSource didn't solve today's animal! ($totalGames players)"
              : "Du och $percentage% av $dataSourceSv löste inte dagens djur! ($totalGames spelare)";
        }
      }
    }
  }

  Widget _buildStatisticsBars() {
    // Befintlig kod... (ingen ändring här)
    if (_dailyStats.isEmpty) {
      // Fallback to default values
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

    print('[QuizResultScreen] Building bars: totalGames=$totalGames, failedCount=$failedCount');
    print('[QuizResultScreen] Hint distribution: $hintDistribution');
    print('[QuizResultScreen] User: isCorrect=${widget.isCorrect}, hintIndex=${widget.hintIndex}');

    return Column(
      children: [
        // Rows 1-5 for successful attempts
        for (int i = 1; i <= 5; i++) ...[
          () {
            final percent = totalGames > 0 ? ((hintDistribution[i] ?? 0) / totalGames * 100).round() : 0;
            final highlight = i == widget.hintIndex && widget.isCorrect;
            print('[QuizResultScreen] Row $i: percent=$percent%, highlight=$highlight');
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
          final highlight = !widget.isCorrect && widget.hintIndex == 5; // Highlight X only if user failed on last attempt
          print('[QuizResultScreen] Row X: percent=$percent%, highlight=$highlight');
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
    // Befintlig kod... (ingen ändring här)
     // Definiera färgerna från bilden för enklare återanvändning
    const Color dialogBackgroundColor = Color(0xFF1C1C1E); // Mörkgrå bakgrund
    const Color primaryTextColor = Colors.white; // Vit text för rubriker
    const Color secondaryTextColor = Color(0xFFEBEBF5); // Ljusgrå text för beskrivning

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: dialogBackgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),

          // ÄNDRING: Titeln är nu "Ledtrådar"
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
                // Loopar igenom AI-ledtrådarna och bygger listan
                ...widget.aiClues.asMap().entries.map((entry) {
                  int index = entry.key;
                  String hint = entry.value;

                  // ÄNDRING: Row och Icon är borttagna.
                  // Vi har nu en Padding direkt runt en Column.
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 24.0), // Lite mer utrymme mellan ledtrådarna
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ÄNDRING: Rubriken är större (fontSize: 18)
                        Text(
                          widget.isEnglish
                              ? 'Clue ${index + 1}'
                              : 'Ledtråd ${index + 1}',
                          style: GoogleFonts.ibmPlexMono(
                            fontSize: 18, // Ändrad från 16
                            fontWeight: FontWeight.w600,
                            color: primaryTextColor,
                          ),
                        ),
                        const SizedBox(height: 6), // Lite mer avstånd till texten under

                        // Beskrivning (själva ledtråden)
                        Text(
                          hint,
                          style: GoogleFonts.ibmPlexMono(
                            fontSize: 14,
                            color: secondaryTextColor.withOpacity(0.7), // Ljusare grå
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

  void _showFullScreenImage(BuildContext context) {
    // Befintlig kod... (ingen ändring här)
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
                        // *** UPPDATERAD KOD för expanderbar del ***
                        child: _isExpanded
                            ? Column(
                                children: [
                                  // --- Description Section (befintlig) ---
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
                                              fontSize: 14, // Justerad storlek
                                              color: Colors.black87,
                                              height: 1.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],

                                  // --- Interesting Facts Section (uppdaterad) ---
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
                                        const SizedBox(height: 12), // Ökat avstånd
                                        // --- Laddningsindikator eller Fakta/Fallback ---
                                        if (_isLoadingFacts)
                                          const Center(
                                            child: Padding( // Lite padding runt indikatorn
                                              padding: EdgeInsets.symmetric(vertical: 20.0),
                                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black54),
                                            )
                                          )
                                        else if (_aiFacts.isNotEmpty)
                                          ..._aiFacts.map((fact) => _buildFactItem(fact)) // Visa AI-fakta
                                        else if (widget.animal.hints.isNotEmpty) // Fallback till gamla hints
                                          ...widget.animal.hints.take(3).map((hint) => _buildFactItem(hint)) // Visa max 3 gamla hints
                                        else
                                          Text( // Meddelande om inga fakta alls finns
                                            widget.isEnglish ? 'No interesting facts available.' : 'Inga intressanta fakta tillgängliga.',
                                            style: GoogleFonts.ibmPlexMono(fontSize: 13, color: Colors.black54),
                                          ),
                                        // --- Slut på laddning/fakta-sektion ---
                                      ],
                                    ),
                                  ),
                                ],
                              )
                            : const SizedBox.shrink(),
                         // *** SLUT PÅ UPPDATERAD KOD ***
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Score display
                // ... (befintlig kod, ingen ändring)
                 if (widget.isCorrect) ...[
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.withOpacity(0.3)),
                      ),
                      child: Text(
                        widget.isEnglish
                            ? 'Your Score: ${calculateScore(attempts: widget.hintIndex, timeMs: widget.totalTimeMs, solved: widget.isCorrect)}/100'
                            : 'Din poäng: ${calculateScore(attempts: widget.hintIndex, timeMs: widget.totalTimeMs, solved: widget.isCorrect)}/100',
                        style: GoogleFonts.ibmPlexMono(
                          color: Colors.blue,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Statistics section
                // ... (befintlig kod, ingen ändring)
                 Center(
                  child: Column(
                    children: [
                      Text(
                        widget.isEnglish ? "today's animal statistics" : 'dagens djurs statistik',
                    style: GoogleFonts.ibmPlexMono(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.0,
                    ),
                      ),
                      if (_dailyStats['isGlobal'] == true) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.green.withOpacity(0.5)),
                          ),
                          child: Text(
                            widget.isEnglish ? '🌍 Global Data' : '🌍 Global Data',
                            style: GoogleFonts.ibmPlexMono(
                              color: Colors.green,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: _isLoadingStats
                    ? CircularProgressIndicator(
                        color: Colors.white70,
                        strokeWidth: 2,
                      )
                    : Text(
                        _getStatisticsText(),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.ibmPlexMono(color: Colors.white70, fontSize: 12),
                  ),
                ),
                const SizedBox(height: 12),

                // Statistics bars
                // ... (befintlig kod, ingen ändring)
                 _isLoadingStats
                  ? const SizedBox(height: 100) // Placeholder while loading
                  : _buildStatisticsBars(),
                const SizedBox(height: 24),

                // View Clues button
                // ... (befintlig kod, ingen ändring)
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
                // ... (befintlig kod, ingen ändring)
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

  // *** NYTT: Hjälp-widget för att visa fakta ***
  Widget _buildFactItem(String fact) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6, right: 10), // Justerad marginal
            width: 5, // Mindre punkt
            height: 5,
            decoration: const BoxDecoration(
              color: Colors.black54, // Mörkare punkt
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              fact,
              style: GoogleFonts.ibmPlexMono(
                fontSize: 14, // Anpassad storlek
                color: Colors.black.withOpacity(0.8), // Mörkare text
                height: 1.4, // Radavstånd
              ),
            ),
          ),
        ],
      ),
    );
  }
  // *** SLUT NYTT ***
}

// _StatsRow widget (befintlig, ingen ändring)
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