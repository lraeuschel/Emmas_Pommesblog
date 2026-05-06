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
                Center(
                  child: Image.asset(
                    'assets/logo_text.jpg',
                    height: 350,
                  ),
                ),
                const SizedBox(height: 32),

                _sectionTitle('Was ist diese App?'),
                const SizedBox(height: 8),
                const Text(
                  "Emma's Pommesblog ist eine App für alle Pommes-Liebhaber! \n"
                  "Passend zu Emma's Histaminunverträglichkeit haben wir diese App entwickelt, damit wir "
                  "sie gemeinsam unterstützen können, die besten Pommesbuden Deutschlands und darüber hinaus "
                  "zu entdecken. \n"
                  'Tragt eure Besuche ein, bewertet die '
                  'Pommes und schaut, welche Bude die beste der Stadt ist.',
                  style: TextStyle(color: Colors.white70, fontSize: 15, height: 1.5),
                ),
                const SizedBox(height: 24),

                _sectionTitle('Unsere genialen Features'),
                const SizedBox(height: 8),
                _featureItem(Icons.map, 'Interaktive Karte',
                    'Entdecke Pommesbuden in deiner Nähe'),
                _featureItem(Icons.star, 'Bewertungssystem',
                    'Bewerte Pommesbuden nach verschiedenen Kategorien'),
                _featureItem(Icons.photo_camera, 'Foto-Upload',
                    'Teile Bilder von deinem Essen MIT DIR'),
                _featureItem(Icons.emoji_events, 'Rangliste',
                    'Schau, welche Bude die meisten Besuche hat'),
                _featureItem(Icons.newspaper, 'News-Feed',
                    'Bleib auf dem Laufenden, wer wo Pommes essen war'),
                _featureItem(Icons.lock_open, 'Geheimnisse',
                    'Jeden Sonntag wird ein Geheimnis gelüftet...'),
                const SizedBox(height: 24),

                _sectionTitle('Zu den Geheimnissen ...'),
                const SizedBox(height: 8),
                const Text(
                  'Bei der Registrierung musstet ihr ein geheimes Geheimnis über euch preisgeben. \n'
                  "Um euch bei Laune zu halten, wird jeden Sonntag eines dieser Geheimnisse (natürlich zufällig) "
                  "gelüftet. Es lohnt sich also, regelmäßig vorbeizuschauen! \n"
                  "Es gibt nur ein Problem: Ihr MÜSST in der Woche davor (Montag bis Sonntag) mindestens "
                  "einmal Pommes essen gewesen sein, damit ihr das Geheimnis sehen könnt. Ansonsten bleibt es für euch verborgen... \n"
                  "Also: Auf die Pommes, fertig, los!",
                  style: TextStyle(color: Colors.white70, fontSize: 15, height: 1.5),
                ),
                const SizedBox(height: 24),

                _sectionTitle('Über uns'),
                const SizedBox(height: 8),
                const Text(
                  'Diese App wurde mit viel Liebe von Lukas und Matteo (und vielleicht etwas Claude) '
                  "zu Emma's 22. Geburtstag entwickelt. "
                  'Wir freuen uns wenn sie regelmäßig genutzt wird!',
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
