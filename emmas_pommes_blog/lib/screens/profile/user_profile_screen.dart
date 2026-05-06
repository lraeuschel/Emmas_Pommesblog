import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../models/app_user.dart';
import '../../models/besuch.dart';
import '../../services/besuch_service.dart';
import '../../services/image_service.dart';
import '../../widgets/besuch_card.dart';
import '../../widgets/user_avatar.dart';
import '../besuch/besuch_detail_screen.dart';

/// Öffentliches Profil eines anderen Benutzers (ohne Secret).
class UserProfileScreen extends StatefulWidget {
  final AppUser user;

  const UserProfileScreen({super.key, required this.user});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  List<Besuch> _besuche = [];
  bool _loading = true;
  String? _profileImageUrl;

  @override
  void initState() {
    super.initState();
    _load();
    _loadProfileImage();
  }

  Future<void> _loadProfileImage() async {
    final path = widget.user.profileImage;
    if (path == null || path.isEmpty) return;
    if (path.startsWith('http')) {
      if (mounted) setState(() => _profileImageUrl = path);
      return;
    }
    final url = await ImageService.getProfileImageUrl(path);
    if (mounted && url != null) setState(() => _profileImageUrl = url);
  }

  void _showFullImage() {
    if (_profileImageUrl == null) return;
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: InteractiveViewer(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                _profileImageUrl!,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final visits = await BesuchService.getByUser(widget.user.id);
      visits.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _besuche = visits;
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
    final user = widget.user;

    return Scaffold(
      appBar: AppBar(
        title: Text(user.displayName),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  // Avatar
                  GestureDetector(
                    onTap: _showFullImage,
                    child: UserAvatar(user: user, radius: 60),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user.displayName,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '@${user.username}',
                    style: const TextStyle(
                      color: PommesTheme.pommesYellow,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Mitglied seit ${user.createdAt.day}.${user.createdAt.month}.${user.createdAt.year}',
                    style: const TextStyle(color: Colors.white38, fontSize: 13),
                  ),
                  const SizedBox(height: 24),
                  // Stats
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
                  // Visits list
                  if (_besuche.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(32),
                      child: Text(
                        'Noch keine Besuche',
                        style: TextStyle(color: Colors.white54),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: _besuche.length,
                      itemBuilder: (context, index) {
                        final besuch = _besuche[index];
                        return BesuchCard(
                          besuch: besuch,
                          isTagged: false,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => BesuchDetailScreen(
                                    visitId: besuch.visitId),
                              ),
                            );
                          },
                        );
                      },
                    ),
                ],
              ),
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
        Text(label,
            style: const TextStyle(color: Colors.white54, fontSize: 12)),
      ],
    );
  }
}
