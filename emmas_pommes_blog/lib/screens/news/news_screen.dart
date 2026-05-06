import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/constants.dart';
import '../../config/theme.dart';
import '../../models/app_user.dart';
import '../../models/besuch.dart';
import '../../models/pommesbude.dart';
import '../../widgets/user_avatar.dart';
import '../bude/bude_detail_screen.dart';
import '../besuch/besuch_detail_screen.dart';

enum _NewsType { visit, budeAdded, userJoined, secretLeak }

class _NewsItem {
  final _NewsType type;
  final DateTime date;
  final AppUser? user;
  final Pommesbude? bude;
  final Besuch? besuch;
  final String? secretText;
  final bool secretLocked;
  final List<AppUser> taggedUsers;

  _NewsItem({
    required this.type,
    required this.date,
    this.user,
    this.bude,
    this.besuch,
    this.secretText,
    this.secretLocked = false,
    this.taggedUsers = const [],
  });
}

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  NewsScreenState createState() => NewsScreenState();
}

class NewsScreenState extends State<NewsScreen> {
  List<_NewsItem> _items = [];
  bool _loading = true;

  bool _sameNum(num? a, num? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    return (a - b).abs() < 0.0001;
  }

  String _groupKey(Besuch visit, List<String> participantIds) {
    final sortedParticipants = List<String>.from(participantIds)..sort();
    return [
      visit.location,
      visit.price?.toString() ?? '',
      visit.review ?? '',
      visit.countVisitors?.toString() ?? '',
      visit.overallRating?.toString() ?? '',
      visit.serviceRating?.toString() ?? '',
      visit.waitingTimeRating?.toString() ?? '',
      visit.ambientRating?.toString() ?? '',
      sortedParticipants.join('|'),
    ].join('::');
  }

  void reload() => _load();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final supabase = Supabase.instance.client;

      final results = await Future.wait([
        // Recent visits with joined data
        supabase
            .from(AppConstants.tableVisit)
            .select('*, user(*), pommesbude(*)')
            .order('created_at', ascending: false)
            .limit(50),
        // Recent buden
        supabase
            .from(AppConstants.tablePommesbude)
            .select()
            .order('created_at', ascending: false)
            .limit(50),
        // Recent users
        supabase
            .from(AppConstants.tableUser)
            .select()
            .order('created_at', ascending: false)
            .limit(50),
        // All users with secrets (for secret leak)
        supabase
            .from(AppConstants.tableUser)
            .select()
            .not('secret', 'is', null)
            .neq('secret', ''),
      ]);

      final items = <_NewsItem>[];

      // Load all visit participant arrays in one query
      final tagRows = await supabase
          .from(AppConstants.tableVisitTags)
          .select('visit_id, tagged_user_ids');
      final participantIdsByVisit = <String, List<String>>{};
      final allParticipantIds = <String>{};
      for (final row in tagRows) {
        final key = row['visit_id'].toString();
        final ids = (row['tagged_user_ids'] as List?)
                ?.map((value) => value.toString())
                .toList() ??
            [];
        participantIdsByVisit[key] = ids;
        allParticipantIds.addAll(ids);
      }

      final usersById = <String, AppUser>{};
      if (allParticipantIds.isNotEmpty) {
        final userRows = await supabase
            .from(AppConstants.tableUser)
            .select()
            .inFilter('id', allParticipantIds.toList());
        for (final row in userRows as List) {
          final user = AppUser.fromJson(row);
          usersById[user.id] = user;
        }
      }

      // Visits
      final visits = (results[0] as List)
          .map((row) => Besuch.fromJson(row as Map<String, dynamic>))
          .toList();

      final representativeByGroupKey = <String, Besuch>{};
      final participantIdsByGroupKey = <String, List<String>>{};

      for (final besuch in visits) {
        final participantIds = participantIdsByVisit[besuch.visitId];
        if (participantIds == null || participantIds.isEmpty) {
          representativeByGroupKey[besuch.visitId] = besuch;
          participantIdsByGroupKey[besuch.visitId] = [];
          continue;
        }

        final groupKey = _groupKey(besuch, participantIds);
        final currentRepresentative = representativeByGroupKey[groupKey];
        if (currentRepresentative == null ||
            besuch.createdAt.isBefore(currentRepresentative.createdAt)) {
          representativeByGroupKey[groupKey] = besuch;
          participantIdsByGroupKey[groupKey] = participantIds;
        }
      }

      for (final entry in representativeByGroupKey.entries) {
        final besuch = entry.value;
        final participantIds = participantIdsByGroupKey[entry.key] ?? const <String>[];
        final taggedUsers = participantIds
            .where((id) => id != besuch.userId)
            .map((id) => usersById[id])
            .whereType<AppUser>()
            .toList();

        items.add(_NewsItem(
          type: _NewsType.visit,
          date: besuch.createdAt,
          user: besuch.user,
          bude: besuch.pommesbude,
          besuch: besuch,
          taggedUsers: taggedUsers,
        ));
      }

      // New buden
      for (final row in (results[1] as List)) {
        final bude = Pommesbude.fromJson(row);
        items.add(_NewsItem(
          type: _NewsType.budeAdded,
          date: bude.createdAt,
          bude: bude,
        ));
      }

      // New users
      for (final row in (results[2] as List)) {
        final user = AppUser.fromJson(row);
        items.add(_NewsItem(
          type: _NewsType.userJoined,
          date: user.createdAt,
          user: user,
        ));
      }

      // Secret leak logic
      final secretItem = await _buildSecretItem(
        results[3] as List,
        results[0] as List,
      );
      if (secretItem != null) items.add(secretItem);

      // Sort chronologically (newest first)
      items.sort((a, b) {
        // Secret leak always pinned at top
        if (a.type == _NewsType.secretLeak) return -1;
        if (b.type == _NewsType.secretLeak) return 1;
        return b.date.compareTo(a.date);
      });

      _items = items;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler: $e')),
        );
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  /// Berechnet den Montag der aktuellen Woche (00:00 UTC).
  static DateTime _mondayOfWeek(DateTime date) {
    final d = DateTime.utc(date.year, date.month, date.day);
    return d.subtract(Duration(days: d.weekday - 1));
  }

  /// Berechnet den Sonntag der aktuellen Woche (23:59 UTC).
  static DateTime _sundayOfWeek(DateTime date) {
    final monday = _mondayOfWeek(date);
    return monday.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
  }

  /// Bestimmt den "Secret Leak" der Woche.
  /// Jeden Sonntag wird das Geheimnis eines zufälligen Users geleakt.
  /// Nur sichtbar, wenn der aktuelle User diese Woche min. 1x Pommes war.
  Future<_NewsItem?> _buildSecretItem(
      List usersWithSecrets, List allVisits) async {
    if (usersWithSecrets.isEmpty) return null;

    final now = DateTime.now();
    final monday = _mondayOfWeek(now);
    final sunday = _sundayOfWeek(now);

    // Wochennummer als deterministischer Seed
    final weekSeed = monday.millisecondsSinceEpoch;
    final pickedIndex = weekSeed % usersWithSecrets.length;
    final pickedUser = AppUser.fromJson(usersWithSecrets[pickedIndex]);

    // Prüfe ob der aktuelle User diese Woche (Mo-So) min. 1x essen war
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    if (currentUserId == null) return null;

    bool hasVisitThisWeek = false;
    for (final row in allVisits) {
      final visitUserId = row['id'].toString();
      final visitDate = DateTime.parse(row['created_at']);
      if (visitUserId == currentUserId &&
          !visitDate.isBefore(monday) &&
          !visitDate.isAfter(sunday)) {
        hasVisitThisWeek = true;
        break;
      }
    }

    return _NewsItem(
      type: _NewsType.secretLeak,
      date: sunday,
      user: pickedUser,
      secretText: pickedUser.secret,
      secretLocked: !hasVisitThisWeek,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Neuigkeiten'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('📭', style: TextStyle(fontSize: 48)),
                      SizedBox(height: 8),
                      Text('Noch keine Neuigkeiten',
                          style: TextStyle(color: Colors.white54)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _items.length,
                  itemBuilder: (context, index) =>
                      _buildNewsCard(_items[index]),
                ),
    );
  }

  Widget _buildNewsCard(_NewsItem item) {
    final dateStr = _formatDate(item.date);

    switch (item.type) {
      case _NewsType.secretLeak:
        return _buildSecretCard(item);

      case _NewsType.visit:
        final budeName = item.bude?.name ?? 'einer Pommesbude';
        String subtitle;
        if (item.taggedUsers.isNotEmpty) {
          final firstName = item.taggedUsers.first.displayName;
          final otherCount = item.taggedUsers.length - 1;
          subtitle = otherCount > 0
              ? 'war mit $firstName und $otherCount weiteren bei $budeName essen'
              : 'war mit $firstName bei $budeName essen';
        } else {
          subtitle = 'war bei $budeName essen';
        }
        return _buildCard(
          icon: Icons.restaurant,
          iconColor: PommesTheme.pommesYellow,
          date: dateStr,
          avatar: item.user,
          title: item.user?.displayName ?? 'Jemand',
          subtitle: subtitle,
          trailing: item.besuch?.overallRating != null
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star,
                        color: PommesTheme.pommesYellow, size: 16),
                    const SizedBox(width: 2),
                    Text(
                      item.besuch!.overallRating!.toStringAsFixed(0),
                      style: const TextStyle(
                        color: PommesTheme.pommesYellow,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                )
              : null,
          onTap: item.besuch != null
              ? () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => BesuchDetailScreen(
                        visitId: item.besuch!.visitId,
                      ),
                    ),
                  )
              : null,
        );

      case _NewsType.budeAdded:
        return _buildCard(
          icon: Icons.add_location_alt,
          iconColor: Colors.green,
          date: dateStr,
          title: item.bude?.name ?? 'Neue Pommesbude',
          subtitle: 'wurde als neue Pommesbude hinzugefügt',
          onTap: item.bude != null
              ? () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => BudeDetailScreen(bude: item.bude!),
                    ),
                  )
              : null,
        );

      case _NewsType.userJoined:
        return _buildCard(
          icon: Icons.person_add,
          iconColor: Colors.blue,
          date: dateStr,
          avatar: item.user,
          title: item.user?.displayName ?? 'Neuer User',
          subtitle: 'hat sich registriert – willkommen! 🎉',
        );
    }
  }

  Widget _buildSecretCard(_NewsItem item) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      color: item.secretLocked
          ? PommesTheme.surfaceDark
          : PommesTheme.primaryPurple.withValues(alpha: 0.8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: item.secretLocked ? Colors.white24 : PommesTheme.pommesYellow,
          width: item.secretLocked ? 1 : 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  item.secretLocked ? Icons.lock : Icons.lock_open,
                  color: item.secretLocked
                      ? Colors.white38
                      : PommesTheme.pommesYellow,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Geheimnis der Woche',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: item.secretLocked
                        ? Colors.white38
                        : PommesTheme.pommesYellow,
                  ),
                ),
                const Spacer(),
                Text(
                  _formatDate(item.date),
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (item.secretLocked) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Column(
                  children: [
                    Text('🔒', style: TextStyle(fontSize: 32)),
                    SizedBox(height: 8),
                    Text(
                      'Du musst diese Woche min. 1x Pommes\nessen gewesen sein, um das Geheimnis zu sehen!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white54, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Row(
                children: [
                  UserAvatar(user: item.user, radius: 18),
                  const SizedBox(width: 10),
                  Text(
                    '${item.user?.displayName ?? '?'}s Geheimnis:',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '"${item.secretText ?? ''}"',
                  style: const TextStyle(
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                    color: Colors.white,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCard({
    required IconData icon,
    required Color iconColor,
    required String date,
    required String title,
    required String subtitle,
    AppUser? avatar,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon or Avatar
              if (avatar != null)
                UserAvatar(user: avatar, radius: 20)
              else
                CircleAvatar(
                  radius: 20,
                  backgroundColor: iconColor.withValues(alpha: 0.2),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(icon, size: 14, color: iconColor),
                        const SizedBox(width: 4),
                        Text(
                          date,
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text.rich(
                      TextSpan(children: [
                        TextSpan(
                          text: title,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(
                          text: ' $subtitle',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ]),
                    ),
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 8),
                trailing,
              ],
              if (onTap != null)
                const Padding(
                  padding: EdgeInsets.only(left: 4),
                  child:
                      Icon(Icons.chevron_right, color: Colors.white38, size: 20),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 1) return 'Gerade eben';
    if (diff.inMinutes < 60) return 'Vor ${diff.inMinutes} Min.';
    if (diff.inHours < 24) return 'Vor ${diff.inHours} Std.';
    if (diff.inDays == 1) return 'Gestern';
    if (diff.inDays < 7) return 'Vor ${diff.inDays} Tagen';
    return DateFormat('dd.MM.yyyy').format(date);
  }
}
