import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/constants.dart';
import '../models/app_user.dart';
import '../models/besuch.dart';
import 'image_service.dart';

class BesuchService {
  static final _supabase = Supabase.instance.client;

  /// Erstellt einen neuen Besuch und optional Gruppen-Kopien.
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
    List<String> taggedUserIds = const [],
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
    final originalVisit = Besuch.fromJson(response);

    final uniqueTaggedUserIds = taggedUserIds
        .where((id) => id != userId)
        .toSet()
        .toList();
    if (uniqueTaggedUserIds.isEmpty) {
      return originalVisit;
    }

    final participantIds = <String>{userId, ...uniqueTaggedUserIds}.toList();
    final mirroredVisitRows = await _insertMirroredVisitRows(
      sourceData: data,
      taggedUserIds: uniqueTaggedUserIds,
    );
    final mirroredVisitIds = mirroredVisitRows
        .map((row) => row['visit_id'].toString())
        .toList();

    await _insertVisitTagRows(
      visitIds: [originalVisit.visitId, ...mirroredVisitIds],
      participantIds: participantIds,
    );

    return originalVisit;
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

  /// Lädt einen einzelnen Besuch per visit_id.
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
        userId,
        location,
        file.name,
        file.bytes,
      );
      paths.add(path);
    }
    return paths;
  }

  /// Gibt signed URLs aller Bilder eines Besuchs zurück.
  static Future<List<String>> getVisitImages(
    String userId,
    String location,
  ) async {
    return ImageService.getEssenImages(userId, location);
  }

  /// Returns a map of userId -> visitCount, sorted descending.
  static Future<List<Map<String, dynamic>>> getUserRanking({
    int limit = 50,
  }) async {
    final response = await _supabase
        .from(AppConstants.tableVisit)
        .select('id, user(*)');

    final visitsByUser = <String, Map<String, dynamic>>{};
    for (final row in (response as List)) {
      final userId = row['id'].toString();
      if (!visitsByUser.containsKey(userId)) {
        visitsByUser[userId] = {
          'user': row['user'],
          'count': 0,
        };
      }
      visitsByUser[userId]!['count'] = (visitsByUser[userId]!['count'] as int) + 1;
    }

    final ranking = visitsByUser.values.toList()
      ..sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));
    return ranking.take(limit).toList();
  }

  // ── Tagging ──────────────────────────────────────────────────

  static Future<void> _insertVisitTagRows({
    required List<String> visitIds,
    required List<String> participantIds,
  }) async {
    if (visitIds.isEmpty || participantIds.isEmpty) return;
    final rows = visitIds
        .map(
          (visitId) => {
            'visit_id': int.parse(visitId),
            'tagged_user_ids': participantIds,
          },
        )
        .toList();
    await _supabase.from(AppConstants.tableVisitTags).insert(rows);
  }

  static Future<List<Map<String, dynamic>>> _insertMirroredVisitRows({
    required Map<String, dynamic> sourceData,
    required List<String> taggedUserIds,
  }) async {
    final rows = taggedUserIds
        .map(
          (userId) => {
            ...sourceData,
            'id': userId,
          },
        )
        .toList();

    final response = await _supabase
        .from(AppConstants.tableVisit)
        .insert(rows)
        .select('visit_id, id');

    return (response as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
  }

  /// Tags andere User bei einem Besuch.
  static Future<void> tagUsers({
    required String visitId,
    required List<String> taggedUserIds,
  }) async {
    final uniqueTaggedUserIds = taggedUserIds.toSet().toList();
    if (uniqueTaggedUserIds.isEmpty) return;

    final visit = await _supabase
        .from(AppConstants.tableVisit)
        .select('id')
        .eq('visit_id', int.parse(visitId))
        .single();
    final creatorUserId = visit['id'].toString();

    await _insertVisitTagRows(
      visitIds: [visitId],
      participantIds: <String>{creatorUserId, ...uniqueTaggedUserIds}.toList(),
    );
  }

  /// Gibt alle getaggten User eines Besuchs zurück.
  static Future<List<AppUser>> getTaggedUsers(String visitId) async {
    final visitResponse = await _supabase
        .from(AppConstants.tableVisit)
        .select('id')
        .eq('visit_id', int.parse(visitId))
        .single();
    final visitOwnerId = visitResponse['id'].toString();

    final tagRows = await _supabase
        .from(AppConstants.tableVisitTags)
        .select('tagged_user_ids')
        .eq('visit_id', int.parse(visitId));

    if ((tagRows as List).isEmpty) return [];

    final tagRow = tagRows.first as Map<String, dynamic>;
    final taggedUserIds = (tagRow['tagged_user_ids'] as List?)
            ?.map((value) => value.toString())
            .where((id) => id != visitOwnerId)
            .toList() ??
        [];

    if (taggedUserIds.isEmpty) return [];

    final users = await _supabase
        .from(AppConstants.tableUser)
        .select()
        .inFilter('id', taggedUserIds);
    return (users as List).map((json) => AppUser.fromJson(json)).toList();
  }

  /// Gibt Besuche zurück, bei denen der User getaggt wurde.
  static Future<List<Besuch>> getTaggedVisits(String userId) async {
    final tagRows = await _supabase
        .from(AppConstants.tableVisitTags)
        .select('visit_id, tagged_user_ids')
        .contains('tagged_user_ids', [userId]);

    if (tagRows.isEmpty) return [];

    final visitIds = (tagRows as List)
        .map((row) => (row as Map<String, dynamic>)['visit_id'].toString())
        .toSet()
        .toList();

    final response = await _supabase
        .from(AppConstants.tableVisit)
        .select('*, pommesbude(*), user(*)')
        .inFilter('visit_id', visitIds.map(int.parse).toList())
        .order('created_at', ascending: false);
    return (response as List).map((json) => Besuch.fromJson(json)).toList();
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
