import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/statistics_service.dart';

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
        score: 5,
        attempts: 3,
        solved: true,
        timeMs: 30000,
        animalForTesting: testingMode ? 'test_animal' : null,
      );
      setState(() => _status = 'Test score submitted successfully');
    } catch (e) {
      setState(() => _status = 'Error submitting score: $e');
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
}
