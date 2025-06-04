class Expert {
  final String name;
  final String specialty;
  final String imageUrl;
  final List<String>? tips; // Optional tips for "View Tips & Advice"

  Expert({
    required this.name,
    required this.specialty,
    required this.imageUrl,
    this.tips,
  });

  factory Expert.fromJson(Map<String, dynamic> json) {
    return Expert(
      name: json['name'],
      specialty: json['specialty'],
      imageUrl: json['imageUrl'],
      tips: json['tips'] != null ? List<String>.from(json['tips']) : null,
    );
  }
}