import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/constants.dart';
import '../models/app_user.dart';
import '../models/besuch.dart';
import 'image_service.dart';

class BesuchService {
  static final _supabase = Supabase.instance.client;

  /// Erstellt einen neuen Besuch.
  static Future<Besuch> create({
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
        .insert(data)
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

  /// Lädt einen einzelnen Besuch per visit_id
  static Future<Besuch> getById(String visitId) async {
    final response = await _supabase
        .from(AppConstants.tableVisit)
        .select('*, pommesbude(*), user(*)')
        .eq('visit_id', int.parse(visitId))
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

  // ── Tagging ──────────────────────────────────────────────────

  /// Tags andere User bei einem Besuch.
  static Future<void> tagUsers({
    required String visitId,
    required List<String> taggedUserIds,
  }) async {
    if (taggedUserIds.isEmpty) return;
    final rows = taggedUserIds
        .map((uid) => {
              'visit_id': int.parse(visitId),
              'tagged_user_id': uid,
            })
        .toList();
    await _supabase.from(AppConstants.tableVisitTags).insert(rows);
  }

  /// Gibt alle getaggten User eines Besuchs zurück.
  static Future<List<AppUser>> getTaggedUsers(String visitId) async {
    final response = await _supabase
        .from(AppConstants.tableVisitTags)
        .select('tagged_user_id, user:tagged_user_id(*)')
        .eq('visit_id', int.parse(visitId));
    return (response as List)
        .where((row) => row['user'] != null)
        .map((row) => AppUser.fromJson(row['user']))
        .toList();
  }

  /// Gibt Besuche zurück, bei denen der User getaggt wurde.
  static Future<List<Besuch>> getTaggedVisits(String userId) async {
    final response = await _supabase
        .from(AppConstants.tableVisitTags)
        .select('visit_id, visit:visit_id(*, user(*), pommesbude(*))')
        .eq('tagged_user_id', userId);
    final visits = <Besuch>[];
    for (final row in (response as List)) {
      if (row['visit'] != null) {
        visits.add(Besuch.fromJson(row['visit']));
      }
    }
    return visits;
  }

  /// Alle User laden (für die Tag-Auswahl).
  static Future<List<AppUser>> getAllUsers() async {
    final response = await _supabase
        .from(AppConstants.tableUser)
        .select()
        .order('username');
    return (response as List).map((json) => AppUser.fromJson(json)).toList();
  }
}
