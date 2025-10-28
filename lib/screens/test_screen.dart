import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/statistics_service.dart';
import '../services/daily_play_service.dart';
import '../services/history_service.dart';
import '../services/api_service.dart';
import '../models/animal_data.dart';

class TestScreen extends StatefulWidget {
  const TestScreen({super.key});

  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  bool _isLoading = false;
  String _status = 'Ready to test';
  List<Map<String, dynamic>> _leaderboard = [];
  Map<String, dynamic> _myRank = {};
  String _nickname = '';
  
  // Text controllers for database manipulation
  final TextEditingController _animalNameController = TextEditingController();
  final TextEditingController _scientificNameController = TextEditingController();
  final TextEditingController _imageUrlController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _hintsController = TextEditingController();

  @override
  void dispose() {
    _animalNameController.dispose();
    _scientificNameController.dispose();
    _imageUrlController.dispose();
    _descriptionController.dispose();
    _hintsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          'Supabase Test Screen',
          style: GoogleFonts.ibmPlexMono(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Testing Mode Toggle
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Text(
                    'Testing Mode:',
                    style: GoogleFonts.ibmPlexMono(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Switch(
                    value: testingMode,
                    onChanged: (value) {
                      setState(() {
                        testingMode = value;
                      });
                    },
                    activeColor: Colors.green,
                    inactiveThumbColor: Colors.grey,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Status
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Text(
                _status,
                style: GoogleFonts.ibmPlexMono(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Nickname Input
            TextField(
              style: GoogleFonts.ibmPlexMono(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Nickname',
                labelStyle: GoogleFonts.ibmPlexMono(color: Colors.white70),
                hintText: 'Enter your nickname',
                hintStyle: GoogleFonts.ibmPlexMono(color: Colors.white54),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.blue),
                ),
              ),
              onChanged: (value) => _nickname = value,
            ),
            const SizedBox(height: 16),

            // Animal data input fields
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Animal Data Input:',
                    style: GoogleFonts.ibmPlexMono(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _animalNameController,
                    style: GoogleFonts.ibmPlexMono(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Animal Name',
                      labelStyle: GoogleFonts.ibmPlexMono(color: Colors.white70),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.blue),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _scientificNameController,
                    style: GoogleFonts.ibmPlexMono(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Scientific Name (optional)',
                      labelStyle: GoogleFonts.ibmPlexMono(color: Colors.white70),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.blue),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _imageUrlController,
                    style: GoogleFonts.ibmPlexMono(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Image URL (optional)',
                      labelStyle: GoogleFonts.ibmPlexMono(color: Colors.white70),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.blue),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _descriptionController,
                    style: GoogleFonts.ibmPlexMono(color: Colors.white),
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: 'Description (optional)',
                      labelStyle: GoogleFonts.ibmPlexMono(color: Colors.white70),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.blue),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _hintsController,
                    style: GoogleFonts.ibmPlexMono(color: Colors.white),
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Hints (one per line, optional)',
                      labelStyle: GoogleFonts.ibmPlexMono(color: Colors.white70),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.blue),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Test Buttons
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildTestButton(
                  'Set Nickname',
                  Icons.person,
                  Colors.blue,
                  () => _setNickname(),
                ),
                _buildTestButton(
                  'Submit Test Score',
                  Icons.score,
                  Colors.green,
                  () => _submitTestScore(),
                ),
                _buildTestButton(
                  'Submit Failed Score',
                  Icons.cancel,
                  Colors.red,
                  () => _submitFailedScore(),
                ),
                _buildTestButton(
                  'Get Leaderboard',
                  Icons.leaderboard,
                  Colors.orange,
                  () => _getLeaderboard(),
                ),
                _buildTestButton(
                  'Get My Rank',
                  Icons.emoji_events,
                  Colors.purple,
                  () => _getMyRank(),
                ),
                _buildTestButton(
                  'Clear Data',
                  Icons.clear,
                  Colors.red,
                  () => _clearData(),
                ),
                _buildTestButton(
                  'Reset Today\'s Play',
                  Icons.refresh,
                  Colors.amber,
                  () => _resetTodaysPlay(),
                ),
                _buildTestButton(
                  'Clear Species Cache',
                  Icons.clear_all,
                  Colors.purple,
                  () => _clearSpeciesCache(),
                ),
                // Database manipulation buttons
                _buildTestButton(
                  'Set Today\'s Animal',
                  Icons.today,
                  Colors.teal,
                  () => _setTodaysAnimal(),
                ),
                _buildTestButton(
                  'Add History Animal',
                  Icons.history,
                  Colors.indigo,
                  () => _addHistoryAnimal(),
                ),
                _buildTestButton(
                  'Clear All Data',
                  Icons.delete_forever,
                  Colors.red,
                  () => _clearAllData(),
                ),
                _buildTestButton(
                  'View Database State',
                  Icons.storage,
                  Colors.cyan,
                  () => _viewDatabaseState(),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Results
            if (_leaderboard.isNotEmpty) ...[
              Text(
                'Leaderboard:',
                style: GoogleFonts.ibmPlexMono(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: _leaderboard.length,
                  itemBuilder: (context, index) {
                    final entry = _leaderboard[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          Text(
                            '${index + 1}.',
                            style: GoogleFonts.ibmPlexMono(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              entry['nickname'] ?? 'Anonymous',
                              style: GoogleFonts.ibmPlexMono(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          Text(
                            'Score: ${entry['score']}',
                            style: GoogleFonts.ibmPlexMono(
                              color: Colors.green,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],

            if (_myRank.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.purple.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'My Rank:',
                      style: GoogleFonts.ibmPlexMono(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Rank: ${_myRank['rank'] ?? 'N/A'}',
                      style: GoogleFonts.ibmPlexMono(color: Colors.white),
                    ),
                    Text(
                      'Score: ${_myRank['score'] ?? 'N/A'}',
                      style: GoogleFonts.ibmPlexMono(color: Colors.white),
                    ),
                    Text(
                      'Total Players: ${_myRank['total_players'] ?? 0}',
                      style: GoogleFonts.ibmPlexMono(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTestButton(String text, IconData icon, Color color, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: _isLoading ? null : onPressed,
      icon: Icon(icon, size: 16),
      label: Text(text),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Future<void> _setNickname() async {
    if (_nickname.isEmpty) {
      setState(() => _status = 'Please enter a nickname first');
      return;
    }

    setState(() {
      _isLoading = true;
      _status = 'Setting nickname...';
    });

    try {
      await setNickname(_nickname);
      setState(() => _status = 'Nickname set successfully: $_nickname');
    } catch (e) {
      setState(() => _status = 'Error setting nickname: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _submitTestScore() async {
    setState(() {
      _isLoading = true;
      _status = 'Submitting test score...';
    });

    try {
      await submitScore(
        attempts: 3,
        solved: true,
        timeMs: 30000,
        animalForTesting: testingMode ? 'test_animal' : null,
        animalName: 'test_animal',
      );
      setState(() => _status = 'Test score submitted successfully');
    } catch (e) {
      setState(() => _status = 'Error submitting score: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _submitFailedScore() async {
    setState(() {
      _isLoading = true;
      _status = 'Submitting failed score...';
    });

    try {
      await submitScore(
        attempts: 5,
        solved: false,
        timeMs: 60000,
        animalForTesting: testingMode ? 'test_animal_failed' : null,
        animalName: 'test_animal_failed',
      );
      setState(() => _status = 'Failed score submitted successfully');
    } catch (e) {
      setState(() => _status = 'Error submitting failed score: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _getLeaderboard() async {
    setState(() {
      _isLoading = true;
      _status = 'Fetching leaderboard...';
    });

    try {
      final leaderboard = await getTopToday(
        limit: 10,
        animalForTesting: testingMode ? 'test_animal' : null,
      );
      setState(() {
        _leaderboard = leaderboard;
        _status = 'Leaderboard loaded (${leaderboard.length} entries)';
      });
    } catch (e) {
      setState(() => _status = 'Error fetching leaderboard: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _getMyRank() async {
    setState(() {
      _isLoading = true;
      _status = 'Fetching my rank...';
    });

    try {
      final rank = await getMyRank(
        animalForTesting: testingMode ? 'test_animal' : null,
      );
      setState(() {
        _myRank = rank;
        _status = 'My rank loaded';
      });
    } catch (e) {
      setState(() => _status = 'Error fetching my rank: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _clearData() {
    setState(() {
      _leaderboard = [];
      _myRank = {};
      _status = 'Data cleared';
    });
  }

  // Database manipulation methods
  Future<void> _setTodaysAnimal() async {
    if (_animalNameController.text.isEmpty) {
      setState(() => _status = 'Please enter an animal name first');
      return;
    }

    setState(() {
      _isLoading = true;
      _status = 'Setting today\'s animal...';
    });

    try {
      // Submit a score for today's animal to establish it in the database
      await submitScore(
        attempts: 1,
        solved: true,
        timeMs: 1000,
        animalForTesting: testingMode ? _animalNameController.text : null,
        animalName: _animalNameController.text,
      );
      setState(() => _status = 'Today\'s animal set to: ${_animalNameController.text}');
    } catch (e) {
      setState(() => _status = 'Error setting today\'s animal: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addHistoryAnimal() async {
    if (_animalNameController.text.isEmpty) {
      setState(() => _status = 'Please enter an animal name first');
      return;
    }

    setState(() {
      _isLoading = true;
      _status = 'Adding history animal...';
    });

    try {
      // Create a fake animal data for history
      final animal = AnimalData(
        name: _animalNameController.text,
        scientificName: _scientificNameController.text.isNotEmpty 
            ? _scientificNameController.text 
            : 'Scientific name not provided',
        imageUrl: _imageUrlController.text.isNotEmpty 
            ? _imageUrlController.text 
            : 'https://via.placeholder.com/400x300?text=${Uri.encodeComponent(_animalNameController.text)}',
        description: _descriptionController.text.isNotEmpty 
            ? _descriptionController.text 
            : 'Description not provided',
        hints: _hintsController.text.isNotEmpty 
            ? _hintsController.text.split('\n').where((h) => h.trim().isNotEmpty).toList()
            : ['Hint 1: This is a test animal', 'Hint 2: It lives in the wild', 'Hint 3: It has four legs'],
      );

      // Save to local history
      await HistoryService.saveGameHistory(
        animal: animal,
        isCorrect: true,
        questionIndex: 2, // Solved on 2nd try
        totalQuestions: 5,
        completedAt: DateTime.now().subtract(Duration(days: Random().nextInt(30))), // Random date in last 30 days
      );

      setState(() => _status = 'History animal added: ${_animalNameController.text}');
    } catch (e) {
      setState(() => _status = 'Error adding history animal: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _clearAllData() async {
    setState(() {
      _isLoading = true;
      _status = 'Clearing all data...';
    });

    try {
      // Clear local history
      await HistoryService.clearHistory();
      
      // Clear daily play status
      await DailyPlayService.clearDailyPlay();
      
      // Clear species cache
      ApiService.clearSpeciesCache();
      
      setState(() => _status = 'All data cleared successfully');
    } catch (e) {
      setState(() => _status = 'Error clearing data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _viewDatabaseState() async {
    setState(() {
      _isLoading = true;
      _status = 'Fetching database state...';
    });

    try {
      // Get local history
      final history = await HistoryService.getGameHistory();
      
      // Get today's leaderboard
      final leaderboard = await getTopToday(limit: 10);
      
      // Get play status
      final hasPlayed = await DailyPlayService.hasPlayedToday();
      
      setState(() {
        _status = 'Database State:\n'
            'Local History: ${history.length} games\n'
            'Today\'s Leaderboard: ${leaderboard.length} entries\n'
            'Has Played Today: $hasPlayed\n'
            'Testing Mode: $testingMode';
      });
    } catch (e) {
      setState(() => _status = 'Error fetching database state: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _resetTodaysPlay() async {
    setState(() {
      _isLoading = true;
      _status = 'Resetting today\'s play...';
    });

    try {
      // Clear daily play status
      await DailyPlayService.clearDailyPlay();
      
      // Clear local history for today to fix statistics
      final history = await HistoryService.getGameHistory();
      final today = DateTime.now();
      final todayDate = DateTime(today.year, today.month, today.day);
      
      // Remove all entries from today
      final filteredHistory = history.where((game) {
        final gameDate = DateTime.parse(game['completed_at']);
        final gameDay = DateTime(gameDate.year, gameDate.month, gameDate.day);
        return gameDay != todayDate;
      }).toList();
      
      // Save filtered history back
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('game_history', json.encode(filteredHistory));
      
      setState(() {
        _status = 'Today\'s play reset! History cleared. You can now play again.';
      });
    } catch (e) {
      setState(() => _status = 'Error resetting today\'s play: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _clearSpeciesCache() {
    ApiService.clearSpeciesCache();
    setState(() {
      _status = 'Species cache cleared! Animals will reload with new language.';
    });
  }
}
