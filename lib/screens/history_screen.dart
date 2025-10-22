import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HistoryScreen extends StatelessWidget {
  final bool isEnglish;

  const HistoryScreen({super.key, required this.isEnglish});

  @override
  Widget build(BuildContext context) {
    // Placeholder data structure for history items
    final List<Map<String, String>> historyItems = [
      {
        'name_en': 'Moose',
        'name_sv': 'Älg',
        'image_url': 'https://example.com/moose.jpg', // Placeholder URL
      },
      {
        'name_en': 'Wolf',
        'name_sv': 'Varg',
        'image_url': 'https://example.com/wolf.jpg', // Placeholder URL
      },
      {
        'name_en': 'Lynx',
        'name_sv': 'Lo',
        'image_url': 'https://example.com/lynx.jpg', // Placeholder URL
      },
      // Add more placeholder animals as needed
    ];

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          isEnglish ? 'History' : 'Historik',
          style: GoogleFonts.ibmPlexMono(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white), // Set back button color
      ),
      body: SafeArea(
        child: historyItems.isEmpty
            ? Center(
                child: Text(
                  isEnglish ? 'No game history yet.' : 'Ingen spelhistorik ännu.',
                  style: GoogleFonts.ibmPlexMono(
                    color: Colors.white54,
                    fontSize: 16,
                  ),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: historyItems.length,
                itemBuilder: (context, index) {
                  final item = historyItems[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: HistoryAnimalCard(
                      name: isEnglish ? item['name_en']! : item['name_sv']!,
                      imageUrl: item['image_url']!,
                    ),
                  );
                },
              ),
      ),
    );
  }
}

// Custom Widget for the Animal Card
class HistoryAnimalCard extends StatelessWidget {
  final String name;
  final String imageUrl;

  const HistoryAnimalCard({
    super.key,
    required this.name,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.15),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          // Placeholder for the Animal Image
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.2), // Use app primary color
              borderRadius: BorderRadius.circular(10),
            ),
            // Placeholder icon since we don't have real images yet
            child: const Icon(
              Icons.image,
              color: Color(0xFF10B981),
              size: 30,
            ),
            // When API is ready, you will replace this with:
            // child: Image.network(imageUrl, fit: BoxFit.cover),
          ),
          const SizedBox(width: 16),
          // Animal Name
          Text(
            name,
            style: GoogleFonts.ibmPlexMono(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const Spacer(),
          // Placeholder for a fact/detail button
          Icon(
            Icons.chevron_right_rounded,
            color: Colors.white.withOpacity(0.6),
          ),
        ],
      ),
    );
  }
}