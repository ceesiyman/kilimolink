class User {
  final String name;
  final String username;
  final String email;
  final String imageUrl;
  final List<String> favorites; // List of favorite items (e.g., crop names)
  final String location;
  final List<String> savedTips; // List of saved tips
  final String role;

  User({
    required this.name,
    required this.username,
    required this.email,
    required this.imageUrl,
    required this.favorites,
    required this.location,
    required this.savedTips,
    required this.role,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      name: json['name'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      favorites: (json['favorites'] as List?)?.map((e) => e?.toString() ?? '').toList() ?? [],
      location: json['location'] ?? '',
      savedTips: (json['savedTips'] ?? json['saved_tips'] as List?)?.map((e) => e?.toString() ?? '').toList() ?? [],
      role: json['role'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'username': username,
      'email': email,
      'imageUrl': imageUrl,
      'favorites': favorites,
      'location': location,
      'savedTips': savedTips,
      'role': role,
    };
  }
}