import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../models/besuch.dart';
import '../widgets/rating_bar.dart';
import '../widgets/user_avatar.dart';
import 'package:intl/intl.dart';

class BesuchCard extends StatelessWidget {
  final Besuch besuch;
  final VoidCallback? onTap;
  final bool showBudeName;

  const BesuchCard({
    super.key,
    required this.besuch,
    this.onTap,
    this.showBudeName = true,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
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

              if (showBudeName && besuch.pommesbude != null) ...[
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

              // Photo
              if (besuch.linkToPicture != null) ...[
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
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
