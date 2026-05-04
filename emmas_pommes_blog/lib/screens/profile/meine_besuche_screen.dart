import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../models/besuch.dart';
import '../../services/auth_service.dart';
import '../../services/besuch_service.dart';
import '../../widgets/besuch_card.dart';
import '../besuch/besuch_detail_screen.dart';

class MeineBesucheScreen extends StatefulWidget {
  const MeineBesucheScreen({super.key});

  @override
  MeineBesucheScreenState createState() => MeineBesucheScreenState();
}

class MeineBesucheScreenState extends State<MeineBesucheScreen> {
  void reload() => _load();
  List<Besuch> _besuche = [];
  Set<String> _taggedKeys = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (AuthService.currentUser == null) return;
    setState(() => _loading = true);
    try {
      final userId = AuthService.currentUser!.id;
      final results = await Future.wait([
        BesuchService.getByUser(userId),
        BesuchService.getTaggedVisits(userId),
      ]);
      final own = results[0] as List<Besuch>;
      final tagged = results[1] as List<Besuch>;
      // Track tagged visit IDs
      _taggedKeys = tagged.map((b) => b.visitId).toSet();
      // Merge, avoid duplicates by visitId
      final seen = <String>{};
      final merged = <Besuch>[];
      for (final b in own) {
        if (seen.add(b.visitId)) merged.add(b);
      }
      for (final b in tagged) {
        if (seen.add(b.visitId)) merged.add(b);
      }
      merged.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _besuche = merged;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler: $e')),
        );
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meine Besuche'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _besuche.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🍟', style: TextStyle(fontSize: 64)),
                      const SizedBox(height: 16),
                      const Text(
                        'Noch keine Besuche',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white54,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Geh auf die Karte und trage deinen\nersten Pommesbuden-Besuch ein!',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white38),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Stats header
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      color: PommesTheme.surfaceDark,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _statItem(
                            '${_besuche.length}',
                            'Besuche',
                            Icons.restaurant,
                          ),
                          _statItem(
                            _besuche
                                .map((b) => b.location)
                                .toSet()
                                .length
                                .toString(),
                            'Buden',
                            Icons.store,
                          ),
                          _statItem(
                            _averageRating(),
                            'Ø Rating',
                            Icons.star,
                          ),
                        ],
                      ),
                    ),
                    // List
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: _besuche.length,
                        itemBuilder: (context, index) {
                          final besuch = _besuche[index];
                          final isTagged = _taggedKeys.contains(besuch.visitId) &&
                              besuch.userId != AuthService.currentUser!.id;
                          return BesuchCard(
                            besuch: besuch,
                            isTagged: isTagged,
                            onTap: () async {
                              await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => BesuchDetailScreen(
                                      visitId: besuch.visitId),
                                ),
                              );
                              _load();
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }

  String _averageRating() {
    final ratings = _besuche
        .where((b) => b.overallRating != null)
        .map((b) => b.overallRating!)
        .toList();
    if (ratings.isEmpty) return '-';
    return (ratings.reduce((a, b) => a + b) / ratings.length)
        .toStringAsFixed(1);
  }

  Widget _statItem(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: PommesTheme.pommesYellow, size: 28),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: PommesTheme.pommesYellow,
          ),
        ),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
      ],
    );
  }
}
