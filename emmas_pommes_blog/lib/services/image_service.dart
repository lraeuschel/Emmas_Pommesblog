import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/constants.dart';

/// Zentraler Service für Bild-Upload und -Abruf über Supabase Storage.
class ImageService {
  static final _supabase = Supabase.instance.client;

  // ── Pommesbuden-Bilder (public bucket) ──────────────────────────

  /// Lädt ein Bild für eine Pommesbude hoch und gibt die public URL zurück.
  /// Pfad: {userId}/{budeId}/{timestamp}_{filename}
  static Future<String> uploadBudeImage(
      String userId, String budeId, String fileName, Uint8List bytes) async {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final path = '$userId/$budeId/${ts}_$fileName';
    await _supabase.storage
        .from(AppConstants.bucketPommesbude)
        .uploadBinary(path, bytes);
    return _supabase.storage
        .from(AppConstants.bucketPommesbude)
        .getPublicUrl(path);
  }

  /// Listet alle Bilder einer Pommesbude (public URLs).
  /// Iteriert über alle User-Ordner um alle Bilder zu finden.
  static Future<List<String>> getBudeImages(String budeId) async {
    try {
      final userDirs = await _supabase.storage
          .from(AppConstants.bucketPommesbude)
          .list();
      final allUrls = <String>[];
      for (final dir in userDirs) {
        if (dir.name == '.emptyFolderPlaceholder') continue;
        try {
          final files = await _supabase.storage
              .from(AppConstants.bucketPommesbude)
              .list(path: '${dir.name}/$budeId');
          for (final f in files) {
            if (f.name != '.emptyFolderPlaceholder') {
              allUrls.add(_supabase.storage
                  .from(AppConstants.bucketPommesbude)
                  .getPublicUrl('${dir.name}/$budeId/${f.name}'));
            }
          }
        } catch (_) {}
      }
      return allUrls;
    } catch (_) {
      return [];
    }
  }

  // ── Besuchs-/Essensbilder (private bucket) ─────────────────────

  /// Lädt ein Bild für einen Besuch hoch.
  /// Pfad: {userId}/{location}/{timestamp}_{filename}
  static Future<String> uploadEssenImage(
      String userId, String location, String fileName, Uint8List bytes) async {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final path = '$userId/$location/${ts}_$fileName';
    await _supabase.storage
        .from(AppConstants.bucketEssen)
        .uploadBinary(path, bytes);
    return path;
  }

  /// Gibt signed URLs für alle Bilder eines Besuchs zurück.
  static Future<List<String>> getEssenImages(
      String userId, String location) async {
    try {
      final files = await _supabase.storage
          .from(AppConstants.bucketEssen)
          .list(path: '$userId/$location');
      if (files.isEmpty) return [];
      final paths = files
          .where((f) => f.name != '.emptyFolderPlaceholder')
          .map((f) => '$userId/$location/${f.name}')
          .toList();
      if (paths.isEmpty) return [];
      final signed = await _supabase.storage
          .from(AppConstants.bucketEssen)
          .createSignedUrls(paths, 3600);
      return signed.map((s) => s.signedUrl).toList();
    } catch (_) {
      return [];
    }
  }

  /// Gibt signed URLs für alle Essensbilder einer Pommesbude zurück
  /// (über alle User/Besuche hinweg).
  static Future<List<String>> getAllEssenImagesForBude(
      String budeId) async {
    try {
      final userDirs = await _supabase.storage
          .from(AppConstants.bucketEssen)
          .list();
      final allPaths = <String>[];
      for (final dir in userDirs) {
        if (dir.name == '.emptyFolderPlaceholder') continue;
        try {
          final files = await _supabase.storage
              .from(AppConstants.bucketEssen)
              .list(path: '${dir.name}/$budeId');
          for (final f in files) {
            if (f.name != '.emptyFolderPlaceholder') {
              allPaths.add('${dir.name}/$budeId/${f.name}');
            }
          }
        } catch (_) {}
      }
      if (allPaths.isEmpty) return [];
      final signed = await _supabase.storage
          .from(AppConstants.bucketEssen)
          .createSignedUrls(allPaths, 3600);
      return signed.map((s) => s.signedUrl).toList();
    } catch (_) {
      return [];
    }
  }

  // ── Profilbilder (private bucket) ──────────────────────────────

  /// Lädt ein Profilbild hoch. Überschreibt ein bestehendes Profilbild.
  static Future<String> uploadProfileImage(
      String userId, String fileName, Uint8List bytes) async {
    final path = '$userId/avatar_$fileName';
    // Alte Bilder löschen (Fehler ignorieren)
    try {
      final existing = await _supabase.storage
          .from(AppConstants.bucketProfile)
          .list(path: userId);
      if (existing.isNotEmpty) {
        final toDelete = existing
            .where((f) => f.name != '.emptyFolderPlaceholder')
            .map((f) => '$userId/${f.name}')
            .toList();
        if (toDelete.isNotEmpty) {
          await _supabase.storage
              .from(AppConstants.bucketProfile)
              .remove(toDelete);
        }
      }
    } catch (_) {}
    // Upload (Fehler NICHT schlucken)
    await _supabase.storage
        .from(AppConstants.bucketProfile)
        .uploadBinary(path, bytes);
    return path;
  }

  /// Erzeugt eine signed URL für ein Profilbild-Pfad.
  static Future<String?> getProfileImageUrl(String storagePath) async {
    try {
      final signed = await _supabase.storage
          .from(AppConstants.bucketProfile)
          .createSignedUrl(storagePath, 3600);
      return signed;
    } catch (_) {
      return null;
    }
  }

  /// Erzeugt signed URLs für mehrere Profilbild-Pfade auf einmal.
  static Future<Map<String, String>> getProfileImageUrls(
      List<String> storagePaths) async {
    if (storagePaths.isEmpty) return {};
    try {
      final unique = storagePaths.toSet().toList();
      final signed = await _supabase.storage
          .from(AppConstants.bucketProfile)
          .createSignedUrls(unique, 3600);
      final map = <String, String>{};
      for (final s in signed) {
        map[s.path] = s.signedUrl;
      }
      return map;
    } catch (_) {
      return {};
    }
  }
}
