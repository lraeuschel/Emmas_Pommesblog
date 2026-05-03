class AppConstants {
  static const String appName = "Emma's Pommesblog";
  static const String tablePommesbude = 'pommesbude';
  static const String tableVisit = 'visit';
  static const String tableUser = 'user';

  // Storage buckets
  static const String bucketPommesbude = 'pommesbude_image'; // public
  static const String bucketProfile = 'profile_images';       // private
  static const String bucketEssen = 'essen_image';            // private

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
}
