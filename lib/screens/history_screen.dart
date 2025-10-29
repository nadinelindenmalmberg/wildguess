import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/animal_data.dart'; // Import AnimalData
import '../services/history_service.dart';
import 'animal_detail_screen.dart'; // Import the new detail screen
import '../widgets/animal_image_widget.dart'; // Import AnimalImageWidget
import '../utils/translation_extension.dart'; // Import translation extension


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
     // Clear local cache first to force database-only mode
     await HistoryService.clearLocalCache();
     
     // Use database-only method to avoid local fallback
     final history = await HistoryService.getGameHistoryFromDatabaseOnly();
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
       // Optionally show an error message using ScaffoldMessenger
       ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text('Error loading history: $e')),
       );
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
     _loadHistory(); // Reload history after clearing
   }
 }


 @override
 Widget build(BuildContext context) {
   return Scaffold(
     backgroundColor: Colors.black, // Dark background for the screen
     appBar: AppBar(
       title: Text(
         widget.isEnglish ? 'History' : 'Historik',
         style: GoogleFonts.ibmPlexMono(
           fontSize: 22,
           fontWeight: FontWeight.w600,
           color: Colors.white, // White title text
         ),
       ),
       backgroundColor: Colors.black, // Dark AppBar
       iconTheme: const IconThemeData(color: Colors.white), // White back arrow
       actions: [
         if (_historyItems.isNotEmpty)
           IconButton(
             icon: const Icon(Icons.delete_outline),
             onPressed: _clearHistory,
             tooltip: widget.isEnglish ? 'Clear History' : 'Rensa historik',
             color: Colors.white, // White delete icon
           ),
       ],
     ),
     body: SafeArea(
       child: _isLoading
           ? const Center(
               child: CircularProgressIndicator(color: Colors.white), // White loading indicator
             )
           : _historyItems.isEmpty
               ? Center(
                   // Placeholder for empty history
                   child: Column(
                     mainAxisAlignment: MainAxisAlignment.center,
                     children: [
                       Icon(
                         Icons.history_rounded, // Changed icon
                         size: 64,
                         color: Colors.white.withOpacity(0.3), // Faded white icon
                       ),
                       const SizedBox(height: 16),
                       Text(
                         widget.isEnglish
                             ? 'No games played yet'
                             : 'Inga spel spelade än',
                         style: GoogleFonts.ibmPlexMono(
                           fontSize: 18,
                           color: Colors.white.withOpacity(0.7), // Faded white text
                         ),
                       ),
                       const SizedBox(height: 8),
                       Text(
                         widget.isEnglish
                             ? 'Start playing to see your history here'
                             : 'Börja spela för att se din historik här',
                         style: GoogleFonts.ibmPlexMono(
                           fontSize: 14,
                           color: Colors.white.withOpacity(0.5), // More faded white text
                         ),
                       ),
                     ],
                   ),
                 )
               : Column(
                   children: [
                     // Statistics header (semi-transparent white card)
                     if (_statistics.isNotEmpty)
                       Container(
                         margin: const EdgeInsets.all(16),
                         padding: const EdgeInsets.all(16),
                         decoration: BoxDecoration(
                           color: Colors.white.withOpacity(0.1), // Semi-transparent white
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
                                 color: Colors.white, // White text
                               ),
                             ),
                             const SizedBox(height: 12),
                             Row(
                               mainAxisAlignment: MainAxisAlignment.spaceAround,
                               children: [
                                 _buildStatItem(
                                   widget.isEnglish ? 'Games' : 'Spel',
                                   '${_statistics['total_games'] ?? 0}', // Added null check
                                 ),
                                 _buildStatItem(
                                   widget.isEnglish ? 'Correct' : 'Rätt',
                                   '${_statistics['correct_games'] ?? 0}', // Added null check
                                 ),
                                 _buildStatItem(
                                   widget.isEnglish ? 'Accuracy' : 'Träffsäkerhet',
                                   '${(_statistics['accuracy'] ?? 0.0).toStringAsFixed(1)}%', // Added null check
                                 ),
                               ],
                             ),
                           ],
                         ),
                       ),
                     // History list using the new card
                     Expanded(
                       child: ListView.builder(
                         padding: const EdgeInsets.symmetric(horizontal: 16.0),
                         itemCount: _historyItems.length,
                         itemBuilder: (context, index) {
                           final item = _historyItems[index];
                           // Create AnimalData from history map
                           final animalData = AnimalData(
                             name: item['animal_name'] ?? '',
                             scientificName: item['animal_scientific_name'] ?? '',
                             imageUrl: item['animal_image_url'] ?? '',
                             // Provide empty defaults if not saved in history yet
                             description: item['animal_description'] ?? '',
                             hints: (item['animal_hints'] as List<dynamic>?)?.cast<String>() ?? [],
                           );
                           // Get total questions for the item, default to 5 if not found
                           final totalQuestions = item['total_questions'] ?? 5;


                           return Padding(
                             padding: const EdgeInsets.only(bottom: 16.0), // Spacing between cards
                             child: NewHistoryAnimalCard( // Use the new card widget
                               animal: animalData, // Pass AnimalData object
                               isEnglish: widget.isEnglish,
                               isCorrect: item['is_correct'] ?? false,
                               questionIndex: item['question_index'] ?? 0,
                               totalQuestions: totalQuestions, // Pass total questions
                               score: item['score'] ?? 0, // Keep score data if needed elsewhere
                               completedAt: DateTime.tryParse(item['completed_at'] ?? '') ?? DateTime.now(),
                               onTap: () { // Navigation logic
                                 Navigator.push(
                                   context,
                                   MaterialPageRoute(
                                     builder: (context) => AnimalDetailScreen(
                                       animal: animalData, // Pass the AnimalData
                                       isEnglish: widget.isEnglish,
                                     ),
                                   ),
                                 );
                               },
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


 // Helper widget for statistics items
 Widget _buildStatItem(String label, String value) {
   return Column(
     children: [
       Text(
         value,
         style: GoogleFonts.ibmPlexMono(
           fontSize: 20,
           fontWeight: FontWeight.w700,
           color: Colors.white, // White text
         ),
       ),
       const SizedBox(height: 4),
       Text(
         label,
         style: GoogleFonts.ibmPlexMono(
           fontSize: 12,
           color: Colors.white.withOpacity(0.7), // Faded white text
         ),
       ),
     ],
   );
 }
}


// ----------------------------------------------------------------------
// NEW History Animal Card Widget (Based on Quiz Result Style)
// ----------------------------------------------------------------------
class NewHistoryAnimalCard extends StatelessWidget {
 final AnimalData animal;
 final bool isEnglish;
 final bool isCorrect;
 final int questionIndex;
 final int totalQuestions; // Added totalQuestions
 final int score;
 final DateTime completedAt;
 final VoidCallback onTap; // Callback for navigation


 const NewHistoryAnimalCard({
   super.key,
   required this.animal,
   required this.isEnglish,
   required this.isCorrect,
   required this.questionIndex,
   required this.totalQuestions, // Added totalQuestions
   required this.score,
   required this.completedAt,
   required this.onTap,
 });


 @override
 Widget build(BuildContext context) {
   // Determine color based on correctness
   final resultColor = isCorrect ? const Color(0xFF10B981) : Colors.redAccent;


   // *** MODIFIED TEXT: Use questionIndex and totalQuestions ***
   final resultDetailText = isCorrect
       ? '${questionIndex}/$totalQuestions' // Format like 3/5
       : ''; // No detail needed for incorrect guesses


   return Container(
     decoration: BoxDecoration(
       color: const Color(0xFFE7EFE7), // Light background like result card
       borderRadius: BorderRadius.circular(16),
       boxShadow: [ // Subtle shadow
         BoxShadow(
           color: Colors.black.withOpacity(0.1),
           blurRadius: 6,
           offset: const Offset(0, 2),
         ),
       ],
     ),
     clipBehavior: Clip.antiAlias, // Ensures image corners are clipped
     child: Material(
       color: Colors.transparent,
       child: InkWell(
         onTap: onTap, // Trigger navigation
         child: Column(
           crossAxisAlignment: CrossAxisAlignment.start,
           children: [
             // Animal Image or Placeholder
             AnimalImageWidget( // Use the reusable image widget
                 imageUrl: animal.imageUrl,
                 animalName: animal.name.getTranslatedAnimalName(isEnglish),
                 width: double.infinity,
                 height: 110, // Slightly smaller height for list view
                 fit: BoxFit.cover,
                 showPlaceholder: true, // Show placeholder if image fails
             ),


             // Animal Info Section
             Padding(
               padding: const EdgeInsets.all(16.0),
               child: Row(
                 crossAxisAlignment: CrossAxisAlignment.start, // Align items to top
                 children: [
                   // Name, Scientific Name, Date
                   Expanded(
                     child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         Text(
                           animal.name.isNotEmpty 
                             ? animal.name.getTranslatedAnimalName(isEnglish)
                             : (isEnglish ? 'Unknown Animal' : 'Okänt Djur'),
                           style: GoogleFonts.ibmPlexMono(
                             fontSize: 18,
                             fontWeight: FontWeight.w600,
                             color: Colors.black87, // Darker text
                           ),
                           maxLines: 1,
                           overflow: TextOverflow.ellipsis,
                         ),
                         if (animal.scientificName.isNotEmpty) ...[
                           const SizedBox(height: 4),
                           Text(
                             animal.scientificName,
                             style: GoogleFonts.ibmPlexMono(
                               fontSize: 13,
                               color: Colors.black.withOpacity(0.6), // Greyer text
                               fontStyle: FontStyle.italic,
                             ),
                             maxLines: 1,
                             overflow: TextOverflow.ellipsis,
                           ),
                         ],
                         const SizedBox(height: 8),
                         Text(
                           _formatDate(completedAt, isEnglish), // Formatted date
                           style: GoogleFonts.ibmPlexMono(
                             fontSize: 12,
                             color: Colors.black.withOpacity(0.5), // Greyer text
                           ),
                         ),
                       ],
                     ),
                   ),
                   const SizedBox(width: 16),
                   // Result Indicator (Icon + NEW TEXT)
                   Column(
                     mainAxisAlignment: MainAxisAlignment.start, // Align to top
                     crossAxisAlignment: CrossAxisAlignment.end,
                     children: [
                        Icon(
                          isCorrect ? Icons.check_circle_outline_rounded : Icons.highlight_off_rounded,
                          color: resultColor, // Green or Red
                          size: 28,
                        ),
                        const SizedBox(height: 4),
                        // *** DISPLAY THE NEW TEXT (e.g., "3/5") ***
                        if (resultDetailText.isNotEmpty)
                          Text(
                             resultDetailText, // Shows "X/5"
                            style: GoogleFonts.ibmPlexMono(
                               fontSize: 14,
                               fontWeight: FontWeight.w600,
                               color: Colors.black.withOpacity(0.8), // Darker text
                            ),
                          ),
                     ],
                   ),
                 ],
               ),
             ),
           ],
         ),
       ),
     ),
   );
 }


   // Helper function for date formatting
   String _formatDate(DateTime date, bool isEnglish) {
   final now = DateTime.now();
   // Compare dates only, ignoring time
   final todayDate = DateTime(now.year, now.month, now.day);
   final gameDate = DateTime(date.year, date.month, date.day);
   final differenceInDays = todayDate.difference(gameDate).inDays;


   if (differenceInDays == 0) {
     return isEnglish ? 'Today' : 'Idag';
   } else if (differenceInDays == 1) {
     return isEnglish ? 'Yesterday' : 'Igår';
   } else if (differenceInDays < 7) {
     return '$differenceInDays ${isEnglish ? 'days ago' : 'dagar sedan'}';
   } else {
     // Format as DD/MM/YYYY
     return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
   }
 }
}
