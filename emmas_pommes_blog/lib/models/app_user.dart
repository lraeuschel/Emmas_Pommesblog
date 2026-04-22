class AppUser {
  final String id;
  final DateTime createdAt;
  final String firstName;
  final String lastName;
  final String username;
  final String? secret;
  final String? profileImage;

  AppUser({
    required this.id,
    required this.createdAt,
    required this.firstName,
    required this.lastName,
    required this.username,
    this.secret,
    this.profileImage,
  });

  String get displayName => '$firstName $lastName';
  String get initials =>
      '${firstName.isNotEmpty ? firstName[0] : ''}${lastName.isNotEmpty ? lastName[0] : ''}'
          .toUpperCase();

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'].toString(),
      createdAt: DateTime.parse(json['created_at']),
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      username: json['username'] ?? '',
      secret: json['secret'],
      profileImage: json['profile_image'],
    );
  }

  Map<String, dynamic> toJson() => {
        'first_name': firstName,
        'last_name': lastName,
        'username': username,
        'secret': secret,
        'profile_image': profileImage,
      };
}
