class Expert {
  final int id;
  final String name;
  final String? username;
  final String email;
  final String? phoneNumber;
  final String? imageUrl;
  final String? location;
  final String role;
  final List<String>? favorites;
  final List<String>? savedTips;
  final String? emailVerifiedAt;
  final String? createdAt;
  final String? updatedAt;

  Expert({
    required this.id,
    required this.name,
    this.username,
    required this.email,
    this.phoneNumber,
    this.imageUrl,
    this.location,
    required this.role,
    this.favorites,
    this.savedTips,
    this.emailVerifiedAt,
    this.createdAt,
    this.updatedAt,
  });

  factory Expert.fromJson(Map<String, dynamic> json) {
    return Expert(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      username: json['username']?.toString(),
      email: json['email'] ?? '',
      phoneNumber: json['phone_number']?.toString(),
      imageUrl: json['image_url']?.toString(),
      location: json['location']?.toString(),
      role: json['role'] ?? '',
      favorites: json['favorites'] != null 
          ? List<String>.from(json['favorites'].map((item) => item?.toString() ?? ''))
          : null,
      savedTips: json['saved_tips'] != null 
          ? List<String>.from(json['saved_tips'].map((tip) => tip?.toString() ?? ''))
          : null,
      emailVerifiedAt: json['email_verified_at']?.toString(),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }

  // Getter for specialty - since API doesn't provide it, we'll use role or a default
  String get specialty {
    return role == 'expert' ? 'Agricultural Expert' : 'Specialist';
  }
}