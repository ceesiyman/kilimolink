class CommunityPost {
  final String content;
  final String author;
  final String? imageUrl; // Optional for Success Stories
  final String? type; // Optional, e.g., "text", "audio" for Discussion

  CommunityPost({
    required this.content,
    required this.author,
    this.imageUrl,
    this.type,
  });

  factory CommunityPost.fromJson(Map<String, dynamic> json) {
    return CommunityPost(
      content: json['content'],
      author: json['author'],
      imageUrl: json['imageUrl'],
      type: json['type'],
    );
  }
}