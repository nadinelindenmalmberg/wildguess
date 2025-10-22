import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// En ny skärm som visar instruktioner för spelet
class HowToPlayScreen extends StatelessWidget {
  final bool isEnglish;

  const HowToPlayScreen({super.key, required this.isEnglish});

  @override
  Widget build(BuildContext context) {
    // Definiera det översatta innehållet
    final String title = isEnglish ? 'How to Play' : 'Hur man spelar';
    final List<Map<String, String>> instructions = [
      {
        'title_en': 'Guess the Animal',
        'title_sv': 'Gissa Djuret',
        'body_en': 'You will be presented with 5 questions in decreasing difficulty, about a specific swedish mammal. Your goal is simple: guess the animal!',
        'body_sv': 'Du kommer att presenteras med 5 frågor i fallande svårighetsgrad, om ett specifikt svenskt däggdjur. Ditt mål är enkelt: gissa djuret!',
      },
      {
        'title_en': 'Daily game',
        'title_sv': 'Använd Ledtrådarna',
        'body_en': 'You can play the game once per day. After 24 hours, you will be able to play the game again, with a new animal.',
        'body_sv': 'Du kan spela spelet en gång per dag. Efter 24 timmar kommer du att kunna spela spelet igen, med ett nytt djur.',
      },
      {
        'title_en': 'Highest Score',
        'title_sv': 'Högsta Poängen',
        'body_en': 'The fewer guesses it takes to guess the correct animal, the higher your score will be!',
        'body_sv': 'Ju färre frågor du använder för att gissa det korrekta djuret, desto högre blir din poäng!',
      },
      {
        'title_en': 'One Chance Only',
        'title_sv': 'Bara en chans',
        'body_en': 'You get only one attempt to submit your final guess per question. Make sure you are confident before you lock it in!',
        'body_sv': 'Du får bara ett försök att skicka in din slutgiltiga gissning per fråga. Se till att du är säker innan du låser den!',
      },
    ];

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          title,
          style: GoogleFonts.ibmPlexMono(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white), // För tillbaka-knappen
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: ListView(
            padding: const EdgeInsets.only(top: 20, bottom: 40),
            children: instructions.map((step) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: _InstructionStep(
                  title: isEnglish ? step['title_en']! : step['title_sv']!,
                  body: isEnglish ? step['body_en']! : step['body_sv']!,
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

// En hjälp-widget för att formatera varje instruktionssteg
class _InstructionStep extends StatelessWidget {
  final String title;
  final String body;

  const _InstructionStep({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.check_circle_outline,
              color: Color(0xFF10B981), // Grön färg från hemskärmens knapp
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.ibmPlexMono(
                      fontSize: 19,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    body,
                    style: GoogleFonts.ibmPlexMono(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.7),
                      height: 1.4,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
