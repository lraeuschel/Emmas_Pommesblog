import 'app_user.dart';
import 'pommesbude.dart';

class Besuch {
  final String id;
  final DateTime createdAt;
  final String location; // Pommesbude ID
  final double? price;
  final String? linkToPicture;
  final String? review;
  final int? countVisitors;
  final double? overallRating;
  final double? serviceRating;
  final double? waitingTimeRating;
  final double? ambientRating;
  final String userId;

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
    required this.userId,
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
      waitingTimeRating: json['waiting_time_rating'] != null
          ? (json['waiting_time_rating'] as num).toDouble()
          : null,
      ambientRating: json['ambient_rating'] != null
          ? (json['ambient_rating'] as num).toDouble()
          : null,
      userId: json['user_id'].toString(),
      pommesbude: json['Pommesbude'] != null
          ? Pommesbude.fromJson(json['Pommesbude'])
          : null,
      user: json['user'] != null ? AppUser.fromJson(json['user']) : null,
    );
  }

  Map<String, dynamic> toInsertJson() => {
        'location': location,
        'price': price,
        'link_to_picture': linkToPicture,
        'review': review,
        'count_visitors': countVisitors,
        'overall_rating': overallRating,
        'service_rating': serviceRating,
        'waiting_time_rating': waitingTimeRating,
        'ambient_rating': ambientRating,
        'user_id': userId,
      };
}

class Reaktion {
  final String id;
  final DateTime createdAt;
  final String besuchId;
  final String userId;
  final String emoji;
  final AppUser? user;

  Reaktion({
    required this.id,
    required this.createdAt,
    required this.besuchId,
    required this.userId,
    required this.emoji,
    this.user,
  });

  factory Reaktion.fromJson(Map<String, dynamic> json) {
    return Reaktion(
      id: json['id'].toString(),
      createdAt: DateTime.parse(json['created_at']),
      besuchId: json['besuch_id'].toString(),
      userId: json['user_id'].toString(),
      emoji: json['emoji'] ?? '',
      user: json['user'] != null ? AppUser.fromJson(json['user']) : null,
    );
  }
}

class Kommentar {
  final String id;
  final DateTime createdAt;
  final String besuchId;
  final String userId;
  final String text;
  final AppUser? user;

  Kommentar({
    required this.id,
    required this.createdAt,
    required this.besuchId,
    required this.userId,
    required this.text,
    this.user,
  });

  factory Kommentar.fromJson(Map<String, dynamic> json) {
    return Kommentar(
      id: json['id'].toString(),
      createdAt: DateTime.parse(json['created_at']),
      besuchId: json['besuch_id'].toString(),
      userId: json['user_id'].toString(),
      text: json['text'] ?? '',
      user: json['user'] != null ? AppUser.fromJson(json['user']) : null,
    );
  }
}
