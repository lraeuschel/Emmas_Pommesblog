import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../config/constants.dart';
import '../../config/theme.dart';
import '../../models/pommesbude.dart';
import '../../services/image_service.dart';
import '../../services/pommesbude_service.dart';
import '../../widgets/image_slideshow.dart';
import '../../widgets/rating_bar.dart';
import '../bude/bude_detail_screen.dart';
import 'add_bude_dialog.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  List<Pommesbude> _buden = [];
  bool _loading = true;
  bool _addMode = false;
  LatLng? _selectedPosition;
  LatLng? _currentPosition;

  @override
  void initState() {
    super.initState();
    _loadBuden();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }
      
      if (mounted) {
        final position = await Geolocator.getCurrentPosition();
        if (mounted) {
          setState(() {
            _currentPosition = LatLng(position.latitude, position.longitude);
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Standort konnte nicht abgerufen werden: $e')),
        );
      }
    }
  }

  Future<void> _loadBuden() async {
    setState(() => _loading = true);
    try {
      _buden = await PommesbudeService.getAll();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Laden: $e')),
        );
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  void _onMapTap(TapPosition tapPosition, LatLng point) {
    if (_addMode) {
      setState(() => _selectedPosition = point);
    }
  }

  Future<void> _addBude() async {
    if (_selectedPosition == null) return;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AddBudeDialog(
        lat: _selectedPosition!.latitude,
        lon: _selectedPosition!.longitude,
      ),
    );
    if (result == true) {
      setState(() {
        _addMode = false;
        _selectedPosition = null;
      });
      await _loadBuden();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_addMode ? 'Tippe auf die Karte' : 'Pommes-Karte'),
        actions: [
          if (_addMode)
            TextButton(
              onPressed: () => setState(() {
                _addMode = false;
                _selectedPosition = null;
              }),
              child: const Text('Abbrechen',
                  style: TextStyle(color: PommesTheme.pommesYellow)),
            ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: LatLng(
                AppConstants.defaultLat,
                AppConstants.defaultLon,
              ),
              initialZoom: AppConstants.defaultZoom,
              minZoom: 3,
              maxZoom: 18,
              onTap: _onMapTap,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
                userAgentPackageName: 'com.emmas.pommesblog',
              ),
              MarkerLayer(
                markers: [
                  ..._buden.map((bude) => Marker(
                        point: LatLng(bude.lat, bude.lon),
                        width: 50,
                        height: 50,
                        child: GestureDetector(
                          onTap: () => _showBudeInfo(bude),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: PommesTheme.primaryPurple,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: PommesTheme.pommesYellow, width: 2),
                                ),
                                child: const Text('🍟',
                                    style: TextStyle(fontSize: 20)),
                              ),
                            ],
                          ),
                        ),
                      )),
                  if (_currentPosition != null)
                    Marker(
                      point: _currentPosition!,
                      width: 40,
                      height: 40,
                      child: Container(
                        decoration: BoxDecoration(
                          color: PommesTheme.primaryPurple.withValues(alpha: 0.3),
                          shape: BoxShape.circle,
                          border: Border.all(color: PommesTheme.primaryPurple, width: 2),
                        ),
                        child: const Icon(
                          Icons.my_location,
                          color: PommesTheme.primaryPurple,
                          size: 20,
                        ),
                      ),
                    ),
                  if (_selectedPosition != null)
                    Marker(
                      point: _selectedPosition!,
                      width: 50,
                      height: 50,
                      child: const Icon(
                        Icons.location_pin,
                        color: Colors.red,
                        size: 40,
                      ),
                    ),
                ],
              ),
            ],
          ),
          if (_loading)
            const Center(child: CircularProgressIndicator()),
          if (_addMode)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: PommesTheme.primaryPurple.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.touch_app, color: PommesTheme.pommesYellow),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Tippe auf die Karte, um eine Pommesbude hinzuzufügen',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (_selectedPosition != null && _addMode)
            Positioned(
              bottom: 32,
              left: 32,
              right: 32,
              child: ElevatedButton.icon(
                onPressed: _addBude,
                icon: const Icon(Icons.add_location_alt),
                label: const Text('Pommesbude hier hinzufügen'),
              ),
            ),
          if (!_addMode)
            Positioned(
              right: 16,
              bottom: 16,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FloatingActionButton.small(
                    heroTag: 'zoomIn',
                    onPressed: () {
                      final z = _mapController.camera.zoom + 1;
                      _mapController.move(_mapController.camera.center, z.clamp(3, 18));
                    },
                    child: const Icon(Icons.add),
                  ),
                  const SizedBox(height: 12),
                  FloatingActionButton.small(
                    heroTag: 'zoomOut',
                    onPressed: () {
                      final z = _mapController.camera.zoom - 1;
                      _mapController.move(_mapController.camera.center, z.clamp(3, 18));
                    },
                    child: const Icon(Icons.remove),
                  ),
                  const SizedBox(height: 12),
                  if (_currentPosition != null)
                    FloatingActionButton.small(
                      heroTag: 'myLocation',
                      onPressed: () {
                        _mapController.move(_currentPosition!, 15);
                      },
                      child: const Icon(Icons.my_location),
                    ),
                  if (_currentPosition != null)
                    const SizedBox(height: 12),
                  FloatingActionButton.small(
                    heroTag: 'add',
                    onPressed: () => setState(() => _addMode = true),
                    child: const Icon(Icons.add_location_alt),
                  ),
                ],
              ),
            ),
        ],
      ),
      floatingActionButton: null,
    );
  }

  void _showBudeInfo(Pommesbude bude) {
    showModalBottomSheet(
      context: context,
      backgroundColor: PommesTheme.surfaceDark,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _BudeInfoSheet(bude: bude),
    );
  }
}

/// Bottom-Sheet das asynchron Bude- + Essensbilder lädt und als Slideshow zeigt.
class _BudeInfoSheet extends StatefulWidget {
  final Pommesbude bude;
  const _BudeInfoSheet({required this.bude});

  @override
  State<_BudeInfoSheet> createState() => _BudeInfoSheetState();
}

class _BudeInfoSheetState extends State<_BudeInfoSheet> {
  List<String> _allImages = [];
  bool _loadingImages = true;

  @override
  void initState() {
    super.initState();
    _loadImages();
  }

  Future<void> _loadImages() async {
    final budeImgs = await ImageService.getBudeImages(widget.bude.id);
    final all = <String>[];
    if (widget.bude.budenImage != null) {
      all.add(widget.bude.budenImage!);
    }
    all.addAll(budeImgs.where((u) => !all.contains(u)));
    if (mounted) setState(() { _allImages = all; _loadingImages = false; });
  }

  @override
  Widget build(BuildContext context) {
    final bude = widget.bude;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🍟', style: TextStyle(fontSize: 32)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  bude.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: PommesTheme.pommesYellow,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              RatingDisplay(rating: bude.averageRating, size: 20),
              const SizedBox(width: 16),
              Icon(Icons.restaurant, size: 18, color: Colors.white54),
              const SizedBox(width: 4),
              Text('${bude.visitCount} Besuche',
                  style: const TextStyle(color: Colors.white54)),
            ],
          ),
          const SizedBox(height: 12),
          if (_loadingImages)
            const SizedBox(
              height: 150,
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_allImages.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: ImageSlideshow(
                imageUrls: _allImages,
                height: 180,
              ),
            ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => BudeDetailScreen(bude: bude),
                  ),
                );
              },
              child: const Text('Details anzeigen'),
            ),
          ),
        ],
      ),
    );
  }
}
