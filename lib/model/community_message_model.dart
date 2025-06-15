import 'package:flutter/material.dart';

class CommunityMessage {
  final int id;
  final int userId;
  final String? title;
  final String content;
  final String? category;
  final List<String>? tags;
  final bool isPinned;
  final bool isAnnouncement;
  final int viewsCount;
  final int likesCount;
  final int repliesCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final User user;
  final List<MessageAttachment>? attachments;
  final List<MessageReply>? replies;
  final bool? isLiked;

  CommunityMessage({
    required this.id,
    required this.userId,
    this.title,
    required this.content,
    this.category,
    this.tags,
    required this.isPinned,
    required this.isAnnouncement,
    required this.viewsCount,
    required this.likesCount,
    required this.repliesCount,
    required this.createdAt,
    required this.updatedAt,
    required this.user,
    this.attachments,
    this.replies,
    this.isLiked,
  });

  factory CommunityMessage.fromJson(Map<String, dynamic> json) {
    return CommunityMessage(
      id: json['id'],
      userId: json['user_id'],
      title: json['title'],
      content: json['content'],
      category: json['category'],
      tags: json['tags'] != null 
          ? List<String>.from(json['tags'])
          : null,
      isPinned: json['is_pinned'] ?? false,
      isAnnouncement: json['is_announcement'] ?? false,
      viewsCount: json['views_count'] ?? 0,
      likesCount: json['likes_count'] ?? 0,
      repliesCount: json['replies_count'] ?? 0,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      user: User.fromJson(json['user']),
      attachments: json['attachments'] != null
          ? List<MessageAttachment>.from(
              json['attachments'].map((x) => MessageAttachment.fromJson(x)))
          : null,
      replies: json['replies'] != null
          ? List<MessageReply>.from(
              json['replies'].map((x) => MessageReply.fromJson(x)))
          : null,
      isLiked: json['is_liked'],
    );
  }
}

class MessageAttachment {
  final int id;
  final int communityMessageId;
  final String fileName;
  final String filePath;
  final String fileType;
  final String mimeType;
  final int fileSize;
  final int order;
  final DateTime createdAt;
  final DateTime updatedAt;

  MessageAttachment({
    required this.id,
    required this.communityMessageId,
    required this.fileName,
    required this.filePath,
    required this.fileType,
    required this.mimeType,
    required this.fileSize,
    required this.order,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MessageAttachment.fromJson(Map<String, dynamic> json) {
    return MessageAttachment(
      id: json['id'],
      communityMessageId: json['community_message_id'],
      fileName: json['file_name'],
      filePath: json['file_path'],
      fileType: json['file_type'],
      mimeType: json['mime_type'],
      fileSize: json['file_size'],
      order: json['order'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}

class MessageReply {
  final int id;
  final int communityMessageId;
  final int userId;
  final String content;
  final int? parentReplyId;
  final int likesCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final User user;
  final List<MessageReply>? replies;
  final bool? isLiked;

  MessageReply({
    required this.id,
    required this.communityMessageId,
    required this.userId,
    required this.content,
    this.parentReplyId,
    required this.likesCount,
    required this.createdAt,
    required this.updatedAt,
    required this.user,
    this.replies,
    this.isLiked,
  });

  factory MessageReply.fromJson(Map<String, dynamic> json) {
    return MessageReply(
      id: json['id'],
      communityMessageId: json['community_message_id'],
      userId: json['user_id'],
      content: json['content'],
      parentReplyId: json['parent_reply_id'],
      likesCount: json['likes_count'] ?? 0,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      user: User.fromJson(json['user']),
      replies: json['replies'] != null
          ? List<MessageReply>.from(
              json['replies'].map((x) => MessageReply.fromJson(x)))
          : null,
      isLiked: json['is_liked'],
    );
  }
}

class User {
  final int id;
  final String name;
  final String? imageUrl;

  User({
    required this.id,
    required this.name,
    this.imageUrl,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      imageUrl: json['image_url'],
    );
  }
} 