import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/constants.dart';
import '../models/pommesbude.dart';
import '../models/besuch.dart';
import 'image_service.dart';

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
          .from(AppConstants.tableVisit)
          .select('overall_rating')
          .eq('location', int.parse(bude.id));
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
        .eq('id', int.parse(id))
        .single();
    return Pommesbude.fromJson(response);
  }

  static Future<Pommesbude> create({
    required double lat,
    required double lon,
    required String name,
    String? budenImage,
  }) async {
    final response = await _supabase
        .from(AppConstants.tablePommesbude)
        .insert({
          'lat': lat,
          'lon': lon,
          'name': name,
          'buden_image': budenImage,
        })
        .select()
        .single();
    return Pommesbude.fromJson(response);
  }

  static Future<List<Besuch>> getVisitsForBude(String budeId) async {
    final response = await _supabase
        .from(AppConstants.tableVisit)
        .select('*, user(*)')
        .eq('location', int.parse(budeId))
        .order('created_at', ascending: false);
    return (response as List).map((json) => Besuch.fromJson(json)).toList();
  }

  static Future<String> uploadImage(
      String userId, String budeId, String fileName, Uint8List fileBytes) async {
    return ImageService.uploadBudeImage(userId, budeId, fileName, fileBytes);
  }

  /// Aktualisiert das Bild einer Pommesbude.
  static Future<void> updateImage(String budeId, String imageUrl) async {
    await _supabase
        .from(AppConstants.tablePommesbude)
        .update({'buden_image': imageUrl})
        .eq('id', int.parse(budeId));
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
