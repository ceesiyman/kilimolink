class SuccessStory {
  final String userName;
  final String content;
  final List<String> imageUrls;

  SuccessStory({
    required this.userName,
    required this.content,
    required this.imageUrls,
  });

  factory SuccessStory.fromJson(Map<String, dynamic> json) {
    return SuccessStory(
      userName: json['userName'],
      content: json['content'],
      imageUrls: List<String>.from(json['imageUrls']),
    );
  }
}