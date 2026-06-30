import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/constants.dart';
import '../models/besuch.dart';
import '../models/pommesbude.dart';

class PommesBadge {
  final String id;
  final String title;
  final String emoji;
  final String description;
  final bool earned;

  PommesBadge({
    required this.id,
    required this.title,
    required this.emoji,
    required this.description,
    required this.earned,
  });
}

class BadgeService {
  static final _supabase = Supabase.instance.client;

  /// Berechnet alle Badges für einen User.
  static Future<List<PommesBadge>> getBadgesForUser(String userId) async {
    // Lade alle Besuche des Users mit Pommesbude-Daten
    final visitResponse = await _supabase
        .from(AppConstants.tableVisit)
        .select('*, pommesbude(*)')
        .eq('id', userId);
    final visits = (visitResponse as List)
        .map((row) => Besuch.fromJson(row))
        .toList();

    // Lade alle Pommesbuden
    final budenResponse = await _supabase
        .from(AppConstants.tablePommesbude)
        .select();
    final allBuden = (budenResponse as List)
        .map((row) => Pommesbude.fromJson(row))
        .toList();

    // Lade alle Besuche aller User für Vergleiche
    final allVisitsResponse = await _supabase
        .from(AppConstants.tableVisit)
        .select('id');
    final visitCountByUser = <String, int>{};
    for (final row in (allVisitsResponse as List)) {
      final uid = row['id'].toString();
      visitCountByUser[uid] = (visitCountByUser[uid] ?? 0) + 1;
    }

    final badges = <PommesBadge>[];
    final visitCount = visits.length;
    final visitedBudeIds = visits.map((v) => v.location).toSet();

    // ── Besuchs-Badges ──────────────────────────────────────

    badges.add(PommesBadge(
      id: 'first_visit',
      title: 'Erster Biss',
      emoji: '🍟',
      description: 'Deinen ersten Besuch eingetragen',
      earned: visitCount >= 1,
    ));

    badges.add(PommesBadge(
      id: 'five_visits',
      title: 'Stammgast',
      emoji: '⭐',
      description: '5 Besuche eingetragen',
      earned: visitCount >= 5,
    ));

    badges.add(PommesBadge(
      id: 'ten_visits',
      title: 'Pommes-Profi',
      emoji: '🏅',
      description: '10 Besuche eingetragen',
      earned: visitCount >= 10,
    ));

    badges.add(PommesBadge(
      id: 'twentyfive_visits',
      title: 'Pommes-Legende',
      emoji: '👑',
      description: '25 Besuche eingetragen',
      earned: visitCount >= 25,
    ));

    // ── Geografie-Badges ────────────────────────────────────

    if (allBuden.isNotEmpty) {
      final visitedBuden = allBuden
          .where((b) => visitedBudeIds.contains(b.id))
          .toList();

      // Nördlichste Bude
      final northernMost = allBuden.reduce(
          (a, b) => a.lat > b.lat ? a : b);
      badges.add(PommesBadge(
        id: 'northernmost',
        title: 'Nordlicht',
        emoji: '🧭',
        description: 'An der nördlichsten Pommesbude gewesen (${northernMost.name})',
        earned: visitedBudeIds.contains(northernMost.id),
      ));

      // Südlichste Bude
      final southernMost = allBuden.reduce(
          (a, b) => a.lat < b.lat ? a : b);
      badges.add(PommesBadge(
        id: 'southernmost',
        title: 'Südwind',
        emoji: '🌴',
        description: 'An der südlichsten Pommesbude gewesen (${southernMost.name})',
        earned: visitedBudeIds.contains(southernMost.id),
      ));

      // Westlichste Bude
      final westernMost = allBuden.reduce(
          (a, b) => a.lon < b.lon ? a : b);
      badges.add(PommesBadge(
        id: 'westernmost',
        title: 'Westwärts',
        emoji: '🌅',
        description: 'An der westlichsten Pommesbude gewesen (${westernMost.name})',
        earned: visitedBudeIds.contains(westernMost.id),
      ));

      // Östlichste Bude
      final easternMost = allBuden.reduce(
          (a, b) => a.lon > b.lon ? a : b);
      badges.add(PommesBadge(
        id: 'easternmost',
        title: 'Ostwärts',
        emoji: '🌄',
        description: 'An der östlichsten Pommesbude gewesen (${easternMost.name})',
        earned: visitedBudeIds.contains(easternMost.id),
      ));

      // Alle Buden besucht
      badges.add(PommesBadge(
        id: 'all_buden',
        title: 'Komplettist',
        emoji: '🗺️',
        description: 'Alle ${allBuden.length} Pommesbuden besucht',
        earned: visitedBudeIds.length >= allBuden.length && allBuden.isNotEmpty,
      ));

      // Vielfalt - mindestens 3 verschiedene Buden
      badges.add(PommesBadge(
        id: 'variety',
        title: 'Entdecker',
        emoji: '🔍',
        description: 'Mindestens 3 verschiedene Pommesbuden besucht',
        earned: visitedBudeIds.length >= 3,
      ));
    }

    // ── Bewertungs-Badges ───────────────────────────────────

    final hasTopRating = visits.any((v) => (v.overallRating ?? 0) >= 5);
    badges.add(PommesBadge(
      id: 'five_stars',
      title: 'Feinschmecker',
      emoji: '🌟',
      description: 'Einen Besuch mit 5 Sternen bewertet',
      earned: hasTopRating,
    ));

    final hasLowRating = visits.any((v) =>
        v.overallRating != null && v.overallRating! <= 1);
    badges.add(PommesBadge(
      id: 'one_star',
      title: 'Kritiker',
      emoji: '🧐',
      description: 'Einen Besuch mit nur 1 Stern bewertet',
      earned: hasLowRating,
    ));

    // ── Ranking-Badge ───────────────────────────────────────

    final isTopVisitor = visitCountByUser.values.every((c) => c <= visitCount);
    badges.add(PommesBadge(
      id: 'most_visits',
      title: 'Pommes-Königin',
      emoji: '🏆',
      description: 'Die meisten Besuche aller User',
      earned: isTopVisitor && visitCount > 0,
    ));

    // ── Sonder-Badges ───────────────────────────────────────

    final hasReview = visits.any(
        (v) => v.review != null && v.review!.isNotEmpty);
    badges.add(PommesBadge(
      id: 'reviewer',
      title: 'Wortgewandt',
      emoji: '✍️',
      description: 'Einen Besuch mit Review geschrieben',
      earned: hasReview,
    ));

    final weekendVisits = visits.where((v) =>
        v.createdAt.weekday == DateTime.saturday ||
        v.createdAt.weekday == DateTime.sunday).length;
    badges.add(PommesBadge(
      id: 'weekend_warrior',
      title: 'Wochenend-Krieger',
      emoji: '🎉',
      description: '5 Besuche am Wochenende',
      earned: weekendVisits >= 5,
    ));

    return badges;
  }
}
