import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AnimalImageWidget extends StatelessWidget {
  final String imageUrl;
  final String animalName;
  final double? width;
  final double? height;
  final BoxFit fit;
  final bool showPlaceholder;

  const AnimalImageWidget({
    super.key,
    required this.imageUrl,
    required this.animalName,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.showPlaceholder = true,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) {
      return _buildPlaceholder();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        imageUrl,
        width: width,
        height: height,
        fit: fit,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;

          return Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Loading image...',
                    style: GoogleFonts.ibmPlexMono(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return showPlaceholder
              ? _buildPlaceholder()
              : const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[300]!,
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.pets,
            size: (height != null ? height! * 0.3 : 40)
                .clamp(20.0, 60.0)
                .toDouble(),
            color: Colors.grey[400],
          ),
          const SizedBox(height: 8),
          Text(
            animalName,
            style: GoogleFonts.ibmPlexMono(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// A specialized widget for displaying animal images in the quiz
class QuizAnimalImageWidget extends StatelessWidget {
  final String imageUrl;
  final String animalName;
  final bool isRevealed;
  final VoidCallback? onTap;

  const QuizAnimalImageWidget({
    super.key,
    required this.imageUrl,
    required this.animalName,
    this.isRevealed = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // Main image
              AnimalImageWidget(
                imageUrl: imageUrl,
                animalName: animalName,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
              ),

              // Overlay for unrevealed state
              if (!isRevealed)
                Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.visibility_off,
                          size: 48,
                          color: Colors.white.withOpacity(0.8),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Tap to reveal',
                          style: GoogleFonts.ibmPlexMono(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
