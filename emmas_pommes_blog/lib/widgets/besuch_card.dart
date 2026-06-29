import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../models/besuch.dart';
import '../services/besuch_service.dart';
import '../services/like_service.dart';
import '../widgets/rating_bar.dart';
import '../widgets/user_avatar.dart';
import 'package:intl/intl.dart';

class BesuchCard extends StatefulWidget {
  final Besuch besuch;
  final VoidCallback? onTap;
  final bool showBudeName;
  final bool isTagged;

  const BesuchCard({
    super.key,
    required this.besuch,
    this.onTap,
    this.showBudeName = true,
    this.isTagged = false,
  });

  @override
  State<BesuchCard> createState() => _BesuchCardState();
}

class _BesuchCardState extends State<BesuchCard> {
  List<String> _imageUrls = [];
  bool _loadedImages = false;
  int _likeCount = 0;
  bool _liked = false;

  @override
  void initState() {
    super.initState();
    _loadImages();
    _loadLikeData();
  }

  Future<void> _loadImages() async {
    try {
      final urls = await BesuchService.getVisitImages(
        widget.besuch.userId,
        widget.besuch.location,
      );
      if (mounted) setState(() { _imageUrls = urls; _loadedImages = true; });
    } catch (_) {
      if (mounted) setState(() => _loadedImages = true);
    }
  }

  Future<void> _loadLikeData() async {
    try {
      final count = await LikeService.getLikeCount(widget.besuch.visitId);
      final liked = await LikeService.hasLiked(widget.besuch.visitId);
      if (mounted) setState(() { _likeCount = count; _liked = liked; });
    } catch (_) {}
  }

  Future<void> _toggleLike() async {
    try {
      final nowLiked = await LikeService.toggleLike(widget.besuch.visitId);
      if (mounted) {
        setState(() {
          _liked = nowLiked;
          _likeCount += nowLiked ? 1 : -1;
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final besuch = widget.besuch;
    final isTagged = widget.isTagged;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with user and date
              Row(
                children: [
                  UserAvatar(user: besuch.user, radius: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          besuch.user?.displayName ?? 'Unbekannt',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        Text(
                          DateFormat('dd.MM.yyyy').format(besuch.createdAt),
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  if (besuch.overallRating != null)
                    RatingDisplay(rating: besuch.overallRating),
                ],
              ),

              if (widget.showBudeName && besuch.pommesbude != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text('🍟 ', style: TextStyle(fontSize: 18)),
                    Text(
                      besuch.pommesbude!.name,
                      style: const TextStyle(
                        color: PommesTheme.pommesYellow,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ],

              // Photos
              if (_imageUrls.isNotEmpty) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    _imageUrls.first,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, e, s) => Container(
                      height: 200,
                      color: PommesTheme.surfaceDark,
                      child: const Center(
                          child: Icon(Icons.broken_image, color: Colors.white38)),
                    ),
                  ),
                ),
                if (_imageUrls.length > 1)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '+${_imageUrls.length - 1} weitere Fotos',
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ),
              ] else if (besuch.linkToPicture != null) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    besuch.linkToPicture!,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, e, s) => Container(
                      height: 200,
                      color: PommesTheme.surfaceDark,
                      child: const Center(
                          child: Icon(Icons.broken_image, color: Colors.white38)),
                    ),
                  ),
                ),
              ],

              // Review
              if (besuch.review != null && besuch.review!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(besuch.review!, style: const TextStyle(fontSize: 14)),
              ],

              // Price and visitors
              const SizedBox(height: 8),
              Row(
                children: [
                  if (isTagged) ...[
                    const Icon(Icons.tag, size: 16, color: PommesTheme.pommesYellow),
                    const SizedBox(width: 4),
                    const Text('Du warst dabei',
                        style: TextStyle(color: PommesTheme.pommesYellow, fontSize: 12)),
                    const SizedBox(width: 16),
                  ],
                  if (besuch.price != null) ...[
                    Icon(Icons.euro, size: 16, color: PommesTheme.pommesYellow),
                    const SizedBox(width: 4),
                    Text('${besuch.price!.toStringAsFixed(2)} €',
                        style: const TextStyle(color: Colors.white70)),
                    const SizedBox(width: 16),
                  ],
                  if (besuch.countVisitors != null) ...[
                    const Icon(Icons.people,
                        size: 16, color: PommesTheme.pommesYellow),
                    const SizedBox(width: 4),
                    Text('${besuch.countVisitors} Besucher',
                        style: const TextStyle(color: Colors.white70)),
                  ],
                  const Spacer(),
                  // Like button
                  GestureDetector(
                    onTap: _toggleLike,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _liked ? Icons.thumb_up : Icons.thumb_up_outlined,
                          size: 18,
                          color: _liked
                              ? PommesTheme.pommesYellow
                              : Colors.white54,
                        ),
                        if (_likeCount > 0) ...[
                          const SizedBox(width: 4),
                          Text(
                            '$_likeCount',
                            style: TextStyle(
                              color: _liked
                                  ? PommesTheme.pommesYellow
                                  : Colors.white54,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
