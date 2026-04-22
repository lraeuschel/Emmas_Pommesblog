import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/theme.dart';
import 'services/auth_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');

  await Supabase.initialize(
    url: dotenv.env['PROJECT_URL']!,
    anonKey: dotenv.env['PUBLISHABLE_KEY']!,
  );

  await AuthService.init();

  runApp(const PommesBlogApp());
}

class PommesBlogApp extends StatelessWidget {
  const PommesBlogApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Emma's Pommesblog",
      debugShowCheckedModeBanner: false,
      theme: PommesTheme.darkTheme,
      home: AuthService.isLoggedIn ? const HomeScreen() : const LoginScreen(),
    );
  }
}
