class AppConstants {
  static const String appName = "Emma's Pommesblog";
  static const String tablePommesbude = 'Pommesbude';
  static const String tableBesuch = 'Besuch';
  static const String tableUser = 'user';
  static const String tableReaktion = 'reaktion';
  static const String tableKommentar = 'kommentar';
  static const String storageBucket = 'images';

  // Default map center (Germany)
  static const double defaultLat = 51.9607;
  static const double defaultLon = 7.6261;
  static const double defaultZoom = 13.0;

  // Rating categories
  static const List<String> ratingCategories = [
    'Gesamt',
    'Service',
    'Wartezeit',
    'Ambiente',
  ];

  // Available reaction emojis
  static const List<String> reactionEmojis = [
    '🍟',
    '❤️',
    '👍',
    '🔥',
    '😋',
    '⭐',
    '🤤',
    '💯',
  ];
}
