import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/animal_data.dart';
import 'home_screen.dart';
import 'quiz_screen.dart';
// Removed QuizScreen import as it's not needed for navigation from here

class QuizResultScreen extends StatelessWidget {
  final AnimalData animal;
  final bool isEnglish;
  final bool isCorrect;
  final int questionIndex; // The attempt number
  final int totalQuestions; // Still available if needed later

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
    // Determine the result text based on correctness and language
    String resultTitle;
    String resultMessage = ''; // Message about the attempt number

    if (isCorrect) {
      resultTitle = isEnglish ? 'You are correct!' : 'Du har rätt!';
      resultMessage = isEnglish
          ? 'You guessed correctly on attempt $questionIndex!'
          : 'Du gissade rätt på försök $questionIndex!';
    } else {
      // Assuming 'Time's up!' means they ran out of attempts or similar
      resultTitle = isEnglish ? 'Time\'s up!' : 'Tiden är ute!';
      // Or provide a message indicating they didn't guess correctly
      resultMessage = isEnglish
          ? 'The correct animal was ${animal.name}.'
          : 'Rätt djur var ${animal.name}.';
    }

    return Scaffold(
      backgroundColor: Colors.black, // Dark background like the image
      body: Container(
        color: Colors.black,
        child: SafeArea(
          child: Padding( // Use Padding instead of SingleChildScrollView if content fits
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24), // Added vertical padding
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center, // Center content horizontally
              children: [
                // --- Result Title ---
                Text(
                  resultTitle,
                  style: GoogleFonts.ibmPlexMono(
                    fontSize: 32, // Kept original size
                    fontWeight: FontWeight.w400,
                    color: Colors.white,
                    letterSpacing: 1.0,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24), // Increased spacing

                // --- Animal Card (Now Stateful) ---
                _ExpandableAnimalCard(
                  animal: animal,
                  isEnglish: isEnglish,
                ),
                const SizedBox(height: 32), // Increased spacing

                // --- Statistics Replacement Text ---
                if (resultMessage.isNotEmpty) // Show message only if defined
                  Text(
                    resultMessage,
                    style: GoogleFonts.ibmPlexMono(
                      color: Colors.white70,
                      fontSize: 14, // Adjusted size
                    ),
                    textAlign: TextAlign.center,
                  ),

                const Spacer(), // Pushes the button to the bottom

                // --- Action Button (Modified) ---
                SizedBox( // Ensure button takes reasonable width
                  width: double.infinity, // Make button wider
                  height: 56,
                  child: ElevatedButton( // Changed to ElevatedButton for style
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[200], // Light background like image
                      foregroundColor: Colors.black, // Black text like image
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const HomeScreen(),
                        ),
                        (route) => false, // Remove all previous routes
                      );
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center, // Center content
                      children: [
                        Text(
                          isEnglish ? 'Back home' : 'Tillbaka hem', // Updated text
                          style: GoogleFonts.ibmPlexMono(
                            fontSize: 18,
                            fontWeight: FontWeight.w400, // Adjusted weight
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward, size: 20), // Arrow like image
                      ],
                    ),
                  ),
                ),
                 const SizedBox(height: 16), // Padding at the very bottom
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ----------------------------------------------------------------------
// _ExpandableAnimalCard (Stateful Widget for the Card)
// ----------------------------------------------------------------------
class _ExpandableAnimalCard extends StatefulWidget {
  final AnimalData animal;
  final bool isEnglish;

  const _ExpandableAnimalCard({required this.animal, required this.isEnglish});

  @override
  State<_ExpandableAnimalCard> createState() => _ExpandableAnimalCardState();
}

class _ExpandableAnimalCardState extends State<_ExpandableAnimalCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final animalName = widget.animal.name.isNotEmpty ? widget.animal.name : 'Unknown Animal';
    final scientificName = widget.animal.scientificName;
    final description = widget.animal.description;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFE7EFE7), // Light background for the card
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias, // Ensures content respects border radius
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // Only toggle if there is a description to show/hide
            if (description.isNotEmpty) {
               setState(() {
                _isExpanded = !_isExpanded;
              });
            }
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Placeholder Image ---
              Container(
                height: 140, // Adjust height as needed
                width: double.infinity,
                color: Colors.grey[300], // Placeholder background color
                child: Icon(
                  Icons.pets, // Placeholder Icon
                  size: 60,
                  color: Colors.grey[600],
                ),
                // TODO: Replace with Image.network(widget.animal.imageUrl) when available
              ),

              // --- Animal Info Header (Always Visible) ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            animalName,
                            style: GoogleFonts.ibmPlexMono(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.black, // Black text on light card
                            ),
                          ),
                          if (scientificName.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              scientificName,
                              style: GoogleFonts.ibmPlexMono(
                                fontSize: 13,
                                color: Colors.black87, // Darker grey text
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    // Show expand icon only if there's content to expand
                    if (description.isNotEmpty)
                      Icon(
                         _isExpanded ? Icons.expand_less : Icons.expand_more,
                         color: Colors.black87
                      ),
                  ],
                ),
              ),

              // --- Collapsible Description Section ---
              AnimatedSize(
                duration: const Duration(milliseconds: 250), // Slightly faster animation
                curve: Curves.easeInOut,
                alignment: Alignment.topCenter,
                child: _isExpanded && description.isNotEmpty
                    ? Column( // Use Column to include Divider
                        children: [
                          const Divider(height: 1, color: Colors.black12),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              description,
                              style: GoogleFonts.ibmPlexMono(
                                fontSize: 14,
                                color: Colors.black87,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      )
                    : const SizedBox.shrink(), // Collapsed state
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Removed _StatsRow class as it's no longer used