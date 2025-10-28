import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/animal_data.dart'; // Import AnimalData
import '../widgets/animal_image_widget.dart'; // Import AnimalImageWidget
import '../services/ai_clue_service.dart'; // Import AI service
import '../utils/translation_extension.dart'; // Import translation extension

class AnimalDetailScreen extends StatefulWidget {
  final AnimalData animal;
  final bool isEnglish;

  const AnimalDetailScreen({
    super.key,
    required this.animal,
    required this.isEnglish,
  });

  @override
  State<AnimalDetailScreen> createState() => _AnimalDetailScreenState();
}

class _AnimalDetailScreenState extends State<AnimalDetailScreen> {
  final AiClueService _aiClueService = AiClueService();
  List<String> _aiFacts = [];
  bool _isLoadingFacts = true;

  @override
  void initState() {
    super.initState();
    _loadAiFacts();
  }

  @override
  void dispose() {
    _aiClueService.dispose();
    super.dispose();
  }

  Future<void> _loadAiFacts() async {
    if (!mounted) return;
    print('[AnimalDetailScreen] Loading AI facts for: ${widget.animal.name}');
    setState(() {
      _isLoadingFacts = true;
    });
    try {
      final facts = await _aiClueService.generateFacts(
        widget.animal,
        isEnglish: widget.isEnglish,
      );
      print('[AnimalDetailScreen] Received ${facts.length} facts: $facts');
      if (mounted) {
        setState(() {
          _aiFacts = facts;
          _isLoadingFacts = false;
        });
      }
    } catch (e) {
      print("Failed to load AI facts in AnimalDetailScreen: $e");
      if (mounted) {
        setState(() {
          _isLoadingFacts = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // *** 1. Set Scaffold background to black ***
      backgroundColor: Colors.black,
      appBar: AppBar(
        // Make AppBar transparent to show black background
        backgroundColor: Colors.transparent,
        elevation: 0,
        // *** 2. Change AppBar icon/title color to white for contrast ***
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          widget.isEnglish ? 'Animal Details' : 'Djurdetaljer',
          style: GoogleFonts.ibmPlexMono(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white, // White title
          ),
        ),
      ),
      // *** 3. Use SafeArea and Padding for spacing around the card ***
      body: SafeArea(
        child: Padding(
          // Add padding around the card container
          padding: const EdgeInsets.all(16.0),
          child: Container(
            // *** 4. Main content container styled as a card ***
            decoration: BoxDecoration(
              color: const Color(0xFFE7EFE7), // Light background for the card
              borderRadius: BorderRadius.circular(20), // Rounded corners
            ),
            clipBehavior: Clip.antiAlias, // Clip content like image to rounded corners
            child: SingleChildScrollView(
              // *** 5. Add padding inside the card ***
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Animal Image (clipped by the container)
                  if (widget.animal.imageUrl.isNotEmpty)
                    AnimalImageWidget(
                      imageUrl: widget.animal.imageUrl,
                      animalName: widget.animal.name.getTranslatedAnimalName(widget.isEnglish),
                      width: double.infinity,
                      height: 250, // Adjust height as needed
                      fit: BoxFit.cover,
                    )
                  else // Placeholder if no image
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        // No need for border radius here, clipped by parent
                      ),
                      child: Center(
                        child: Icon(Icons.pets, size: 64, color: Colors.grey[400]),
                      ),
                    ),
                  const SizedBox(height: 24),

                  // Animal Name (ensure text color is black)
                  Text(
                    widget.animal.name.isNotEmpty 
                      ? widget.animal.name.getTranslatedAnimalName(widget.isEnglish)
                      : (widget.isEnglish ? 'Unknown Animal' : 'Okänt Djur'),
                    style: GoogleFonts.ibmPlexMono(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87, // Dark text
                    ),
                  ),
                  // Scientific Name
                  if (widget.animal.scientificName.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      widget.animal.scientificName,
                      style: GoogleFonts.ibmPlexMono(
                        fontSize: 16,
                        color: Colors.black.withOpacity(0.7), // Dark text
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),

                  // Description Section
                  if (widget.animal.description.isNotEmpty) ...[
                    Text(
                      widget.isEnglish ? 'Description' : 'Beskrivning',
                      style: GoogleFonts.ibmPlexMono(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87, // Dark text
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.animal.description,
                      style: GoogleFonts.ibmPlexMono(
                        fontSize: 15,
                        color: Colors.black.withOpacity(0.8), // Dark text
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // AI Facts Section (replaces hints)
                  Text(
                    widget.isEnglish ? 'Interesting Facts' : 'Intressanta fakta',
                    style: GoogleFonts.ibmPlexMono(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87, // Dark text
                    ),
                  ),
                  const SizedBox(height: 12),
                  
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
                      children: _aiFacts.map((fact) => _buildFactItem(fact)).toList(),
                    )
                  else if (widget.animal.hints.isNotEmpty) // Fallback to original hints
                    Column(
                      children: widget.animal.hints.take(3).map((hint) => _buildFactItem(hint)).toList(),
                    )
                  else
                    Text(
                      widget.isEnglish ? 'No interesting facts available.' : 'Inga intressanta fakta tillgängliga.',
                      style: GoogleFonts.ibmPlexMono(fontSize: 13, color: Colors.black54),
                    ),
                  
                  const SizedBox(height: 16), // Add padding at the bottom inside card
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Helper widget for displaying facts
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
}
