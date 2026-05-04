import 'package:flutter/material.dart';
import '../../config/theme.dart';

class ImpressumScreen extends StatelessWidget {
  const ImpressumScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Impressum & Info'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(
                  child: Text('🍟', style: TextStyle(fontSize: 64)),
                ),
                const SizedBox(height: 16),
                const Center(
                  child: Text(
                    "Emma's Pommesblog",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: PommesTheme.pommesYellow,
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                _sectionTitle('Was ist diese App?'),
                const SizedBox(height: 8),
                const Text(
                  "Emma's Pommesblog ist eine App für alle Pommes-Liebhaber! "
                  'Hier könnt ihr eure liebsten Pommesbuden entdecken, bewerten '
                  'und mit Freunden teilen. Tragt eure Besuche ein, bewertet die '
                  'Pommes und schaut, welche Bude die beste der Stadt ist.',
                  style: TextStyle(color: Colors.white70, fontSize: 15, height: 1.5),
                ),
                const SizedBox(height: 24),

                _sectionTitle('Features'),
                const SizedBox(height: 8),
                _featureItem(Icons.map, 'Interaktive Karte',
                    'Entdecke Pommesbuden in deiner Nähe'),
                _featureItem(Icons.star, 'Bewertungssystem',
                    'Bewerte Pommesbuden nach verschiedenen Kategorien'),
                _featureItem(Icons.photo_camera, 'Foto-Upload',
                    'Teile Bilder von deinem Essen und den Buden'),
                _featureItem(Icons.emoji_events, 'Rangliste',
                    'Schau, welche Bude die meisten Besuche hat'),
                _featureItem(Icons.newspaper, 'News-Feed',
                    'Bleib auf dem Laufenden, wer wo Pommes essen war'),
                _featureItem(Icons.lock_open, 'Geheimnisse',
                    'Jeden Sonntag wird ein Geheimnis gelüftet...'),
                const SizedBox(height: 24),

                _sectionTitle('Über uns'),
                const SizedBox(height: 8),
                const Text(
                  'Diese App wurde mit viel Liebe (und Pommes) entwickelt. '
                  'Sie ist ein Spaßprojekt unter Freunden und nicht kommerziell.',
                  style: TextStyle(color: Colors.white70, fontSize: 15, height: 1.5),
                ),
                const SizedBox(height: 24),

                _sectionTitle('Technologie'),
                const SizedBox(height: 8),
                const Text(
                  'Entwickelt mit Flutter & Supabase.\n'
                  'Kartendaten: © OpenStreetMap contributors\n'
                  'Kartenstil: © CARTO',
                  style: TextStyle(color: Colors.white54, fontSize: 13, height: 1.5),
                ),
                const SizedBox(height: 48),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: PommesTheme.pommesYellow,
      ),
    );
  }

  static Widget _featureItem(IconData icon, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: PommesTheme.pommesYellow, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15)),
                Text(desc,
                    style: const TextStyle(
                        color: Colors.white54, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
