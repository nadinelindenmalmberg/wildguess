class TaxonResponse {
  final List<int> taxonIds;

  TaxonResponse({required this.taxonIds});

  factory TaxonResponse.fromJson(Map<String, dynamic> json) {
    return TaxonResponse(
      taxonIds: List<int>.from(json['taxonIds'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'taxonIds': taxonIds,
    };
  }
}
