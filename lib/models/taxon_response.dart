class TaxonResponse {
  final List<int> taxonIds;
  final List<TaxonInfo> taxonInfos;

  TaxonResponse({required this.taxonIds, required this.taxonInfos});

  factory TaxonResponse.fromJson(Map<String, dynamic> json) {
    return TaxonResponse(
      taxonIds: List<int>.from(json['taxonIds'] ?? []),
      taxonInfos: (json['taxonInfos'] as List<dynamic>?)
          ?.map((item) => TaxonInfo.fromJson(item))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'taxonIds': taxonIds,
      'taxonInfos': taxonInfos.map((info) => info.toJson()).toList(),
    };
  }
}

class TaxonInfo {
  final int taxonId;
  final int? parentId;
  final String swedishName;
  final String scientificName;
  final TaxonCategory category;

  TaxonInfo({
    required this.taxonId,
    this.parentId,
    required this.swedishName,
    required this.scientificName,
    required this.category,
  });

  factory TaxonInfo.fromJson(Map<String, dynamic> json) {
    return TaxonInfo(
      taxonId: json['taxonId'] ?? 0,
      parentId: json['parentId'],
      swedishName: json['swedishName'] ?? '',
      scientificName: json['scientificName'] ?? '',
      category: TaxonCategory.fromJson(json['category'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'taxonId': taxonId,
      'parentId': parentId,
      'swedishName': swedishName,
      'scientificName': scientificName,
      'category': category.toJson(),
    };
  }
}

class TaxonCategory {
  final int id;
  final String name;

  TaxonCategory({required this.id, required this.name});

  factory TaxonCategory.fromJson(Map<String, dynamic> json) {
    return TaxonCategory(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}
