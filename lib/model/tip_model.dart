import 'user_model.dart';
import 'tip_category_model.dart';

class Tip {
  final int id;
  final int userId;
  final int categoryId;
  final String title;
  final String slug;
  final String content;
  final bool isFeatured;
  final int viewsCount;
  final int likesCount;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int likedByCount;
  final int savedByCount;
  final TipCategory category;
  final User user;
  final bool? isLiked;
  final bool? isSaved;

  Tip({
    required this.id,
    required this.userId,
    required this.categoryId,
    required this.title,
    required this.slug,
    required this.content,
    required this.isFeatured,
    required this.viewsCount,
    required this.likesCount,
    required this.tags,
    required this.createdAt,
    required this.updatedAt,
    required this.likedByCount,
    required this.savedByCount,
    required this.category,
    required this.user,
    this.isLiked,
    this.isSaved,
  });

  factory Tip.fromJson(Map<String, dynamic> json) {
    return Tip(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      categoryId: json['category_id'] ?? 0,
      title: json['title'] ?? '',
      slug: json['slug'] ?? '',
      content: json['content'] ?? '',
      isFeatured: json['is_featured'] ?? false,
      viewsCount: json['views_count'] ?? 0,
      likesCount: json['likes_count'] ?? 0,
      tags: (json['tags'] as List?)?.map((tag) => tag.toString()).toList() ?? [],
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
      likedByCount: json['liked_by_count'] ?? 0,
      savedByCount: json['saved_by_count'] ?? 0,
      category: TipCategory.fromJson(json['category'] ?? {}),
      user: User.fromJson(json['user'] ?? {}),
      isLiked: json['is_liked'],
      isSaved: json['is_saved'],
    );
  }
}