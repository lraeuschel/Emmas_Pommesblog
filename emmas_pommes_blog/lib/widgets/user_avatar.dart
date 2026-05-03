import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../models/app_user.dart';
import '../services/image_service.dart';

/// Avatar-Widget das automatisch signed URLs für private Profilbilder auflöst.
class UserAvatar extends StatefulWidget {
  final AppUser? user;
  final double radius;

  const UserAvatar({super.key, this.user, this.radius = 20});

  @override
  State<UserAvatar> createState() => _UserAvatarState();
}

class _UserAvatarState extends State<UserAvatar> {
  String? _imageUrl;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(UserAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user?.profileImage != widget.user?.profileImage) {
      _imageUrl = null;
      _loadImage();
    }
  }

  Future<void> _loadImage() async {
    final path = widget.user?.profileImage;
    if (path == null || path.isEmpty) return;
    // Wenn es schon eine URL ist (z.B. public), direkt nutzen
    if (path.startsWith('http')) {
      if (mounted) setState(() => _imageUrl = path);
      return;
    }
    final url = await ImageService.getProfileImageUrl(path);
    if (mounted && url != null) setState(() => _imageUrl = url);
  }

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: widget.radius,
      backgroundColor: PommesTheme.lightPurple,
      backgroundImage: _imageUrl != null ? NetworkImage(_imageUrl!) : null,
      child: _imageUrl == null
          ? Text(
              widget.user?.initials ?? '?',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: widget.radius * 0.7,
              ),
            )
          : null,
    );
  }
}
