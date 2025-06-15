class User {
  final String name;
  final String username;
  final String email;
  final String imageUrl;
  final List<String> favorites; // List of favorite items (e.g., crop names)
  final String location;
  final List<String> savedTips; // List of saved tips
  final String role;
  final String? phoneNumber;

  User({
    required this.name,
    required this.username,
    required this.email,
    required this.imageUrl,
    required this.favorites,
    required this.location,
    required this.savedTips,
    required this.role,
    this.phoneNumber,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    try {
      print('Parsing user JSON: $json');
      return User(
        name: json['name']?.toString() ?? '',
        username: json['username']?.toString() ?? '',
        email: json['email']?.toString() ?? '',
        imageUrl: json['imageUrl']?.toString() ?? json['image_url']?.toString() ?? '',
        favorites: _parseListField(json['favorites']),
        location: json['location']?.toString() ?? '',
        savedTips: _parseListField(json['savedTips'] ?? json['saved_tips']),
        role: json['role']?.toString() ?? '',
        phoneNumber: json['phoneNumber']?.toString() ?? json['phone_number']?.toString(),
      );
    } catch (e) {
      print('Error parsing user JSON: $e');
      print('User JSON data: $json');
      rethrow;
    }
  }

  static List<String> _parseListField(dynamic field) {
    if (field == null) return [];
    if (field is List) {
      return field.map((e) => e?.toString() ?? '').toList();
    }
    return [];
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
      'phoneNumber': phoneNumber,
    };
  }
}