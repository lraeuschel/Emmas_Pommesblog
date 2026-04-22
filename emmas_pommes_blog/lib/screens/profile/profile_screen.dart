import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _editing = false;
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _secretController = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final user = AuthService.currentUser;
    if (user != null) {
      _firstNameController.text = user.firstName;
      _lastNameController.text = user.lastName;
      _secretController.text = user.secret ?? '';
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await AuthService.updateProfile(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        secret: _secretController.text.trim().isNotEmpty
            ? _secretController.text.trim()
            : null,
      );
      if (mounted) {
        setState(() => _editing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil gespeichert')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _logout() async {
    await AuthService.logout();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _secretController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        actions: [
          if (!_editing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _editing = true),
            ),
        ],
      ),
      body: user == null
          ? const Center(child: Text('Nicht angemeldet'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      // Avatar
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: PommesTheme.lightPurple,
                        backgroundImage: user.profileImage != null
                            ? NetworkImage(user.profileImage!)
                            : null,
                        child: user.profileImage == null
                            ? Text(
                                user.initials,
                                style: const TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '@${user.username}',
                        style: const TextStyle(
                          color: PommesTheme.pommesYellow,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Mitglied seit ${user.createdAt.day}.${user.createdAt.month}.${user.createdAt.year}',
                        style:
                            const TextStyle(color: Colors.white38, fontSize: 13),
                      ),
                      const SizedBox(height: 32),

                      if (_editing) ...[
                        TextFormField(
                          controller: _firstNameController,
                          decoration: const InputDecoration(
                            labelText: 'Vorname',
                            prefixIcon: Icon(Icons.badge),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _lastNameController,
                          decoration: const InputDecoration(
                            labelText: 'Nachname',
                            prefixIcon: Icon(Icons.badge_outlined),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _secretController,
                          decoration: const InputDecoration(
                            labelText: 'Mein Geheimnis 🤫',
                            prefixIcon: Icon(Icons.lock_open),
                            hintText: 'Etwas Geheimes über dich...',
                          ),
                          maxLines: 2,
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  setState(() => _editing = false);
                                  _firstNameController.text = user.firstName;
                                  _lastNameController.text = user.lastName;
                                  _secretController.text = user.secret ?? '';
                                },
                                child: const Text('Abbrechen'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _saving ? null : _save,
                                child: _saving
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2),
                                      )
                                    : const Text('Speichern'),
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              children: [
                                _profileRow(Icons.person, 'Name',
                                    user.displayName),
                                const Divider(color: Colors.white12),
                                _profileRow(Icons.alternate_email,
                                    'Benutzername', user.username),
                                if (user.secret != null &&
                                    user.secret!.isNotEmpty) ...[
                                  const Divider(color: Colors.white12),
                                  _profileRow(Icons.lock_open,
                                      'Mein Geheimnis 🤫', user.secret!),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 48),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _logout,
                          icon: const Icon(Icons.logout, color: Colors.redAccent),
                          label: const Text('Abmelden',
                              style: TextStyle(color: Colors.redAccent)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.redAccent),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _profileRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: PommesTheme.pommesYellow, size: 20),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style:
                      const TextStyle(color: Colors.white38, fontSize: 12)),
              Text(value,
                  style: const TextStyle(fontSize: 16)),
            ],
          ),
        ],
      ),
    );
  }
}
