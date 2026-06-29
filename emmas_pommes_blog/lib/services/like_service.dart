import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/constants.dart';

class LikeService {
  static final _supabase = Supabase.instance.client;

  /// Toggled einen Like für einen Besuch.
  /// Gibt true zurück wenn geliked, false wenn unliked.
  static Future<bool> toggleLike(String visitId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Nicht eingeloggt');

    final existing = await _supabase
        .from(AppConstants.tableVisitLikes)
        .select()
        .eq('visit_id', int.parse(visitId))
        .eq('user_id', userId)
        .maybeSingle();

    if (existing != null) {
      await _supabase
          .from(AppConstants.tableVisitLikes)
          .delete()
          .eq('visit_id', int.parse(visitId))
          .eq('user_id', userId);
      return false;
    } else {
      await _supabase.from(AppConstants.tableVisitLikes).insert({
        'visit_id': int.parse(visitId),
        'user_id': userId,
      });
      return true;
    }
  }

  /// Gibt die Anzahl der Likes für einen Besuch zurück.
  static Future<int> getLikeCount(String visitId) async {
    final response = await _supabase
        .from(AppConstants.tableVisitLikes)
        .select()
        .eq('visit_id', int.parse(visitId));
    return (response as List).length;
  }

  /// Prüft ob der aktuelle User einen Besuch geliked hat.
  static Future<bool> hasLiked(String visitId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return false;

    final existing = await _supabase
        .from(AppConstants.tableVisitLikes)
        .select()
        .eq('visit_id', int.parse(visitId))
        .eq('user_id', userId)
        .maybeSingle();
    return existing != null;
  }

  /// Gibt Like-Daten für mehrere Visits auf einmal zurück.
  /// Returns Map<visitId, {count, liked}>
  static Future<Map<String, ({int count, bool liked})>> getBulkLikeData(
      List<String> visitIds) async {
    if (visitIds.isEmpty) return {};
    final userId = _supabase.auth.currentUser?.id;

    final intIds = visitIds.map((id) => int.parse(id)).toList();
    final response = await _supabase
        .from(AppConstants.tableVisitLikes)
        .select()
        .inFilter('visit_id', intIds);

    final result = <String, ({int count, bool liked})>{};
    final countMap = <String, int>{};
    final likedSet = <String>{};

    for (final row in (response as List)) {
      final vid = row['visit_id'].toString();
      countMap[vid] = (countMap[vid] ?? 0) + 1;
      if (row['user_id'] == userId) likedSet.add(vid);
    }

    for (final id in visitIds) {
      result[id] = (count: countMap[id] ?? 0, liked: likedSet.contains(id));
    }
    return result;
  }
}
