import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/constants.dart';
import '../../config/theme.dart';
import '../../models/besuch.dart';
import '../../services/auth_service.dart';
import '../../services/besuch_service.dart';
import '../../widgets/rating_bar.dart';

class BesuchDetailScreen extends StatefulWidget {
  final String besuchId;

  const BesuchDetailScreen({super.key, required this.besuchId});

  @override
  State<BesuchDetailScreen> createState() => _BesuchDetailScreenState();
}

class _BesuchDetailScreenState extends State<BesuchDetailScreen> {
  Besuch? _besuch;
  List<Reaktion> _reactions = [];
  List<Kommentar> _comments = [];
  bool _loading = true;
  final _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      _besuch = await BesuchService.getById(widget.besuchId);
      _reactions = await BesuchService.getReactions(widget.besuchId);
      _comments = await BesuchService.getComments(widget.besuchId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler: $e')),
        );
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _addReaction(String emoji) async {
    try {
      await BesuchService.addReaction(
        besuchId: widget.besuchId,
        userId: AuthService.currentUser!.id,
        emoji: emoji,
      );
      _reactions = await BesuchService.getReactions(widget.besuchId);
      if (mounted) setState(() {});
    } catch (e) {
      // Silently handle - reaction tables may not exist yet
    }
  }

  Future<void> _addComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;
    try {
      await BesuchService.addComment(
        besuchId: widget.besuchId,
        userId: AuthService.currentUser!.id,
        text: text,
      );
      _commentController.clear();
      _comments = await BesuchService.getComments(widget.besuchId);
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Besuch')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final besuch = _besuch;
    if (besuch == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Besuch')),
        body: const Center(child: Text('Besuch nicht gefunden')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(besuch.pommesbude?.name ?? 'Besuch'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photo
            if (besuch.linkToPicture != null)
              Image.network(
                besuch.linkToPicture!,
                height: 250,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, e, s) => const SizedBox.shrink(),
              ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User info
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: PommesTheme.lightPurple,
                        backgroundImage: besuch.user?.profileImage != null
                            ? NetworkImage(besuch.user!.profileImage!)
                            : null,
                        child: besuch.user?.profileImage == null
                            ? Text(besuch.user?.initials ?? '?',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold))
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              besuch.user?.displayName ?? 'Unbekannt',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            Text(
                              DateFormat('dd.MM.yyyy HH:mm')
                                  .format(besuch.createdAt),
                              style: const TextStyle(
                                  color: Colors.white54, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Bude name
                  if (besuch.pommesbude != null)
                    Row(
                      children: [
                        const Text('🍟 ', style: TextStyle(fontSize: 22)),
                        Text(
                          besuch.pommesbude!.name,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: PommesTheme.pommesYellow,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 16),

                  // Ratings
                  const Text('Bewertungen',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  RatingBar(
                      label: 'Gesamt',
                      value: besuch.overallRating ?? 0,
                      readOnly: true),
                  const SizedBox(height: 4),
                  RatingBar(
                      label: 'Service',
                      value: besuch.serviceRating ?? 0,
                      readOnly: true),
                  const SizedBox(height: 4),
                  RatingBar(
                      label: 'Wartezeit',
                      value: besuch.waitingTimeRating ?? 0,
                      readOnly: true),
                  const SizedBox(height: 4),
                  RatingBar(
                      label: 'Ambiente',
                      value: besuch.ambientRating ?? 0,
                      readOnly: true),

                  // Price & visitors
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      if (besuch.price != null) ...[
                        Chip(
                          avatar: const Icon(Icons.euro, size: 16),
                          label: Text('${besuch.price!.toStringAsFixed(2)} €'),
                        ),
                        const SizedBox(width: 8),
                      ],
                      if (besuch.countVisitors != null)
                        Chip(
                          avatar: const Icon(Icons.people, size: 16),
                          label: Text('${besuch.countVisitors} Besucher'),
                        ),
                    ],
                  ),

                  // Review text
                  if (besuch.review != null &&
                      besuch.review!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text('Bewertung',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: PommesTheme.cardDark,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        besuch.review!,
                        style: const TextStyle(fontSize: 15, height: 1.5),
                      ),
                    ),
                  ],

                  // Reactions
                  const SizedBox(height: 24),
                  const Text('Reaktionen',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),

                  // Emoji picker
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: AppConstants.reactionEmojis.map((emoji) {
                      final count = _reactions
                          .where((r) => r.emoji == emoji)
                          .length;
                      final myReaction = _reactions.any((r) =>
                          r.emoji == emoji &&
                          r.userId == AuthService.currentUser?.id);
                      return ActionChip(
                        label: Text('$emoji ${count > 0 ? count : ''}'),
                        backgroundColor: myReaction
                            ? PommesTheme.pommesYellow
                            : PommesTheme.cardDark,
                        onPressed: () => _addReaction(emoji),
                      );
                    }).toList(),
                  ),

                  // Comments
                  const SizedBox(height: 24),
                  Text('Kommentare (${_comments.length})',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),

                  // Comment input
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _commentController,
                          decoration: const InputDecoration(
                            hintText: 'Kommentar schreiben...',
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                          ),
                          onFieldSubmitted: (_) => _addComment(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: _addComment,
                        icon: const Icon(Icons.send),
                        color: PommesTheme.pommesYellow,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Comment list
                  ..._comments.map((comment) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: PommesTheme.cardDark,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 14,
                                    backgroundColor: PommesTheme.lightPurple,
                                    child: Text(
                                      comment.user?.initials ?? '?',
                                      style: const TextStyle(
                                          fontSize: 10, color: Colors.white),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    comment.user?.displayName ?? 'Unbekannt',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13),
                                  ),
                                  const Spacer(),
                                  Text(
                                    DateFormat('dd.MM. HH:mm')
                                        .format(comment.createdAt),
                                    style: const TextStyle(
                                        color: Colors.white38, fontSize: 11),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(comment.text),
                            ],
                          ),
                        ),
                      )),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
