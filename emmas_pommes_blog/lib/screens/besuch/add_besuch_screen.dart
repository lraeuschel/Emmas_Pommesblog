import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../config/theme.dart';
import '../../models/pommesbude.dart';
import '../../services/auth_service.dart';
import '../../services/besuch_service.dart';
import '../../widgets/rating_bar.dart';

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

  Uint8List? _imageBytes;
  String? _imageName;
  bool _loading = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _imageBytes = bytes;
        _imageName = picked.name;
      });
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
      String? imageUrl;
      if (_imageBytes != null && _imageName != null) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        imageUrl = await BesuchService.uploadImage(
          '${timestamp}_$_imageName',
          _imageBytes!,
        );
      }

      await BesuchService.create(
        location: widget.bude.id,
        userId: AuthService.currentUser!.id,
        price: _priceController.text.isNotEmpty
            ? double.tryParse(_priceController.text.replaceAll(',', '.'))
            : null,
        linkToPicture: imageUrl,
        review: _reviewController.text.trim().isNotEmpty
            ? _reviewController.text.trim()
            : null,
        countVisitors: int.tryParse(_visitorsController.text),
        overallRating: _overallRating,
        serviceRating: _serviceRating > 0 ? _serviceRating : null,
        waitingTimeRating: _waitingTimeRating > 0 ? _waitingTimeRating : null,
        ambientRating: _ambientRating > 0 ? _ambientRating : null,
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

                // Photo
                const Text('Foto',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                if (_imageBytes != null)
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.memory(
                          _imageBytes!,
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: IconButton(
                          onPressed: () => setState(() {
                            _imageBytes = null;
                            _imageName = null;
                          }),
                          icon: const Icon(Icons.close, color: Colors.white),
                          style: IconButton.styleFrom(
                              backgroundColor: Colors.black54),
                        ),
                      ),
                    ],
                  )
                else
                  GestureDetector(
                    onTap: _pickImage,
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
                          Text('Foto hinzufügen',
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
