class SpeciesData {
  final String? swedishName;
  final String? scientificName;
  final List<RedlistInfo> redlistInfo;

  SpeciesData({
    this.swedishName,
    this.scientificName,
    required this.redlistInfo,
  });

  factory SpeciesData.fromJson(Map<String, dynamic> json) {
    return SpeciesData(
      swedishName: json['swedishName'],
      scientificName: json['scientificName'],
      redlistInfo: (json['redlistInfo'] as List<dynamic>?)
          ?.map((item) => RedlistInfo.fromJson(item))
          .toList() ?? [],
    );
  }
}

class RedlistInfo {
  final String category;
  final String? criterionText;
  final Period period;

  RedlistInfo({
    required this.category,
    this.criterionText,
    required this.period,
  });

  factory RedlistInfo.fromJson(Map<String, dynamic> json) {
    return RedlistInfo(
      category: json['category'] ?? '',
      criterionText: json['criterionText'],
      period: Period.fromJson(json['period']),
    );
  }
}

class Period {
  final String id;
  final String name;
  final String description;
  final bool current;

  Period({
    required this.id,
    required this.name,
    required this.description,
    required this.current,
  });

  factory Period.fromJson(Map<String, dynamic> json) {
    return Period(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      current: json['current'] ?? false,
    );
  }
}
