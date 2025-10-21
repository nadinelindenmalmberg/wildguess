class AnimalData {
  final String name;
  final String scientificName;
  final String description;
  final List<String> hints;
  final String imageUrl;

  AnimalData({
    required this.name,
    required this.scientificName,
    required this.description,
    required this.hints,
    required this.imageUrl,
  });

  factory AnimalData.fromJson(Map<String, dynamic> json) {
    return AnimalData(
      name: json['name'] ?? '',
      scientificName: json['scientificName'] ?? '',
      description: json['description'] ?? '',
      hints: List<String>.from(json['hints'] ?? []),
      imageUrl: json['imageUrl'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'scientificName': scientificName,
      'description': description,
      'hints': hints,
      'imageUrl': imageUrl,
    };
  }

  @override
  String toString() {
    return 'AnimalData(name: $name, scientificName: $scientificName, description: $description, hints: $hints, imageUrl: $imageUrl)';
  }
}
