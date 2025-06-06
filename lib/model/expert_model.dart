class Expert {
  final int id;
  final String name;
  final String specialty;
  final String imageUrl;
  final List<String>? tips; // Optional tips for "View Tips & Advice"

  Expert({
    required this.id,
    required this.name,
    required this.specialty,
    required this.imageUrl,
    this.tips,
  });

  factory Expert.fromJson(Map<String, dynamic> json) {
    return Expert(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      specialty: json['specialty'] ?? '',
      imageUrl: json['imageUrl'] ?? json['image_url'] ?? '',
      tips: json['tips'] != null 
          ? List<String>.from(json['tips'].map((tip) => tip?.toString() ?? ''))
          : null,
    );
  }
}