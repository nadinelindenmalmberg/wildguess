import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../models/animal_data.dart';
import '../utils/translation_extension.dart';
import '../widgets/loading_widget.dart';
import '../widgets/error_widget.dart';
import '../services/daily_play_service.dart';
import 'quiz_screen.dart';
import 'tutorial_screen.dart';
import 'history_screen.dart';
import 'test_screen.dart';
import 'animal_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isEnglish = true; // Default to English
  late Future<AnimalData> _animalFuture;
  bool _hasPlayedToday = false;
  bool _isLoadingPlayStatus = true;

  @override
  void initState() {
    super.initState();
    _loadLanguage();
    _animalFuture = _loadRandomAnimal();
    _checkPlayStatus();
  }

  Future<void> _loadLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLanguage = prefs.getBool('isEnglish');
      if (savedLanguage != null) {
        setState(() {
          isEnglish = savedLanguage;
        });
      }
    } catch (e) {
      print('Error loading language preference: $e');
    }
  }

  Future<void> _saveLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isEnglish', isEnglish);
    } catch (e) {
      print('Error saving language preference: $e');
    }
  }

  Future<void> _checkPlayStatus() async {
    final hasPlayed = await DailyPlayService.hasPlayedToday();
    setState(() {
      _hasPlayedToday = hasPlayed;
      _isLoadingPlayStatus = false;
    });
  }

  void _toggleLanguage() {
    setState(() {
      isEnglish = !isEnglish;
      _animalFuture = _loadRandomAnimal(); // Reload animal with new language
    });
    _saveLanguage();
  }

  Future<AnimalData> _loadRandomAnimal() async {
    final apiService = ApiService();
    return await apiService.getRandomAnimal(isEnglish: isEnglish);
  }

  void _refreshAnimal() {
    setState(() {
      _animalFuture = _loadRandomAnimal();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        color: Colors.black,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                // Header with language toggle and test button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        isEnglish ? 'Wild Guess' : 'Vild Gissning',
                        style: GoogleFonts.ibmPlexMono(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Test Screen Button (Debug)
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.bug_report, size: 20),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const TestScreen(),
                                ),
                              );
                            },
                            color: Colors.red,
                            style: IconButton.styleFrom(
                              padding: const EdgeInsets.all(8),
                              minimumSize: const Size(40, 40),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Clear Daily Play Button (Debug)
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.refresh, size: 20),
                            onPressed: () async {
                              await DailyPlayService.clearDailyPlay();
                              _checkPlayStatus();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    isEnglish ? 'Daily play cleared!' : 'Dagligt spel rensat!',
                                    style: GoogleFonts.ibmPlexMono(),
                                  ),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            },
                            color: Colors.orange,
                            style: IconButton.styleFrom(
                              padding: const EdgeInsets.all(8),
                              minimumSize: const Size(40, 40),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Language Toggle
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: Icon(
                              isEnglish ? Icons.language : Icons.translate,
                              size: 20,
                            ),
                            onPressed: _toggleLanguage,
                            color: Colors.white,
                            style: IconButton.styleFrom(
                              padding: const EdgeInsets.all(8),
                              minimumSize: const Size(40, 40),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                
                // Main content
                Flexible(
                  child: FutureBuilder<AnimalData>(
                    future: _animalFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const LoadingWidget(message: 'Loading animal data...');
                      } else if (snapshot.hasError) {
                        return ErrorDisplayWidget(
                          message: snapshot.error.toString(),
                          onRetry: _refreshAnimal,
                        );
                      } else if (snapshot.hasData) {
                        final animal = snapshot.data!;
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Game icon or animal image
                            if (_hasPlayedToday)
                              // Show animal image when played
                              Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(60),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.2),
                                    width: 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.3),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(60),
                                  child: animal.imageUrl.isNotEmpty
                                      ? Image.network(
                                          animal.imageUrl,
                                          width: 120,
                                          height: 120,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Container(
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                  colors: [
                                                    Colors.white.withOpacity(0.15),
                                                    Colors.white.withOpacity(0.05),
                                                  ],
                                                ),
                                              ),
                                              child: const Icon(
                                                Icons.pets,
                                                size: 60,
                                                color: Colors.white,
                                              ),
                                            );
                                          },
                                        )
                                      : Container(
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                              colors: [
                                                Colors.white.withOpacity(0.15),
                                                Colors.white.withOpacity(0.05),
                                              ],
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.pets,
                                            size: 60,
                                            color: Colors.white,
                                          ),
                                        ),
                                ),
                              )
                            else
                              // Show game icon when not played
                              Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Colors.white.withOpacity(0.15),
                                      Colors.white.withOpacity(0.05),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(60),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.2),
                                    width: 1,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.pets,
                                  size: 60,
                                  color: Colors.white,
                                ),
                              ),
                            const SizedBox(height: 32),
                            
                            // Title (only show if not played today)
                            if (!_hasPlayedToday) ...[
                              Text(
                                isEnglish ? 'Ready to Play!' : 'Redo att spela!',
                                style: GoogleFonts.ibmPlexMono(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: -0.5,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 20),
                            ],

                            // Subtitle
                            Text(
                              _hasPlayedToday
                                  ? (isEnglish
                                      ? 'You\'ve already played today!\nCome back tomorrow for a new animal.'
                                      : 'Du har redan spelat idag!\nKom tillbaka imorgon för ett nytt djur.')
                                  : (isEnglish
                                      ? 'A random animal has been selected.\nCan you guess what it is?'
                                      : 'Ett slumpmässigt djur har valts.\nKan du gissa vad det är?'),
                              style: GoogleFonts.ibmPlexMono(
                                fontSize: 17,
                                color: Colors.white.withOpacity(0.8),
                                height: 1.6,
                                fontWeight: FontWeight.w400,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 48),

                           // Today's animal display (only show if already played)
                           if (_hasPlayedToday) ...[
                             GestureDetector(
                               onTap: () {
                                 Navigator.push(
                                   context,
                                   MaterialPageRoute(
                                     builder: (context) => AnimalDetailScreen(
                                       animal: animal,
                                       isEnglish: isEnglish,
                                     ),
                                   ),
                                 );
                               },
                               child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF374151),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: const Color(0xFF6B7280), 
                                    width: 1,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      isEnglish ? "Today's Animal" : "Dagens djur",
                                      style: GoogleFonts.ibmPlexMono(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white70,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      animal.name,
                                      style: GoogleFonts.ibmPlexMono(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                    if (animal.scientificName.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        animal.scientificName,
                                        style: GoogleFonts.ibmPlexMono(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w400,
                                          color: Colors.white60,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                ),
                              ),
                              const SizedBox(height: 24),
                            ],
                            
                            // Play button or status
                            if (_isLoadingPlayStatus)
                              Container(
                                width: double.infinity,
                                height: 64,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF374151),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                  ),
                                ),
                              )
                            else if (_hasPlayedToday)
                              Container(
                                width: double.infinity,
                                height: 64,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1F2937), 
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: const Color(0xFF374151),
                                    width: 1,
                                  ),
                                ),
                                child: Center(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.check_circle,
                                        color: Colors.green[400],
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            isEnglish ? "Already played today!" : "Redan spelat idag!",
                                            style: GoogleFonts.ibmPlexMono(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white70,
                                            ),
                                          ),
                                          Text(
                                            isEnglish ? "Come back tomorrow" : "Kom tillbaka imorgon",
                                            style: GoogleFonts.ibmPlexMono(
                                              fontSize: 11,
                                              color: Colors.white60,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            else
                              Container(
                                width: double.infinity,
                                height: 64,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Color(0xFF10B981),
                                      Color(0xFF059669),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF10B981).withOpacity(0.3),
                                      blurRadius: 20,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(20),
                                    onTap: () async {
                                      // Mark as played and navigate
                                      await DailyPlayService.markPlayedToday();
                                      await DailyPlayService.setTodaysAnimal(animal);
                                      
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => QuizScreen(
                                            animal: animal,
                                            isEnglish: isEnglish,
                                          ),
                                        ),
                                      );
                                    },
                                    child: Center(
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(
                                            Icons.play_arrow_rounded,
                                            color: Colors.white,
                                            size: 24,
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            isEnglish ? 'Guess Today\'s Animal' : 'Gissa dagens djur',
                                            style: GoogleFonts.ibmPlexMono(
                                              fontSize: 19,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                              letterSpacing: -0.2,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            const SizedBox(height: 24),
                            
                            // Secondary buttons
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    height: 52,
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
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => HistoryScreen(isEnglish: isEnglish),
                                            ),
                                          );
                                        },
                                        child: Center(
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.history_rounded,
                                                color: Colors.white.withOpacity(0.9),
                                                size: 18,
                                              ),
                                              const SizedBox(width: 10),
                                              Text(
                                                isEnglish ? 'History' : 'Historik',
                                                style: GoogleFonts.ibmPlexMono(
                                                  fontSize: 15,
                                                  color: Colors.white.withOpacity(0.9),
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Container(
                                    height: 52,
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
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => HowToPlayScreen(
                                                isEnglish: isEnglish,
                                              ),
                                            ),
                                          );
                                        },
                                        child: Center(
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.help_outline_rounded,
                                                color: Colors.white.withOpacity(0.9),
                                                size: 18,
                                              ),
                                              const SizedBox(width: 10),
                                              Text(
                                                isEnglish ? 'How to play' : 'Hur man spelar',
                                                style: GoogleFonts.ibmPlexMono(
                                                  fontSize: 15,
                                                  color: Colors.white.withOpacity(0.9),
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      } else {
                        return const LoadingWidget(message: 'Loading...');
                      }
                    },
                  ),
                ),
                
                // Refresh button
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: TextButton(
                    onPressed: _refreshAnimal,
                    child: Text(
                      isEnglish ? 'Get New Animal' : 'Få nytt djur',
                      style: GoogleFonts.ibmPlexMono(
                        color: Colors.black,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}