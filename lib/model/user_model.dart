class User {
  final String name;
  final String username;
  final String imageUrl;
  final List<String> favorites; // List of favorite items (e.g., crop names)
  final String location;
  final List<String> savedTips; // List of saved tips
  final String role;

  User({
    required this.name,
    required this.username,
    required this.imageUrl,
    required this.favorites,
    required this.location,
    required this.savedTips,
    required this.role,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      name: json['name'],
      username: json['username'],
      imageUrl: json['imageUrl'],
      favorites: List<String>.from(json['favorites']),
      location: json['location'],
      savedTips: List<String>.from(json['savedTips']),
      role: json['role'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'username': username,
      'imageUrl': imageUrl,
      'favorites': favorites,
      'location': location,
      'savedTips': savedTips,
      'role': role,
    };
  }
}