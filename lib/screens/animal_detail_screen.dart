import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/animal_data.dart'; // Import AnimalData
import '../widgets/animal_image_widget.dart'; // Import AnimalImageWidget

class AnimalDetailScreen extends StatelessWidget {
  final AnimalData animal;
  final bool isEnglish;

  const AnimalDetailScreen({
    super.key,
    required this.animal,
    required this.isEnglish,
  });

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
          isEnglish ? 'Animal Details' : 'Djurdetaljer',
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
                  if (animal.imageUrl.isNotEmpty)
                    AnimalImageWidget(
                      imageUrl: animal.imageUrl,
                      animalName: animal.name,
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
                    animal.name.isNotEmpty ? animal.name : 'Unknown Animal',
                    style: GoogleFonts.ibmPlexMono(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87, // Dark text
                    ),
                  ),
                  // Scientific Name
                  if (animal.scientificName.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      animal.scientificName,
                      style: GoogleFonts.ibmPlexMono(
                        fontSize: 16,
                        color: Colors.black.withOpacity(0.7), // Dark text
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),

                  // Description Section
                  if (animal.description.isNotEmpty) ...[
                    Text(
                      isEnglish ? 'Description' : 'Beskrivning',
                      style: GoogleFonts.ibmPlexMono(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87, // Dark text
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      animal.description,
                      style: GoogleFonts.ibmPlexMono(
                        fontSize: 15,
                        color: Colors.black.withOpacity(0.8), // Dark text
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Hints/Facts Section
                  if (animal.hints.isNotEmpty) ...[
                    Text(
                      isEnglish ? 'Interesting Facts / Clues' : 'Intressanta fakta / Ledtrådar',
                      style: GoogleFonts.ibmPlexMono(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87, // Dark text
                      ),
                    ),
                    const SizedBox(height: 12),
                    Column(
                      children: animal.hints.map((hint) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 6, right: 10),
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Colors.black54, // Dark bullet
                                shape: BoxShape.circle,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                hint,
                                style: GoogleFonts.ibmPlexMono(
                                  fontSize: 14,
                                  color: Colors.black.withOpacity(0.8), // Dark text
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )).toList(),
                    ),
                    const SizedBox(height: 16), // Add padding at the bottom inside card
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}