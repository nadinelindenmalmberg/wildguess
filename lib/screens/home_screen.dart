import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../models/animal_data.dart';
import '../utils/translation_extension.dart';
import '../widgets/loading_widget.dart';
import '../widgets/error_widget.dart';
import 'quiz_screen.dart';
import 'history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isEnglish = false;
  late Future<AnimalData> _animalFuture;

  void _toggleLanguage() {
    setState(() {
      isEnglish = !isEnglish;
    });
  }

  Future<AnimalData> _loadRandomAnimal() async {
    final apiService = ApiService();
    return await apiService.getRandomAnimal();
  }

  void _refreshAnimal() {
    setState(() {
      _animalFuture = _loadRandomAnimal();
    });
  }

  @override
  void initState() {
    super.initState();
    _animalFuture = _loadRandomAnimal();
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
                // Header with language toggle
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isEnglish ? 'Wild Guess' : 'Vild Gissning',
                      style: GoogleFonts.ibmPlexMono(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
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
                const SizedBox(height: 40),
                
                // Main content
                Expanded(
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
                            // Game icon
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
                            
                            // Title
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
                            
                            // Subtitle
                            Text(
                              isEnglish
                                  ? 'A random animal has been selected.\nCan you guess what it is?'
                                  : 'Ett slumpmässigt djur har valts.\nKan du gissa vad det är?',
                              style: GoogleFonts.ibmPlexMono(
                                fontSize: 17,
                                color: Colors.white.withOpacity(0.8),
                                height: 1.6,
                                fontWeight: FontWeight.w400,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 48),
                            
                            // Play button
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
                                  onTap: () {
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
                                          isEnglish ? 'Play Today\'s Game' : 'Spela dagens spel',
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
                                          // How to play functionality
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
                        color: Colors.white70,
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
