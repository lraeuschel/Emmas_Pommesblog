import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/constants.dart';
import '../models/app_user.dart';
import 'image_service.dart';

/// Auth über Supabase Auth (auth.users) + user-Tabelle.
/// user.id ist FK auf auth.users.id.
class AuthService {
  static AppUser? currentUser;
  static final _supabase = Supabase.instance.client;

  /// Beim App-Start: aktive Supabase-Session prüfen und user-Profil laden
  static Future<void> init() async {
    final session = _supabase.auth.currentSession;
    if (session != null) {
      try {
        final response = await _supabase
            .from(AppConstants.tableUser)
            .select()
            .eq('id', session.user.id)
            .single();
        currentUser = AppUser.fromJson(response);
      } catch (_) {
        // Profil existiert noch nicht oder Fehler → ausloggen
        await _supabase.auth.signOut();
      }
    }
  }

  static bool get isLoggedIn => currentUser != null;

  /// Generiert eine interne Email-Adresse aus dem Benutzernamen.
  /// Supabase Auth benötigt eine Email, der User sieht sie aber nicht.
  static String _emailFromUsername(String username) =>
      '${username.toLowerCase()}@pommesblog.app';

  static Future<AppUser> register({
    required String password,
    required String firstName,
    required String lastName,
    required String username,
    String? secret,
  }) async {
    // Prüfe ob Username schon vergeben
    final existing = await _supabase
        .from(AppConstants.tableUser)
        .select('id')
        .eq('username', username);
    if ((existing as List).isNotEmpty) {
      throw Exception('Benutzername bereits vergeben');
    }

    // 1) Supabase Auth: User anlegen mit generierter Email
    final authResponse = await _supabase.auth.signUp(
      email: _emailFromUsername(username),
      password: password,
    );
    final authUser = authResponse.user;
    if (authUser == null) {
      throw Exception('Registrierung fehlgeschlagen');
    }

    // 2) user-Tabelle befüllen (id = auth.users.id)
    final response = await _supabase
        .from(AppConstants.tableUser)
        .insert({
          'id': authUser.id,
          'first_name': firstName,
          'last_name': lastName,
          'username': username,
          'secret': secret,
        })
        .select()
        .single();

    final user = AppUser.fromJson(response);
    currentUser = user;
    return user;
  }

  static Future<AppUser> login({
    required String username,
    required String password,
  }) async {
    // 1) Supabase Auth: einloggen mit generierter Email
    final authResponse = await _supabase.auth.signInWithPassword(
      email: _emailFromUsername(username),
      password: password,
    );
    final authUser = authResponse.user;
    if (authUser == null) {
      throw Exception('Anmeldung fehlgeschlagen');
    }

    // 2) Profil aus user-Tabelle laden
    try {
      final response = await _supabase
          .from(AppConstants.tableUser)
          .select()
          .eq('id', authUser.id)
          .single();
      final user = AppUser.fromJson(response);
      currentUser = user;
      return user;
    } catch (_) {
      throw Exception('Benutzerprofil nicht gefunden');
    }
  }

  static Future<void> logout() async {
    await _supabase.auth.signOut();
    currentUser = null;
  }

  static Future<void> updateProfile({
    String? firstName,
    String? lastName,
    String? secret,
    String? profileImage,
  }) async {
    if (currentUser == null) return;
    final updates = <String, dynamic>{};
    if (firstName != null) updates['first_name'] = firstName;
    if (lastName != null) updates['last_name'] = lastName;
    if (secret != null) updates['secret'] = secret;
    if (profileImage != null) updates['profile_image'] = profileImage;

    if (updates.isNotEmpty) {
      final response = await _supabase
          .from(AppConstants.tableUser)
          .update(updates)
          .eq('id', currentUser!.id)
          .select()
          .single();
      currentUser = AppUser.fromJson(response);
    }
  }

  /// Lädt ein Profilbild hoch und speichert den Pfad in der user-Tabelle.
  static Future<void> uploadProfileImage(
      String fileName, Uint8List bytes) async {
    if (currentUser == null) return;
    final path =
        await ImageService.uploadProfileImage(currentUser!.id, fileName, bytes);
    await updateProfile(profileImage: path);
  }

  /// Gibt die signed URL für das aktuelle Profilbild zurück.
  static Future<String?> getProfileImageUrl() async {
    final img = currentUser?.profileImage;
    if (img == null) return null;
    return ImageService.getProfileImageUrl(img);
  }
}
