class TipCategory {
  final int id;
  final String name;
  final String slug;
  final String description;
  final String icon;
  final int tipsCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  TipCategory({
    required this.id,
    required this.name,
    required this.slug,
    required this.description,
    required this.icon,
    required this.tipsCount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TipCategory.fromJson(Map<String, dynamic> json) {
    return TipCategory(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      description: json['description'] ?? '',
      icon: json['icon'] ?? '',
      tipsCount: json['tips_count'] ?? 0,
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }
} 