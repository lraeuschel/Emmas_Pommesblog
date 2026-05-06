import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/auth_service.dart';
import '../home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _secretController = TextEditingController();
  bool _loading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _passwordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    _secretController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await AuthService.register(
        password: _passwordController.text,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        username: _usernameController.text.trim(),
        secret: _secretController.text.trim().isNotEmpty
            ? _secretController.text.trim()
            : null,
      );
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registrieren')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Image.asset(
                      'assets/logo_text.jpg',
                      height: 300,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Erstelle dein Konto und starte dein Pommes-Abenteuer!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white54),
                    ),
                    const SizedBox(height: 32),

                    // Username
                    TextFormField(
                      controller: _usernameController,
                      decoration: const InputDecoration(
                        labelText: 'Benutzername',
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Bitte eingeben';
                        }
                        if (v.trim().length < 3) {
                          return 'Mindestens 3 Zeichen';
                        }
                        return null;
                      },
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),

                    // Password
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: 'Passwort',
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility),
                          onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      obscureText: _obscurePassword,
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return 'Bitte eingeben';
                        }
                        if (v.length < 6) {
                          return 'Mindestens 6 Zeichen';
                        }
                        return null;
                      },
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),

                    // First name
                    TextFormField(
                      controller: _firstNameController,
                      decoration: const InputDecoration(
                        labelText: 'Vorname',
                        prefixIcon: Icon(Icons.badge),
                      ),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Bitte eingeben' : null,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),

                    // Last name
                    TextFormField(
                      controller: _lastNameController,
                      decoration: const InputDecoration(
                        labelText: 'Nachname',
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Bitte eingeben' : null,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),

                    // Secret (fun personal fact)
                    TextFormField(
                      controller: _secretController,
                      decoration: InputDecoration(
                        labelText: 'Mein Geheimnis 🤫',
                        prefixIcon: const Icon(Icons.lock_open),
                        hintText: 'Etwas Geheimes über dich...',
                        suffixIcon: Tooltip(
                          message: 'Soo, hier müsst ihr jetzt ein Geheimnis über euch eintragen hahaha!\n'
                              'Jeden Sonntag wird zufällig ein Geheimnis\n'
                              'aus der Gruppe enthüllt - natürlich anonym also haut was raus.\n' 
                              'Aber nur, wenn ihr in der Woche davor mindestens einmal Pommes essen wart!',
                          triggerMode: TooltipTriggerMode.tap,
                          showDuration: const Duration(seconds: 5),
                          child: const Icon(Icons.help_outline, size: 20),
                        ),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 32),

                    // Register button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _register,
                        child: _loading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Registrieren'),
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text(
                        'Bereits ein Konto? Anmelden',
                        style: TextStyle(color: PommesTheme.pommesYellow),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
