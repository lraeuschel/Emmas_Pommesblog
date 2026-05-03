class Pommesbude {
  final String id;
  final DateTime createdAt;
  final double lon;
  final double lat;
  final String name;
  final String? budenImage;

  // Computed fields (from joins)
  final double? averageRating;
  final int visitCount;

  Pommesbude({
    required this.id,
    required this.createdAt,
    required this.lon,
    required this.lat,
    required this.name,
    this.budenImage,
    this.averageRating,
    this.visitCount = 0,
  });

  factory Pommesbude.fromJson(Map<String, dynamic> json) {
    return Pommesbude(
      id: json['id'].toString(),
      createdAt: DateTime.parse(json['created_at']),
      lon: (json['lon'] as num?)?.toDouble() ?? 0,
      lat: (json['lat'] as num?)?.toDouble() ?? 0,
      name: json['name'] ?? '',
      budenImage: json['buden_image'],
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
      budenImage: budenImage,
      averageRating: averageRating ?? this.averageRating,
      visitCount: visitCount ?? this.visitCount,
    );
  }

  Map<String, dynamic> toInsertJson() => {
        'lon': lon,
        'lat': lat,
        'name': name,
        'buden_image': budenImage,
      };
}
