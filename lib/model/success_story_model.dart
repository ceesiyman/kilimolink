import 'user_model.dart';

class SuccessStory {
  final int id;
  final int userId;
  final String title;
  final String content;
  final String? location;
  final String? cropType;
  final double? yieldImprovement;
  final String? yieldUnit;
  final bool isFeatured;
  final int viewsCount;
  final int likesCount;
  final int commentsCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final User user;
  final List<StoryImage> images;
  final List<StoryComment> comments;
  final bool? isLiked;

  SuccessStory({
    required this.id,
    required this.userId,
    required this.title,
    required this.content,
    this.location,
    this.cropType,
    this.yieldImprovement,
    this.yieldUnit,
    required this.isFeatured,
    required this.viewsCount,
    required this.likesCount,
    required this.commentsCount,
    required this.createdAt,
    required this.updatedAt,
    required this.user,
    required this.images,
    required this.comments,
    this.isLiked,
  });

  factory SuccessStory.fromJson(Map<String, dynamic> json) {
    return SuccessStory(
      id: json['id'],
      userId: json['user_id'],
      title: json['title'],
      content: json['content'],
      location: json['location'],
      cropType: json['crop_type'],
      yieldImprovement: _parseYieldImprovement(json['yield_improvement']),
      yieldUnit: json['yield_unit'],
      isFeatured: json['is_featured'] ?? false,
      viewsCount: json['views_count'] ?? 0,
      likesCount: json['likes_count'] ?? 0,
      commentsCount: json['all_comments_count'] ?? json['comments_count'] ?? 0,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      user: User.fromJson(json['user']),
      images: (json['images'] as List<dynamic>?)
          ?.map((image) => StoryImage.fromJson(image))
          .toList() ?? [],
      comments: (json['comments'] as List<dynamic>?)
          ?.map((comment) => StoryComment.fromJson(comment))
          .toList() ?? [],
      isLiked: json['is_liked'],
    );
  }

  static double? _parseYieldImprovement(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
        print('Error parsing yield_improvement string: $value');
        return null;
      }
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'content': content,
      'location': location,
      'crop_type': cropType,
      'yield_improvement': yieldImprovement,
      'yield_unit': yieldUnit,
      'is_featured': isFeatured,
      'views_count': viewsCount,
      'likes_count': likesCount,
      'comments_count': commentsCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'user': user.toJson(),
      'images': images.map((image) => image.toJson()).toList(),
      'comments': comments.map((comment) => comment.toJson()).toList(),
      'is_liked': isLiked,
    };
  }
}

class StoryImage {
  final int id;
  final int successStoryId;
  final String imagePath;
  final String? caption;
  final int order;

  StoryImage({
    required this.id,
    required this.successStoryId,
    required this.imagePath,
    this.caption,
    required this.order,
  });

  factory StoryImage.fromJson(Map<String, dynamic> json) {
    return StoryImage(
      id: json['id'],
      successStoryId: json['success_story_id'],
      imagePath: json['image_path'],
      caption: json['caption'],
      order: json['order'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'success_story_id': successStoryId,
      'image_path': imagePath,
      'caption': caption,
      'order': order,
    };
  }
}

class StoryComment {
  final int id;
  final int successStoryId;
  final int userId;
  final String comment;
  final int? parentId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final User user;
  final List<StoryComment> replies;

  StoryComment({
    required this.id,
    required this.successStoryId,
    required this.userId,
    required this.comment,
    this.parentId,
    required this.createdAt,
    required this.updatedAt,
    required this.user,
    required this.replies,
  });

  factory StoryComment.fromJson(Map<String, dynamic> json) {
    return StoryComment(
      id: json['id'],
      successStoryId: json['success_story_id'],
      userId: json['user_id'],
      comment: json['comment'],
      parentId: json['parent_id'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      user: User.fromJson(json['user']),
      replies: (json['replies'] as List<dynamic>?)
          ?.map((reply) => StoryComment.fromJson(reply))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'success_story_id': successStoryId,
      'user_id': userId,
      'comment': comment,
      'parent_id': parentId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'user': user.toJson(),
      'replies': replies.map((reply) => reply.toJson()).toList(),
    };
  }
}