import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../config/theme.dart';
import '../../models/app_user.dart';
import '../../models/pommesbude.dart';
import '../../services/auth_service.dart';
import '../../services/besuch_service.dart';
import '../../widgets/rating_bar.dart';
import '../../widgets/user_avatar.dart';

class AddBesuchScreen extends StatefulWidget {
  final Pommesbude bude;

  const AddBesuchScreen({super.key, required this.bude});

  @override
  State<AddBesuchScreen> createState() => _AddBesuchScreenState();
}

class _AddBesuchScreenState extends State<AddBesuchScreen> {
  final _formKey = GlobalKey<FormState>();
  final _priceController = TextEditingController();
  final _reviewController = TextEditingController();
  final _visitorsController = TextEditingController(text: '1');

  double _overallRating = 0;
  double _serviceRating = 0;
  double _waitingTimeRating = 0;
  double _ambientRating = 0;

  final List<({String name, Uint8List bytes})> _images = [];
  final List<AppUser> _taggedUsers = [];
  bool _loading = false;

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage();
    for (final xfile in picked) {
      final bytes = await xfile.readAsBytes();
      setState(() => _images.add((name: xfile.name, bytes: bytes)));
    }
  }

  Future<void> _showTagDialog() async {
    final currentUserId = AuthService.currentUser?.id;
    List<AppUser>? allUsers;
    try {
      allUsers = await BesuchService.getAllUsers();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fehler beim Laden der User')),
        );
      }
      return;
    }

    // Filter: eigenen User und bereits getaggte raus
    final available = allUsers
        .where((u) =>
            u.id != currentUserId &&
            !_taggedUsers.any((t) => t.id == u.id))
        .toList();

    if (!mounted) return;

    final selected = await showDialog<AppUser>(
      context: context,
      builder: (context) {
        String search = '';
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final filtered = available
                .where((u) =>
                    u.displayName.toLowerCase().contains(search.toLowerCase()) ||
                    u.username.toLowerCase().contains(search.toLowerCase()))
                .toList();
            return AlertDialog(
              title: const Text('Freund auswählen'),
              content: SizedBox(
                width: double.maxFinite,
                height: 350,
                child: Column(
                  children: [
                    TextField(
                      decoration: const InputDecoration(
                        hintText: 'Suchen...',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (v) => setDialogState(() => search = v),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: filtered.isEmpty
                          ? const Center(
                              child: Text('Keine User gefunden',
                                  style: TextStyle(color: Colors.white54)))
                          : ListView.builder(
                              itemCount: filtered.length,
                              itemBuilder: (context, i) {
                                final user = filtered[i];
                                return ListTile(
                                  leading: UserAvatar(user: user, radius: 18),
                                  title: Text(user.displayName),
                                  subtitle: Text('@${user.username}',
                                      style: const TextStyle(
                                          color: Colors.white54, fontSize: 12)),
                                  onTap: () =>
                                      Navigator.of(context).pop(user),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Abbrechen'),
                ),
              ],
            );
          },
        );
      },
    );

    if (selected != null) {
      setState(() => _taggedUsers.add(selected));
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_overallRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte eine Gesamtbewertung abgeben')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final userId = AuthService.currentUser!.id;

      // Bilder hochladen
      if (_images.isNotEmpty) {
        await BesuchService.uploadImages(
          userId: userId,
          location: widget.bude.id,
          files: _images,
        );
      }

      final besuch = await BesuchService.create(
        location: widget.bude.id,
        userId: userId,
        price: _priceController.text.isNotEmpty
            ? double.tryParse(_priceController.text.replaceAll(',', '.'))
            : null,
        review: _reviewController.text.trim().isNotEmpty
            ? _reviewController.text.trim()
            : null,
        countVisitors: int.tryParse(_visitorsController.text),
        overallRating: _overallRating,
        serviceRating: _serviceRating > 0 ? _serviceRating : null,
        waitingTimeRating: _waitingTimeRating > 0 ? _waitingTimeRating : null,
        ambientRating: _ambientRating > 0 ? _ambientRating : null,
        taggedUserIds: _taggedUsers.map((u) => u.id).toList(),
      );

      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _priceController.dispose();
    _reviewController.dispose();
    _visitorsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Besuch eintragen'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Bude info
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Text('🍟', style: TextStyle(fontSize: 32)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.bude.name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: PommesTheme.pommesYellow,
                                ),
                              ),
                              Text(
                                '${widget.bude.lat.toStringAsFixed(4)}, ${widget.bude.lon.toStringAsFixed(4)}',
                                style: const TextStyle(
                                    color: Colors.white54, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Photos (multiple)
                const Text('Fotos',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                if (_images.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ..._images.asMap().entries.map((entry) => Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.memory(
                                  entry.value.bytes,
                                  height: 120,
                                  width: 120,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: GestureDetector(
                                  onTap: () => setState(
                                      () => _images.removeAt(entry.key)),
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: const BoxDecoration(
                                      color: Colors.black54,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.close,
                                        color: Colors.white, size: 16),
                                  ),
                                ),
                              ),
                            ],
                          )),
                      GestureDetector(
                        onTap: _pickImages,
                        child: Container(
                          height: 120,
                          width: 120,
                          decoration: BoxDecoration(
                            color: PommesTheme.surfaceDark,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: const Icon(Icons.add_photo_alternate,
                              size: 32, color: Colors.white38),
                        ),
                      ),
                    ],
                  )
                else
                  GestureDetector(
                    onTap: _pickImages,
                    child: Container(
                      height: 150,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: PommesTheme.surfaceDark,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo,
                              size: 40, color: Colors.white38),
                          SizedBox(height: 8),
                          Text('Fotos hinzufügen',
                              style: TextStyle(color: Colors.white38)),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 24),

                // Ratings
                const Text('Bewertungen *',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                RatingBar(
                  label: 'Gesamt *',
                  value: _overallRating,
                  onChanged: (v) => setState(() => _overallRating = v),
                ),
                const SizedBox(height: 12),
                RatingBar(
                  label: 'Service',
                  value: _serviceRating,
                  onChanged: (v) => setState(() => _serviceRating = v),
                ),
                const SizedBox(height: 12),
                RatingBar(
                  label: 'Wartezeit',
                  value: _waitingTimeRating,
                  onChanged: (v) => setState(() => _waitingTimeRating = v),
                ),
                const SizedBox(height: 12),
                RatingBar(
                  label: 'Ambiente',
                  value: _ambientRating,
                  onChanged: (v) => setState(() => _ambientRating = v),
                ),
                const SizedBox(height: 24),

                // Price
                TextFormField(
                  controller: _priceController,
                  decoration: const InputDecoration(
                    labelText: 'Preis (€)',
                    prefixIcon: Icon(Icons.euro),
                    hintText: 'z.B. 4.50',
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value == null || value.isEmpty) return null;
                    final parsed = double.tryParse(value.replaceAll(',', '.'));
                    if (parsed == null || parsed < 0) {
                      return 'Bitte eine gültige Zahl eingeben';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Visitors
                TextFormField(
                  controller: _visitorsController,
                  decoration: const InputDecoration(
                    labelText: 'Anzahl Besucher',
                    prefixIcon: Icon(Icons.people),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 24),

                // Tag users
                const Text('Freunde taggen',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ..._taggedUsers.map((user) => Chip(
                          avatar: UserAvatar(user: user, radius: 12),
                          label: Text(user.displayName),
                          deleteIcon:
                              const Icon(Icons.close, size: 16),
                          onDeleted: () => setState(
                              () => _taggedUsers.remove(user)),
                        )),
                    ActionChip(
                      avatar: const Icon(Icons.person_add, size: 18),
                      label: const Text('Freund hinzufügen'),
                      onPressed: _showTagDialog,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Review
                TextFormField(
                  controller: _reviewController,
                  decoration: const InputDecoration(
                    labelText: 'Bewertungstext',
                    prefixIcon: Icon(Icons.rate_review),
                    hintText: 'Wie war dein Besuch?',
                    alignLabelWithHint: true,
                  ),
                  maxLines: 4,
                ),
                const SizedBox(height: 32),

                // Submit
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _loading ? null : _save,
                    icon: _loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save),
                    label: const Text('Besuch speichern'),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
