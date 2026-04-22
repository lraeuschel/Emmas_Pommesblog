class Pommesbude {
  final String id;
  final DateTime createdAt;
  final double lon;
  final double lat;
  final String name;
  final String? linkToPhoto;

  // Computed fields (from joins)
  final double? averageRating;
  final int visitCount;

  Pommesbude({
    required this.id,
    required this.createdAt,
    required this.lon,
    required this.lat,
    required this.name,
    this.linkToPhoto,
    this.averageRating,
    this.visitCount = 0,
  });

  factory Pommesbude.fromJson(Map<String, dynamic> json) {
    return Pommesbude(
      id: json['id'].toString(),
      createdAt: DateTime.parse(json['created_at']),
      lon: (json['lon'] as num).toDouble(),
      lat: (json['lat'] as num).toDouble(),
      name: json['name'] ?? '',
      linkToPhoto: json['link_to_photo'],
    );
  }

  Pommesbude copyWith({
    double? averageRating,
    int? visitCount,
  }) {
    return Pommesbude(
      id: id,
      createdAt: createdAt,
      lon: lon,
      lat: lat,
      name: name,
      linkToPhoto: linkToPhoto,
      averageRating: averageRating ?? this.averageRating,
      visitCount: visitCount ?? this.visitCount,
    );
  }

  Map<String, dynamic> toInsertJson() => {
        'lon': lon,
        'lat': lat,
        'name': name,
        'link_to_photo': linkToPhoto,
      };
}
