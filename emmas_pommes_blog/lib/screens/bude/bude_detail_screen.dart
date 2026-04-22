import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../models/pommesbude.dart';
import '../../models/besuch.dart';
import '../../services/pommesbude_service.dart';
import '../../widgets/besuch_card.dart';
import '../../widgets/rating_bar.dart';
import '../besuch/add_besuch_screen.dart';
import '../besuch/besuch_detail_screen.dart';

class BudeDetailScreen extends StatefulWidget {
  final Pommesbude bude;

  const BudeDetailScreen({super.key, required this.bude});

  @override
  State<BudeDetailScreen> createState() => _BudeDetailScreenState();
}

class _BudeDetailScreenState extends State<BudeDetailScreen> {
  List<Besuch> _visits = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadVisits();
  }

  Future<void> _loadVisits() async {
    setState(() => _loading = true);
    try {
      _visits = await PommesbudeService.getVisitsForBude(widget.bude.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler: $e')),
        );
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  double? _averageOf(double? Function(Besuch) getter) {
    final vals = _visits
        .map(getter)
        .where((v) => v != null)
        .cast<double>()
        .toList();
    if (vals.isEmpty) return null;
    return vals.reduce((a, b) => a + b) / vals.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.bude.name),
      ),
      body: RefreshIndicator(
        onRefresh: _loadVisits,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with photo
              if (widget.bude.linkToPhoto != null)
                Image.network(
                  widget.bude.linkToPhoto!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, e, s) => Container(
                    height: 200,
                    color: PommesTheme.surfaceDark,
                    child: const Center(
                      child: Text('🍟', style: TextStyle(fontSize: 60)),
                    ),
                  ),
                )
              else
                Container(
                  height: 150,
                  width: double.infinity,
                  color: PommesTheme.surfaceDark,
                  child: const Center(
                    child: Text('🍟', style: TextStyle(fontSize: 60)),
                  ),
                ),

              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.bude.name,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: PommesTheme.pommesYellow,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.location_on,
                            size: 16, color: Colors.white54),
                        const SizedBox(width: 4),
                        Text(
                          '${widget.bude.lat.toStringAsFixed(4)}, ${widget.bude.lon.toStringAsFixed(4)}',
                          style: const TextStyle(color: Colors.white54),
                        ),
                      ],
                    ),

                    // Rating summary
                    if (_visits.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      const Text(
                        'Durchschnittliche Bewertungen',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _ratingRow('Gesamt', _averageOf((b) => b.overallRating)),
                      _ratingRow(
                          'Service', _averageOf((b) => b.serviceRating)),
                      _ratingRow(
                          'Wartezeit', _averageOf((b) => b.waitingTimeRating)),
                      _ratingRow(
                          'Ambiente', _averageOf((b) => b.ambientRating)),
                    ],

                    // Visits section
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Besuche (${_visits.length})',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              if (_loading)
                const Center(
                    child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ))
              else if (_visits.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                    child: Column(
                      children: [
                        Text('😢', style: TextStyle(fontSize: 48)),
                        SizedBox(height: 8),
                        Text('Noch keine Besuche',
                            style: TextStyle(color: Colors.white54)),
                      ],
                    ),
                  ),
                )
              else
                ..._visits.map((besuch) => BesuchCard(
                      besuch: besuch,
                      showBudeName: false,
                      onTap: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                BesuchDetailScreen(besuchId: besuch.id),
                          ),
                        );
                        _loadVisits();
                      },
                    )),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (_) => AddBesuchScreen(bude: widget.bude),
            ),
          );
          if (result == true) _loadVisits();
        },
        icon: const Icon(Icons.rate_review),
        label: const Text('Besuch eintragen'),
      ),
    );
  }

  Widget _ratingRow(String label, double? avg) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: const TextStyle(color: Colors.white70)),
          ),
          if (avg != null) ...[
            RatingDisplay(rating: avg, size: 18),
          ] else
            const Text('-', style: TextStyle(color: Colors.white38)),
        ],
      ),
    );
  }
}
