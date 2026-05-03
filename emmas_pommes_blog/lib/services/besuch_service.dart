import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/constants.dart';
import '../models/besuch.dart';
import 'image_service.dart';

class BesuchService {
  static final _supabase = Supabase.instance.client;

  /// Erstellt oder aktualisiert einen Besuch.
  /// Composite PK: id (= userId) + location (= budeId).
  static Future<Besuch> createOrUpdate({
    required String userId,
    required String location,
    double? price,
    String? linkToPicture,
    String? review,
    int? countVisitors,
    double? overallRating,
    double? serviceRating,
    double? waitingTimeRating,
    double? ambientRating,
  }) async {
    final data = {
      'id': userId,
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

    final response = await _supabase
        .from(AppConstants.tableVisit)
        .upsert(data)
        .select('*, user(*), pommesbude(*)')
        .single();
    return Besuch.fromJson(response);
  }

  static Future<List<Besuch>> getByUser(String userId) async {
    final response = await _supabase
        .from(AppConstants.tableVisit)
        .select('*, pommesbude(*), user(*)')
        .eq('id', userId)
        .order('created_at', ascending: false);
    return (response as List).map((json) => Besuch.fromJson(json)).toList();
  }

  static Future<List<Besuch>> getAll() async {
    final response = await _supabase
        .from(AppConstants.tableVisit)
        .select('*, pommesbude(*), user(*)')
        .order('created_at', ascending: false);
    return (response as List).map((json) => Besuch.fromJson(json)).toList();
  }

  /// Lädt einen einzelnen Besuch per composite key (userId + location)
  static Future<Besuch> getByKey(String userId, String location) async {
    final response = await _supabase
        .from(AppConstants.tableVisit)
        .select('*, pommesbude(*), user(*)')
        .eq('id', userId)
        .eq('location', int.parse(location))
        .single();
    return Besuch.fromJson(response);
  }

  /// Lädt mehrere Essensbilder für einen Besuch hoch.
  /// Gibt die Liste der Storage-Pfade zurück.
  static Future<List<String>> uploadImages({
    required String userId,
    required String location,
    required List<({String name, Uint8List bytes})> files,
  }) async {
    final paths = <String>[];
    for (final file in files) {
      final path = await ImageService.uploadEssenImage(
          userId, location, file.name, file.bytes);
      paths.add(path);
    }
    return paths;
  }

  /// Gibt signed URLs aller Bilder eines Besuchs zurück.
  static Future<List<String>> getVisitImages(
      String userId, String location) async {
    return ImageService.getEssenImages(userId, location);
  }

  /// Returns a map of userId -> visitCount, sorted descending
  static Future<List<Map<String, dynamic>>> getUserRanking(
      {int limit = 50}) async {
    final response = await _supabase
        .from(AppConstants.tableVisit)
        .select('id, user(*)');

    final visitsByUser = <String, Map<String, dynamic>>{};
    for (final row in (response as List)) {
      final uid = row['id'].toString();
      if (!visitsByUser.containsKey(uid)) {
        visitsByUser[uid] = {
          'user': row['user'],
          'count': 0,
        };
      }
      visitsByUser[uid]!['count'] = (visitsByUser[uid]!['count'] as int) + 1;
    }

    final ranking = visitsByUser.values.toList()
      ..sort(
          (a, b) => (b['count'] as int).compareTo(a['count'] as int));
    return ranking.take(limit).toList();
  }
}
