import 'app_user.dart';
import 'pommesbude.dart';

/// Ein Besuch (visit-Tabelle).
/// Composite PK: id (= user uuid) + location (= pommesbude id).
class Besuch {
  final String id; // = user UUID
  final DateTime createdAt;
  final String location; // = pommesbude ID (int8)
  final double? price;
  final String? linkToPicture;
  final String? review;
  final int? countVisitors;
  final double? overallRating;
  final double? serviceRating;
  final double? waitingTimeRating;
  final double? ambientRating;

  /// Convenience: userId == id (da visit.id die user-UUID ist)
  String get userId => id;

  // Joined data
  final Pommesbude? pommesbude;
  final AppUser? user;

  Besuch({
    required this.id,
    required this.createdAt,
    required this.location,
    this.price,
    this.linkToPicture,
    this.review,
    this.countVisitors,
    this.overallRating,
    this.serviceRating,
    this.waitingTimeRating,
    this.ambientRating,
    this.pommesbude,
    this.user,
  });

  factory Besuch.fromJson(Map<String, dynamic> json) {
    return Besuch(
      id: json['id'].toString(),
      createdAt: DateTime.parse(json['created_at']),
      location: json['location'].toString(),
      price: json['price'] != null ? (json['price'] as num).toDouble() : null,
      linkToPicture: json['link_to_picture'],
      review: json['review'],
      countVisitors: json['count_visitors'],
      overallRating: json['overall_rating'] != null
          ? (json['overall_rating'] as num).toDouble()
          : null,
      serviceRating: json['service_rating'] != null
          ? (json['service_rating'] as num).toDouble()
          : null,
      // DB-Spalte heißt wating_time_rating (Typo)
      waitingTimeRating: json['wating_time_rating'] != null
          ? (json['wating_time_rating'] as num).toDouble()
          : null,
      ambientRating: json['ambient_rating'] != null
          ? (json['ambient_rating'] as num).toDouble()
          : null,
      pommesbude: json['pommesbude'] != null
          ? Pommesbude.fromJson(json['pommesbude'])
          : null,
      user: json['user'] != null ? AppUser.fromJson(json['user']) : null,
    );
  }

  Map<String, dynamic> toInsertJson() => {
        'id': id, // user UUID
        'location': int.parse(location),
        'price': price,
        'link_to_picture': linkToPicture,
        'review': review,
        'count_visitors': countVisitors,
        'overall_rating': overallRating?.round(),
        'service_rating': serviceRating?.round(),
        'wating_time_rating': waitingTimeRating?.round(),
        'ambient_rating': ambientRating?.round(),
      };
}
