// import 'dart:convert'; // Oanvänd import - tas bort
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
// import 'package:shared_preferences/shared_preferences.dart'; // Oanvänd import - tas bort
import '../models/animal_data.dart';
import '../services/history_service.dart';
import '../services/statistics_service.dart';
import '../services/ai_clue_service.dart';
import 'home_screen.dart'; // Behövs för navigation

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
  final AiClueService _aiClueService = AiClueService();
  bool _isExpanded = false;
  Map<String, dynamic> _dailyStats = {};
  bool _isLoadingStats = true;

  List<String> _aiFacts = [];
  bool _isLoadingAiFacts = true;

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


  Future<void> _loadAiFacts() async {
     setState(() {
       _isLoadingAiFacts = true;
    });
    try {
      final facts = await _aiClueService.generateFacts(
        widget.animal,
        isEnglish: widget.isEnglish,
      );
      if (mounted) {
        setState(() {
          _aiFacts = facts;
          _isLoadingAiFacts = false;
        });
      }
    } catch (e) {
      print('Error loading AI facts: $e'); // ignore: avoid_print
      if (mounted) {
        setState(() {
          _isLoadingAiFacts = false;
           _aiFacts = widget.isEnglish ? ['Could not load facts.'] : ['Kunde inte ladda fakta.'];
        });
      }
    }
  }

  Future<void> _loadDailyStatistics() async {
    // ... (Inga ändringar här, samma kod som i föregående svar) ...
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

          print('[QuizResultScreen] Loading global stats: totalPlayers=$totalPlayers, isCorrect=${widget.isCorrect}, hintIndex=${widget.hintIndex}'); // ignore: avoid_print
          // print('[QuizResultScreen] Raw leaderboard data: $leaderboard'); // ignore: avoid_print // Kan bli mycket data

          // Count successful attempts for each hint level (only solved = true)
          for (int i = 1; i <= 5; i++) {
            hintDistribution[i] = leaderboard.where((entry) =>
              entry['attempts'] == i && entry['solved'] == true).length;
            // print('[QuizResultScreen] Hint $i successful: ${hintDistribution[i]}'); // ignore: avoid_print
          }

          // Count failed attempts (solved = false)
          final failedCount = leaderboard.where((entry) =>
            entry['solved'] == false).length;
          // print('[QuizResultScreen] Failed attempts: $failedCount'); // ignore: avoid_print

          // For daily animal system: calculate percentage based on success/failure
          int currentCount;
          if (widget.isCorrect) {
            // User succeeded, count successful attempts at their hint level
            currentCount = hintDistribution[widget.hintIndex] ?? 0;
            // print('[QuizResultScreen] User succeeded, counting hint ${widget.hintIndex}: $currentCount'); // ignore: avoid_print
          } else {
            // User failed, count failed attempts
            currentCount = failedCount;
            // print('[QuizResultScreen] User failed, counting failed attempts: $currentCount'); // ignore: avoid_print
          }
          final percentage = totalPlayers > 0 ? (currentCount / totalPlayers * 100).round() : 0;
          // print('[QuizResultScreen] Final percentage: $percentage%'); // ignore: avoid_print

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
        print('Error loading global statistics: $e'); // ignore: avoid_print
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
      print('Error loading daily statistics: $e'); // ignore: avoid_print
      if (mounted) {
        setState(() {
          // Sätt defaultvärden även vid fel i fallback
           _dailyStats = {
            'percentage': 0,
            'totalGames': 0,
            'hintDistribution': {1: 8, 2: 11, 3: 52, 4: 20, 5: 9}, // Default
            'failedCount': 0,
            'isLocal': true,
            'isDefault': true, // Markera som default
          };
          _isLoadingStats = false;
        });
      }
    }
  }

  Future<void> _saveGameHistory() async {
    // ... (Inga ändringar här, samma kod som i föregående svar) ...
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
      print('[QuizResultScreen] Submitting score: attempts=${widget.hintIndex}, solved=${widget.isCorrect}, timeMs=${widget.totalTimeMs}'); // ignore: avoid_print
      await submitScore(
        attempts: widget.hintIndex,
        solved: widget.isCorrect,
        timeMs: widget.totalTimeMs,
        animalForTesting: testingMode ? widget.animal.name : null,
        animalName: widget.animal.name, // Always pass animal name for daily tracking
      );
      print('[QuizResultScreen] Score submitted to Supabase successfully'); // ignore: avoid_print
    } catch (e) {
      print('[QuizResultScreen] Error submitting score to Supabase: $e'); // ignore: avoid_print
      // Don't show error to user, just log it
    }
  }

 String _getStatisticsText() {
   // ... (Inga ändringar här, samma kod som i föregående svar) ...
       if (_isLoadingStats) {
       return widget.isEnglish ? "Loading statistics..." : "Laddar statistik...";
    }
    if (_dailyStats.isEmpty) {
      // Använd en rimlig standard om laddning misslyckas helt
      final defaultPercent = widget.isCorrect ? 35 : 15;
      if (widget.isCorrect) {
        return widget.isEnglish
            ? "You and $defaultPercent% of other players solved today's animal on the ${widget.hintIndex}${_getOrdinal(widget.hintIndex)} try!"
            : "Du och $defaultPercent% av andra spelare löste dagens djur på ${widget.hintIndex}:e försöket!";
      } else {
        return widget.isEnglish
            ? "You and $defaultPercent% of other players didn't solve today's animal!"
            : "Du och $defaultPercent% av andra spelare löste inte dagens djur!";
      }
    }

    final percentage = _dailyStats['percentage'] ?? 0;
    final isDefault = _dailyStats['isDefault'] ?? false;
    final isGlobal = _dailyStats['isGlobal'] ?? false;
    final totalGames = _dailyStats['totalGames'] ?? 0;

    String dataSource = isGlobal ? "players today" : "other players";
    String dataSourceSv = isGlobal ? "spelare idag" : "andra spelare";
    // Tydligare text när global data visas
    String countInfo = totalGames > 0 ? " ($totalGames ${isGlobal ? (widget.isEnglish ? 'global' : 'globalt') : (widget.isEnglish ? 'local' : 'lokala')})" : "";


    // Om isDefault är sann, visa en generell text utan procent (eftersom datan är påhittad)
    if (isDefault) {
      return widget.isEnglish
          ? "Statistics are being gathered for today's animal."
          : "Statistik samlas in för dagens djur.";
    }

    // Annars, visa den vanliga texten med procent och antal spelare
    if (widget.isCorrect) {
      return widget.isEnglish
          ? "You and $percentage% of $dataSource solved today's animal on the ${widget.hintIndex}${_getOrdinal(widget.hintIndex)} try!$countInfo"
          : "Du och $percentage% av $dataSourceSv löste dagens djur på ${widget.hintIndex}:e försöket!$countInfo";
    } else {
      // Hantera fallet där hintIndex är 5 och isCorrect är false (misslyckades på sista)
      if (!widget.isCorrect && widget.hintIndex == widget.totalHints) {
         return widget.isEnglish
            ? "You and $percentage% of $dataSource didn't solve today's animal!$countInfo"
            : "Du och $percentage% av $dataSourceSv löste inte dagens djur!$countInfo";
      } else {
         // Om man gissade fel på en tidigare hint (vilket inte borde hända i nuvarande logik, men för säkerhets skull)
         return widget.isEnglish
            ? "You didn't solve the animal on the ${widget.hintIndex}${_getOrdinal(widget.hintIndex)} try."
            : "Du löste inte djuret på ${widget.hintIndex}:e försöket.";
      }
    }
 }

   String _getOrdinal(int number) {
     // ... (Inga ändringar här, samma kod som i föregående svar) ...
        if (!widget.isEnglish) return ""; // Endast för engelska
    if (number <= 0) return ""; // Hantera ogiltiga nummer
    if (number % 100 >= 11 && number % 100 <= 13) return 'th';
    switch (number % 10) {
      case 1: return 'st';
      case 2: return 'nd';
      case 3: return 'rd';
      default: return 'th';
    }
   }

  Widget _buildStatisticsBars() {
    if (_isLoadingStats || _dailyStats.isEmpty || _dailyStats['isDefault'] == true) {
      // ... (Inga ändringar här, samma kod som i föregående svar) ...
       return Container(
        height: 150,
        alignment: Alignment.center,
        child: _isLoadingStats
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white70))
            : Text(
                widget.isEnglish ? 'Gathering statistics...' : 'Samlar in statistik...',
                style: GoogleFonts.ibmPlexMono(color: Colors.white54, fontSize: 12),
              ),
      );
    }

    final dynamic rawHintDistribution = _dailyStats['hintDistribution'];
    final Map<int, int> hintDistributionIntKeys;
    // ... (Inga ändringar här, samma kod som i föregående svar) ...
     if (rawHintDistribution is Map<int, int>) {
      hintDistributionIntKeys = rawHintDistribution;
    } else if (rawHintDistribution is Map) {
      hintDistributionIntKeys = rawHintDistribution.map((key, value) {
        final intKey = int.tryParse(key.toString()) ?? 0;
        final intValue = value is int ? value : 0;
        return MapEntry(intKey, intValue);
      });
    } else {
      hintDistributionIntKeys = {}; // Fallback till tom map
    }

    final failedCount = _dailyStats['failedCount'] ?? 0;
    final totalGames = (_dailyStats['totalGames'] ?? 1).clamp(1, 1000000);

    // print('[QuizResultScreen] Building bars: totalGames=$totalGames, failedCount=$failedCount'); // ignore: avoid_print
    // print('[QuizResultScreen] Hint distribution (int keys): $hintDistributionIntKeys'); // ignore: avoid_print
    // print('[QuizResultScreen] User: isCorrect=${widget.isCorrect}, hintIndex=${widget.hintIndex}'); // ignore: avoid_print

    return Column(
      children: [
        // Rows 1-5 for successful attempts
        for (int i = 1; i <= 5; i++) ...[
          // --- KORRIGERING: Ta bort extra () ---
          _StatsRow(
            attempt: i.toString(),
            percent: totalGames > 0 ? (((hintDistributionIntKeys[i] ?? 0).clamp(0, totalGames) / totalGames) * 100).round() : 0,
            highlight: i == widget.hintIndex && widget.isCorrect,
            isEnglish: widget.isEnglish,
          ),
          // --- SLUT PÅ KORRIGERING ---
        ],
        // Row X for failed attempts
        // --- KORRIGERING: Ta bort extra () ---
        _StatsRow(
          attempt: 'X',
          percent: totalGames > 0 ? (((failedCount ?? 0).clamp(0, totalGames) / totalGames) * 100).round() : 0,
          highlight: !widget.isCorrect,
          isEnglish: widget.isEnglish,
        ),
        // --- SLUT PÅ KORRIGERING ---
      ],
    );
  }


  void _showCluesDialog(BuildContext context) {
    // ... (Inga ändringar här, samma kod som i föregående svar) ...
        const Color dialogBackgroundColor = Color(0xFF1C1C1E);
    const Color primaryTextColor = Colors.white;
    // Använd .withAlpha istället för .withOpacity
    final Color secondaryTextColor = const Color(0xFFEBEBF5).withAlpha(178); // 0.7 * 255 = 178.5 -> 178

    showDialog(
      context: context,
      builder: (BuildContext context) {
        // Använd take(widget.hintIndex) för att bara visa använda ledtrådar
        final usedClues = (widget.aiClues.isNotEmpty ? widget.aiClues : widget.animal.hints)
                            .take(widget.hintIndex).toList();

        return AlertDialog(
          backgroundColor: dialogBackgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            widget.isEnglish ? 'Clues Used' : 'Använda Ledtrådar',
            style: GoogleFonts.ibmPlexMono(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: primaryTextColor,
            ),
             textAlign: TextAlign.center,
          ),
           titlePadding: const EdgeInsets.only(top: 24, bottom: 8),
           contentPadding: const EdgeInsets.symmetric(horizontal: 20),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: usedClues.isEmpty
                ? [ // Visa ett meddelande om inga ledtrådar användes (borde inte hända)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20.0),
                      child: Center(
                        child: Text(
                          widget.isEnglish ? 'No clues were used.' : 'Inga ledtrådar användes.',
                          style: GoogleFonts.ibmPlexMono(color: secondaryTextColor),
                        ),
                      ),
                    )
                  ]
                : usedClues.asMap().entries.map((entry) {
                  int index = entry.key;
                  String hint = entry.value;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.isEnglish
                              ? 'Clue ${index + 1}'
                              : 'Ledtråd ${index + 1}',
                          style: GoogleFonts.ibmPlexMono(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            // Använd withAlpha
                            color: primaryTextColor.withAlpha(217), // 0.85 * 255 = 216.75 -> 217
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          hint,
                          style: GoogleFonts.ibmPlexMono(
                            fontSize: 14,
                            color: secondaryTextColor, // Redan med alpha
                            height: 1.4,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        // Divider
                        if (index < usedClues.length - 1)
                          const Divider(
                            height: 24,
                            color: Colors.white24,
                            thickness: 0.5,
                           ),
                      ],
                    ),
                  );
                }).toList(), // Behövs inte i spread operator, men skadar inte här
            ),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actionsPadding: const EdgeInsets.only(bottom: 20, top: 10),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                 padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                 backgroundColor: Colors.white.withAlpha(25), // 0.1 * 255 = 25.5 -> 25
                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                widget.isEnglish ? 'Close' : 'Stäng',
                style: GoogleFonts.ibmPlexMono(
                  // Använd withAlpha
                  color: primaryTextColor.withAlpha(230), // 0.9 * 255 = 229.5 -> 230
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showFullScreenImage(BuildContext context) {
    // ... (Inga ändringar här, samma kod som i föregående svar) ...
        showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withAlpha(217), // 0.85 * 255
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(10),
          child: Stack(
            alignment: Alignment.center,
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: InteractiveViewer(
                  minScale: 0.8,
                  maxScale: 4.0,
                  clipBehavior: Clip.none,
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withAlpha(128), blurRadius: 20, spreadRadius: 5) // 0.5 * 255
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Image.network(
                        widget.animal.imageUrl,
                        fit: BoxFit.contain,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Center(
                              child: CircularProgressIndicator(color: Colors.white),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.broken_image, size: 64, color: Colors.white60),
                                  const SizedBox(height: 10),
                                  Text(widget.isEnglish ? "Image not found" : "Bild kunde inte laddas", style: GoogleFonts.ibmPlexMono(color: Colors.white60)),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 20,
                right: 20,
                child: Material(
                  color: Colors.black.withAlpha(128), // 0.5 * 255
                  shape: const CircleBorder(),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 30,
                left: 20,
                right: 20,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(153), // 0.6 * 255
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.animal.name,
                        style: GoogleFonts.ibmPlexMono(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                      ),
                      if (widget.animal.scientificName.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          widget.animal.scientificName,
                          style: GoogleFonts.ibmPlexMono(
                            color: Colors.white70,
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1, overflow: TextOverflow.ellipsis,
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
   // ... (Inga ändringar här, samma kod som i föregående svar ned till slutet)...
       return Scaffold(
      backgroundColor: Colors.black,
      body: Container( // Yttersta container behövs inte om Scaffold har backgroundColor
        color: Colors.black,
        child: SafeArea(
          child: SingleChildScrollView( // Flyttat SingleChildScrollView hit
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
                      // Animal image
                      if (widget.animal.imageUrl.isNotEmpty) ...[
                        GestureDetector(
                          onTap: () => _showFullScreenImage(context), // Använd funktionen
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
                      ] else ... [ // Fallback om bild-URL är tom
                         Container(
                            height: 200,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
                            ),
                            child: Center(
                              child: Icon(Icons.pets, size: 64, color: Colors.grey[400]),
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
                      // Expanderbar sektion med fakta
                     AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: _isExpanded ? null : 0,
                      child: _isExpanded
                          ? Column(
                              children: [
                                // Description (oförändrad)
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

                                // Interesting Facts (ersätter gamla hints-sektionen)
                                if (!_isLoadingAiFacts || _aiFacts.isNotEmpty) ...[
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
                                        const SizedBox(height: 12),
                                        _isLoadingAiFacts
                                            ? const Center(
                                                child: Padding(
                                                  padding: EdgeInsets.symmetric(vertical: 16.0),
                                                  child: SizedBox(
                                                    width: 20,
                                                    height: 20,
                                                    child: CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.black54),
                                                    ),
                                                  ),
                                                ),
                                              )
                                            : _aiFacts.isEmpty
                                                ? Text(
                                                    widget.isEnglish ? 'No facts available.' : 'Ingen fakta tillgänglig.',
                                                     style: GoogleFonts.ibmPlexMono(
                                                        fontSize: 13,
                                                        color: Colors.black54,
                                                        fontStyle: FontStyle.italic,
                                                      ),
                                                  )
                                                : Column(
                                                    children: _aiFacts.map((fact) => Padding(
                                                      padding: const EdgeInsets.only(bottom: 12),
                                                      child: Row(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Container(
                                                            margin: const EdgeInsets.only(top: 7, right: 10),
                                                            width: 5,
                                                            height: 5,
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
                                                                color: Colors.black.withAlpha(217), // 0.85 * 255
                                                                height: 1.4,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    )).toList(), // .toList() behövs här pga .map
                                                  ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            )
                          : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Score display
                if (widget.isCorrect) ...[
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withAlpha(25), // 0.1 * 255
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.withAlpha(77)), // 0.3 * 255
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
                            color: Colors.green.withAlpha(51), // 0.2 * 255
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.green.withAlpha(128)), // 0.5 * 255
                          ),
                          child: Text(
                            // Behåller "Global Data" för båda språken för tydlighet
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
                    ? const SizedBox( // Använd SizedBox för att undvika layoutskift
                         height: 18, // Ge lite höjd
                         child: CircularProgressIndicator(
                            color: Colors.white70,
                            strokeWidth: 2,
                          ),
                       )
                    : Text(
                        _getStatisticsText(), // Använd funktionen
                        textAlign: TextAlign.center,
                        style: GoogleFonts.ibmPlexMono(color: Colors.white70, fontSize: 12),
                      ),
                ),
                const SizedBox(height: 12),

                // Statistics bars
                 _buildStatisticsBars(), // Använd funktionen

                const SizedBox(height: 24),

                // View Clues button
                Align(
                  alignment: Alignment.centerLeft,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => _showCluesDialog(context), // Använd funktionen
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
                              widget.isEnglish ? 'View Clues Used' : 'Visa Använda Ledtrådar', // Uppdaterad text
                              style: GoogleFonts.ibmPlexMono(
                                color: Colors.white,
                                fontSize: 16, // Något mindre text
                                fontWeight: FontWeight.w500, // Normal vikt
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.list_alt_rounded, color: Colors.white, size: 20), // Ny ikon
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
                          border: Border.all(color: Colors.white, width: 1.5), // Tunnare border
                        ),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.isEnglish ? 'Back to home' : 'Tillbaka hem',
                              style: GoogleFonts.ibmPlexMono(
                                color: Colors.white,
                                fontSize: 16, // Samma som ovan
                                fontWeight: FontWeight.w500, // Samma som ovan
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.home_outlined, color: Colors.white, size: 20), // Ny ikon
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

// _StatsRow Widget
class _StatsRow extends StatelessWidget {
 // ... (Inga ändringar här, samma kod som i föregående svar) ...
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
    final Color barColor = highlight ? Colors.white : Colors.white60;
    final Color textColor = highlight ? Colors.white : Colors.white70;
    final FontWeight fontWeight = highlight ? FontWeight.w700 : FontWeight.w400;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: Text(
              attempt,
              style: GoogleFonts.ibmPlexMono(
                color: textColor,
                fontSize: 13,
                fontWeight: fontWeight,
              ),
               textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 10,
              decoration: BoxDecoration(
                 gradient: LinearGradient(
                   colors: [Colors.white.withAlpha(25), Colors.white.withAlpha(13)], // 0.1, 0.05
                   begin: Alignment.centerLeft,
                   end: Alignment.centerRight,
                 ),
                borderRadius: BorderRadius.circular(5),
              ),
               clipBehavior: Clip.antiAlias,
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: (percent / 100).clamp(0.0, 1.0),
                child: AnimatedContainer(
                   duration: const Duration(milliseconds: 300),
                   curve: Curves.easeOut,
                  decoration: BoxDecoration(
                    color: barColor,
                    borderRadius: BorderRadius.circular(5),
                     boxShadow: highlight ? [
                       BoxShadow(
                         color: Colors.white.withAlpha(77), // 0.3 * 255
                         blurRadius: 3,
                         spreadRadius: 0.5,
                       )
                     ] : null,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
             width: 35,
            child: Text(
              '$percent%',
              style: GoogleFonts.ibmPlexMono(
                color: textColor,
                fontSize: 13,
                fontWeight: fontWeight,
              ),
               textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}