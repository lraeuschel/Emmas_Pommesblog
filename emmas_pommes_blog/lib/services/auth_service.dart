import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../config/constants.dart';
import '../models/app_user.dart';

/// Einfache Registrierung/Login ohne Passwort.
/// Daten werden direkt in der user-Tabelle gespeichert.
class AuthService {
  static AppUser? currentUser;
  static final _supabase = Supabase.instance.client;

  /// Beim App-Start: gespeicherte user_id prüfen
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');
    if (userId != null) {
      try {
        final response = await _supabase
            .from(AppConstants.tableUser)
            .select()
            .eq('id', userId)
            .single();
        currentUser = AppUser.fromJson(response);
      } catch (_) {
        await prefs.remove('user_id');
      }
    }
  }

  static bool get isLoggedIn => currentUser != null;

  static Future<AppUser> register({
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

    // Direkt in die user-Tabelle eintragen
    final id = const Uuid().v4();
    final response = await _supabase
        .from(AppConstants.tableUser)
        .insert({
          'id': id,
          'first_name': firstName,
          'last_name': lastName,
          'username': username,
          'secret': secret,
        })
        .select()
        .single();

    final user = AppUser.fromJson(response);
    currentUser = user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_id', user.id);
    return user;
  }

  static Future<AppUser> login({
    required String username,
  }) async {
    try {
      final response = await _supabase
          .from(AppConstants.tableUser)
          .select()
          .eq('username', username)
          .single();

      final user = AppUser.fromJson(response);
      currentUser = user;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_id', user.id);
      return user;
    } catch (_) {
      throw Exception('Benutzername nicht gefunden');
    }
  }

  static Future<void> logout() async {
    currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_id');
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
}
