import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/constants.dart';
import '../models/besuch.dart';

class BesuchService {
  static final _supabase = Supabase.instance.client;

  static Future<Besuch> create({
    required String location,
    required String userId,
    double? price,
    String? linkToPicture,
    String? review,
    int? countVisitors,
    double? overallRating,
    double? serviceRating,
    double? waitingTimeRating,
    double? ambientRating,
  }) async {
    final response = await _supabase
        .from(AppConstants.tableBesuch)
        .insert({
          'location': location,
          'user_id': userId,
          'price': price,
          'link_to_picture': linkToPicture,
          'review': review,
          'count_visitors': countVisitors,
          'overall_rating': overallRating,
          'service_rating': serviceRating,
          'waiting_time_rating': waitingTimeRating,
          'ambient_rating': ambientRating,
        })
        .select('*, user(*), Pommesbude(*)')
        .single();
    return Besuch.fromJson(response);
  }

  static Future<List<Besuch>> getByUser(String userId) async {
    final response = await _supabase
        .from(AppConstants.tableBesuch)
        .select('*, Pommesbude(*), user(*)')
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return (response as List).map((json) => Besuch.fromJson(json)).toList();
  }

  static Future<List<Besuch>> getAll() async {
    final response = await _supabase
        .from(AppConstants.tableBesuch)
        .select('*, Pommesbude(*), user(*)')
        .order('created_at', ascending: false);
    return (response as List).map((json) => Besuch.fromJson(json)).toList();
  }

  static Future<Besuch> getById(String id) async {
    final response = await _supabase
        .from(AppConstants.tableBesuch)
        .select('*, Pommesbude(*), user(*)')
        .eq('id', id)
        .single();
    return Besuch.fromJson(response);
  }

  static Future<String?> uploadImage(
      String fileName, Uint8List fileBytes) async {
    try {
      final path = 'besuche/$fileName';
      await _supabase.storage
          .from(AppConstants.storageBucket)
          .uploadBinary(path, fileBytes);
      return _supabase.storage
          .from(AppConstants.storageBucket)
          .getPublicUrl(path);
    } catch (_) {
      return null;
    }
  }

  // --- Reactions ---

  static Future<List<Reaktion>> getReactions(String besuchId) async {
    final response = await _supabase
        .from(AppConstants.tableReaktion)
        .select('*, user(*)')
        .eq('besuch_id', besuchId)
        .order('created_at');
    return (response as List).map((json) => Reaktion.fromJson(json)).toList();
  }

  static Future<void> addReaction({
    required String besuchId,
    required String userId,
    required String emoji,
  }) async {
    // Remove existing reaction by this user first
    await _supabase
        .from(AppConstants.tableReaktion)
        .delete()
        .eq('besuch_id', besuchId)
        .eq('user_id', userId);

    await _supabase.from(AppConstants.tableReaktion).insert({
      'besuch_id': besuchId,
      'user_id': userId,
      'emoji': emoji,
    });
  }

  // --- Comments ---

  static Future<List<Kommentar>> getComments(String besuchId) async {
    final response = await _supabase
        .from(AppConstants.tableKommentar)
        .select('*, user(*)')
        .eq('besuch_id', besuchId)
        .order('created_at');
    return (response as List).map((json) => Kommentar.fromJson(json)).toList();
  }

  static Future<Kommentar> addComment({
    required String besuchId,
    required String userId,
    required String text,
  }) async {
    final response = await _supabase
        .from(AppConstants.tableKommentar)
        .insert({
          'besuch_id': besuchId,
          'user_id': userId,
          'text': text,
        })
        .select('*, user(*)')
        .single();
    return Kommentar.fromJson(response);
  }

  /// Returns a map of userId -> visitCount, sorted descending
  static Future<List<Map<String, dynamic>>> getUserRanking(
      {int limit = 50}) async {
    final response = await _supabase
        .from(AppConstants.tableBesuch)
        .select('user_id, user(*)');

    final visitsByUser = <String, Map<String, dynamic>>{};
    for (final row in (response as List)) {
      final uid = row['user_id'].toString();
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
