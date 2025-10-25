import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/history_service.dart';

class HistoryScreen extends StatefulWidget {
  final bool isEnglish;

  const HistoryScreen({super.key, required this.isEnglish});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Map<String, dynamic>> _historyItems = [];
  bool _isLoading = true;
  Map<String, dynamic> _statistics = {};

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final history = await HistoryService.getGameHistory();
      final stats = await HistoryService.getStatistics();
      
      if (mounted) {
        setState(() {
          _historyItems = history;
          _statistics = stats;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _clearHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFE7EFE7),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          widget.isEnglish ? 'Clear History' : 'Rensa historik',
          style: GoogleFonts.ibmPlexMono(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        content: Text(
          widget.isEnglish 
              ? 'Are you sure you want to clear all game history? This action cannot be undone.'
              : 'Är du säker på att du vill rensa all spelhistorik? Denna åtgärd kan inte ångras.',
          style: GoogleFonts.ibmPlexMono(
            fontSize: 14,
            color: Colors.black87,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              widget.isEnglish ? 'Cancel' : 'Avbryt',
              style: GoogleFonts.ibmPlexMono(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              widget.isEnglish ? 'Clear' : 'Rensa',
              style: GoogleFonts.ibmPlexMono(
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await HistoryService.clearHistory();
      _loadHistory();
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          widget.isEnglish ? 'History' : 'Historik',
          style: GoogleFonts.ibmPlexMono(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_historyItems.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _clearHistory,
              tooltip: widget.isEnglish ? 'Clear History' : 'Rensa historik',
            ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.white),
              )
            : _historyItems.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.history,
                          size: 64,
                          color: Colors.white.withOpacity(0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          widget.isEnglish 
                              ? 'No games played yet' 
                              : 'Inga spel spelade än',
                          style: GoogleFonts.ibmPlexMono(
                            fontSize: 18,
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.isEnglish 
                              ? 'Start playing to see your history here' 
                              : 'Börja spela för att se din historik här',
                          style: GoogleFonts.ibmPlexMono(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  )
                : Column(
                    children: [
                      // Statistics header
                      if (_statistics.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.all(16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(
                                widget.isEnglish ? 'Statistics' : 'Statistik',
                                style: GoogleFonts.ibmPlexMono(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  _buildStatItem(
                                    widget.isEnglish ? 'Games' : 'Spel',
                                    '${_statistics['total_games']}',
                                  ),
                                  _buildStatItem(
                                    widget.isEnglish ? 'Correct' : 'Rätt',
                                    '${_statistics['correct_games']}',
                                  ),
                                  _buildStatItem(
                                    widget.isEnglish ? 'Accuracy' : 'Träffsäkerhet',
                                    '${_statistics['accuracy'].toStringAsFixed(1)}%',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      // History list
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          itemCount: _historyItems.length,
                          itemBuilder: (context, index) {
                            final item = _historyItems[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: HistoryAnimalCard(
                                nameEn: item['animal_name'] ?? '',
                                nameSv: item['animal_name'] ?? '',
                                imageUrl: item['animal_image_url'] ?? '',
                                isEnglish: widget.isEnglish,
                                isCorrect: item['is_correct'] ?? false,
                                questionIndex: item['question_index'] ?? 0,
                                totalQuestions: item['total_questions'] ?? 0,
                                score: item['score'] ?? 0,
                                completedAt: DateTime.tryParse(item['completed_at'] ?? '') ?? DateTime.now(),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.ibmPlexMono(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.ibmPlexMono(
            fontSize: 12,
            color: Colors.white.withOpacity(0.7),
          ),
        ),
      ],
    );
  }
}

// ----------------------------------------------------------------------
// HistoryAnimalCard (Revised with AnimatedSize for smooth scrolling on expand)
// (No changes needed in HistoryAnimalCard itself)
// ----------------------------------------------------------------------
class HistoryAnimalCard extends StatefulWidget {
  final String nameEn;
  final String nameSv;
  final String imageUrl;
  final bool isEnglish;
  final bool isCorrect;
  final int questionIndex;
  final int totalQuestions;
  final int score;
  final DateTime completedAt;

  const HistoryAnimalCard({
    super.key,
    required this.nameEn,
    required this.nameSv,
    required this.imageUrl,
    required this.isEnglish,
    this.isCorrect = false,
    this.questionIndex = 0,
    this.totalQuestions = 0,
    this.score = 0,
    required this.completedAt,
  });

  @override
  State<HistoryAnimalCard> createState() => _HistoryAnimalCardState();
}

class _HistoryAnimalCardState extends State<HistoryAnimalCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final animalName = widget.isEnglish ? widget.nameEn : widget.nameSv;
    final resultText = widget.isCorrect 
        ? (widget.isEnglish ? 'Correct!' : 'Rätt!')
        : (widget.isEnglish ? 'Incorrect' : 'Fel');
    final resultColor = widget.isCorrect ? Colors.green : Colors.red;
    final scoreText = widget.isEnglish ? 'Score' : 'Poäng';
    final questionText = widget.isEnglish ? 'Clue' : 'Ledtråd';
    final dateText = _formatDate(widget.completedAt);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.15),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            setState(() {
              _isExpanded = !_isExpanded;
            });
          },
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.image,
                        color: Color(0xFF10B981),
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        animalName,
                        style: GoogleFonts.ibmPlexMono(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Icon(
                      _isExpanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: Colors.white.withOpacity(0.8),
                      size: 28,
                    ),
                  ],
                ),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: _isExpanded
                    ? Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Divider(color: Colors.white30, height: 1),
                            const SizedBox(height: 12),
                            // Game result
                            Row(
                              children: [
                                Icon(
                                  widget.isCorrect ? Icons.check_circle : Icons.cancel,
                                  color: resultColor,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  resultText,
                                  style: GoogleFonts.ibmPlexMono(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: resultColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // Game details
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '$questionText ${widget.questionIndex}/${widget.totalQuestions}',
                                      style: GoogleFonts.ibmPlexMono(
                                        fontSize: 14,
                                        color: Colors.white.withOpacity(0.8),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '$scoreText: ${widget.score}',
                                      style: GoogleFonts.ibmPlexMono(
                                        fontSize: 14,
                                        color: Colors.white.withOpacity(0.8),
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  dateText,
                                  style: GoogleFonts.ibmPlexMono(
                                    fontSize: 12,
                                    color: Colors.white.withOpacity(0.6),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return widget.isEnglish ? 'Today' : 'Idag';
    } else if (difference.inDays == 1) {
      return widget.isEnglish ? 'Yesterday' : 'Igår';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ${widget.isEnglish ? 'days ago' : 'dagar sedan'}';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}