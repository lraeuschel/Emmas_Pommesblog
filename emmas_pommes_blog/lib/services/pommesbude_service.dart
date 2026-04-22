import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/constants.dart';
import '../models/pommesbude.dart';
import '../models/besuch.dart';

class PommesbudeService {
  static final _supabase = Supabase.instance.client;

  static Future<List<Pommesbude>> getAll() async {
    final response = await _supabase
        .from(AppConstants.tablePommesbude)
        .select()
        .order('created_at', ascending: false);

    final buden = (response as List)
        .map((json) => Pommesbude.fromJson(json))
        .toList();

    // Fetch visit stats for each bude
    final enriched = <Pommesbude>[];
    for (final bude in buden) {
      final visits = await _supabase
          .from(AppConstants.tableBesuch)
          .select('overall_rating')
          .eq('location', bude.id);
      final visitList = visits as List;
      final count = visitList.length;
      double? avg;
      if (count > 0) {
        final ratings = visitList
            .where((v) => v['overall_rating'] != null)
            .map((v) => (v['overall_rating'] as num).toDouble())
            .toList();
        if (ratings.isNotEmpty) {
          avg = ratings.reduce((a, b) => a + b) / ratings.length;
        }
      }
      enriched.add(bude.copyWith(averageRating: avg, visitCount: count));
    }
    return enriched;
  }

  static Future<Pommesbude> getById(String id) async {
    final response = await _supabase
        .from(AppConstants.tablePommesbude)
        .select()
        .eq('id', id)
        .single();
    return Pommesbude.fromJson(response);
  }

  static Future<Pommesbude> create({
    required double lat,
    required double lon,
    required String name,
    String? linkToPhoto,
  }) async {
    final response = await _supabase
        .from(AppConstants.tablePommesbude)
        .insert({
          'lat': lat,
          'lon': lon,
          'name': name,
          'link_to_photo': linkToPhoto,
        })
        .select()
        .single();
    return Pommesbude.fromJson(response);
  }

  static Future<List<Besuch>> getVisitsForBude(String budeId) async {
    final response = await _supabase
        .from(AppConstants.tableBesuch)
        .select('*, user(*)')
        .eq('location', budeId)
        .order('created_at', ascending: false);
    return (response as List).map((json) => Besuch.fromJson(json)).toList();
  }

  static Future<String?> uploadImage(
      String fileName, Uint8List fileBytes) async {
    try {
      final path = 'pommesbuden/$fileName';
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

  /// Returns top-rated Pommesbuden sorted by average overall_rating
  static Future<List<Pommesbude>> getTopRated({int limit = 50}) async {
    final all = await getAll();
    all.sort((a, b) {
      final ra = a.averageRating ?? 0;
      final rb = b.averageRating ?? 0;
      return rb.compareTo(ra);
    });
    return all.take(limit).toList();
  }
}
