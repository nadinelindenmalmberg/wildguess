import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HistoryScreen extends StatelessWidget {
  final bool isEnglish;

  const HistoryScreen({super.key, required this.isEnglish});

  @override
  Widget build(BuildContext context) {
    // Placeholder list of animals (15 items for scroll testing, but ListView.builder handles many more)
    final List<Map<String, String>> historyItems = [
      {'name_en': 'Moose', 'name_sv': 'Älg', 'image_url': 'https://example.com/moose.jpg'},
      {'name_en': 'Wolf', 'name_sv': 'Varg', 'image_url': 'https://example.com/wolf.jpg'},
      {'name_en': 'Lynx', 'name_sv': 'Lo', 'image_url': 'https://example.com/lynx.jpg'},
      {'name_en': 'Brown Bear', 'name_sv': 'Brunbjörn', 'image_url': 'https://example.com/bear.jpg'},
      {'name_en': 'Reindeer', 'name_sv': 'Renen', 'image_url': 'https://example.com/reindeer.jpg'},
      {'name_en': 'Wild Boar', 'name_sv': 'Vildsvin', 'image_url': 'https://example.com/boar.jpg'},
      {'name_en': 'Red Fox', 'name_sv': 'Rödräv', 'image_url': 'https://example.com/fox.jpg'},
      {'name_en': 'Beaver', 'name_sv': 'Bäver', 'image_url': 'https://example.com/beaver.jpg'},
      {'name_en': 'Arctic Fox', 'name_sv': 'Fjällräv', 'image_url': 'https://example.com/arcticfox.jpg'},
      {'name_en': 'Hare', 'name_sv': 'Hare', 'image_url': 'https://example.com/hare.jpg'},
      {'name_en': 'Otter', 'name_sv': 'Utter', 'image_url': 'https://example.com/otter.jpg'},
      {'name_en': 'Seal', 'name_sv': 'Säl', 'image_url': 'https://example.com/seal.jpg'},
      {'name_en': 'Pine Marten', 'name_sv': 'Mård', 'image_url': 'https://example.com/marten.jpg'},
      {'name_en': 'Wolverine', 'name_sv': 'Järv', 'image_url': 'https://example.com/wolverine.jpg'},
      {'name_en': 'Red Deer', 'name_sv': 'Kronhjort', 'image_url': 'https://example.com/reddeer.jpg'},
      // Add more items here if needed for testing longer lists
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
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      // --- MODIFIED BODY ---
      body: SafeArea(
        // Use ListView.builder for efficient scrolling with potentially many items
        child: ListView.builder(
          padding: const EdgeInsets.all(16.0), // Apply padding to the ListView itself
          itemCount: historyItems.length,      // Tell the ListView how many items there are
          itemBuilder: (context, index) {
            final item = historyItems[index]; // Get the data for the current item
            // Return the widget for this list item, wrapped in padding
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0), // Add spacing between cards
              child: HistoryAnimalCard(
                nameEn: item['name_en']!,
                nameSv: item['name_sv']!,
                imageUrl: item['image_url']!,
                isEnglish: isEnglish,
              ),
            );
          },
        ),
      ),
      // --- END OF MODIFIED BODY ---
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

  const HistoryAnimalCard({
    super.key,
    required this.nameEn,
    required this.nameSv,
    required this.imageUrl,
    required this.isEnglish,
  });

  @override
  State<HistoryAnimalCard> createState() => _HistoryAnimalCardState();
}

class _HistoryAnimalCardState extends State<HistoryAnimalCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final animalName = widget.isEnglish ? widget.nameEn : widget.nameSv;
    final factsLabel = widget.isEnglish ? 'Facts:' : 'Fakta:';
    const placeholderFact1 = 'Habitat: Found across all Swedish forests and mountains.';
    const placeholderFact2 = 'Diet: Primarily vegetarian, but occasionally eats berries.';
    const placeholderFactSv1 = 'Habitat: Finns i alla svenska skogar och berg.';
    const placeholderFactSv2 = 'Diet: Huvudsakligen vegetarisk, men äter ibland bär.';
    final factText1 = widget.isEnglish ? placeholderFact1 : placeholderFactSv1;
    final factText2 = widget.isEnglish ? placeholderFact2 : placeholderFactSv2;

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
                            Text(
                              factsLabel,
                              style: GoogleFonts.ibmPlexMono(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '— $factText1',
                              style: GoogleFonts.ibmPlexMono(
                                fontSize: 14,
                                color: Colors.white70,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '— $factText2',
                              style: GoogleFonts.ibmPlexMono(
                                fontSize: 14,
                                color: Colors.white70,
                                height: 1.4,
                              ),
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
}