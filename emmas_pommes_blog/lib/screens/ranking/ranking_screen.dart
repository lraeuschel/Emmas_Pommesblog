import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../models/pommesbude.dart';
import '../../models/app_user.dart';
import '../../services/pommesbude_service.dart';
import '../../services/besuch_service.dart';
import '../../widgets/rating_bar.dart';
import '../../widgets/user_avatar.dart';
import '../bude/bude_detail_screen.dart';

class RankingScreen extends StatefulWidget {
  const RankingScreen({super.key});

  @override
  RankingScreenState createState() => RankingScreenState();
}

class RankingScreenState extends State<RankingScreen>
    with SingleTickerProviderStateMixin {

  void reload() => _loadData();
  late TabController _tabController;
  List<Pommesbude> _topBuden = [];
  List<Map<String, dynamic>> _topUsers = [];
  bool _loadingBuden = true;
  bool _loadingUsers = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    _loadBuden();
    _loadUsers();
  }

  Future<void> _loadBuden() async {
    setState(() => _loadingBuden = true);
    try {
      _topBuden = await PommesbudeService.getTopRated();
    } catch (_) {}
    if (mounted) setState(() => _loadingBuden = false);
  }

  Future<void> _loadUsers() async {
    setState(() => _loadingUsers = true);
    try {
      _topUsers = await BesuchService.getUserRanking();
    } catch (_) {}
    if (mounted) setState(() => _loadingUsers = false);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🏆 Rangliste'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: PommesTheme.pommesYellow,
          labelColor: PommesTheme.pommesYellow,
          unselectedLabelColor: Colors.white54,
          tabs: const [
            Tab(text: 'Top Pommesbuden', icon: Icon(Icons.store)),
            Tab(text: 'Top Besucher', icon: Icon(Icons.people)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBudenRanking(),
          _buildUserRanking(),
        ],
      ),
    );
  }

  Widget _buildBudenRanking() {
    if (_loadingBuden) {
      return const Center(child: CircularProgressIndicator());
    }

    final ranked = List<Pommesbude>.from(_topBuden)
      ..sort((a, b) => b.visitCount.compareTo(a.visitCount));
    if (ranked.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🍟', style: TextStyle(fontSize: 48)),
            SizedBox(height: 8),
            Text('Noch keine Pommesbuden',
                style: TextStyle(color: Colors.white54)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: ranked.length,
      itemBuilder: (context, index) {
        final bude = ranked[index];
        return _buildBudeRankCard(index + 1, bude);
      },
    );
  }

  Widget _buildBudeRankCard(int rank, Pommesbude bude) {
    Color? medalColor;
    if (rank == 1) medalColor = const Color(0xFFFFD700);
    if (rank == 2) medalColor = const Color(0xFFC0C0C0);
    if (rank == 3) medalColor = const Color(0xFFCD7F32);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => BudeDetailScreen(bude: bude)),
        ),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Rank
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: medalColor ?? PommesTheme.surfaceDark,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$rank',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: medalColor != null
                          ? PommesTheme.primaryPurple
                          : Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bude.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${bude.visitCount} Besuche',
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 13),
                    ),
                  ],
                ),
              ),
              // Rating
              RatingDisplay(rating: bude.averageRating, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserRanking() {
    if (_loadingUsers) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_topUsers.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('👤', style: TextStyle(fontSize: 48)),
            SizedBox(height: 8),
            Text('Noch keine Besuche',
                style: TextStyle(color: Colors.white54)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _topUsers.length,
      itemBuilder: (context, index) {
        final entry = _topUsers[index];
        final user = entry['user'] != null
            ? AppUser.fromJson(entry['user'])
            : null;
        final count = entry['count'] as int;
        return _buildUserRankCard(index + 1, user, count);
      },
    );
  }

  Widget _buildUserRankCard(int rank, AppUser? user, int count) {
    Color? medalColor;
    if (rank == 1) medalColor = const Color(0xFFFFD700);
    if (rank == 2) medalColor = const Color(0xFFC0C0C0);
    if (rank == 3) medalColor = const Color(0xFFCD7F32);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Rank
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: medalColor ?? PommesTheme.surfaceDark,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '$rank',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: medalColor != null
                        ? PommesTheme.primaryPurple
                        : Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Avatar
            UserAvatar(user: user, radius: 20),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user?.displayName ?? 'Unbekannt',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    '@${user?.username ?? '?'}',
                    style:
                        const TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                ],
              ),
            ),
            // Count
            Column(
              children: [
                Text(
                  '$count',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: PommesTheme.pommesYellow,
                  ),
                ),
                const Text('Besuche',
                    style: TextStyle(color: Colors.white54, fontSize: 11)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
