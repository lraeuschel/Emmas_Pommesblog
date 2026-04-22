import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/pommesbude_service.dart';

class AddBudeDialog extends StatefulWidget {
  final double lat;
  final double lon;

  const AddBudeDialog({super.key, required this.lat, required this.lon});

  @override
  State<AddBudeDialog> createState() => _AddBudeDialogState();
}

class _AddBudeDialogState extends State<AddBudeDialog> {
  final _nameController = TextEditingController();
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
    if (_nameController.text.trim().isEmpty) return;
    setState(() => _loading = true);
    try {
      String? photoUrl;
      if (_imageBytes != null && _imageName != null) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        photoUrl = await PommesbudeService.uploadImage(
          '${timestamp}_$_imageName',
          _imageBytes!,
        );
      }

      await PommesbudeService.create(
        lat: widget.lat,
        lon: widget.lon,
        name: _nameController.text.trim(),
        linkToPhoto: photoUrl,
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
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Text('🍟 ', style: TextStyle(fontSize: 24)),
          Text('Neue Pommesbude'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Position: ${widget.lat.toStringAsFixed(4)}, ${widget.lon.toStringAsFixed(4)}',
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name der Pommesbude',
                prefixIcon: Icon(Icons.store),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            if (_imageBytes != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(
                  _imageBytes!,
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.photo_camera),
              label: Text(_imageBytes != null ? 'Foto ändern' : 'Foto hinzufügen'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Abbrechen'),
        ),
        ElevatedButton(
          onPressed: _loading ? null : _save,
          child: _loading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Speichern'),
        ),
      ],
    );
  }
}
