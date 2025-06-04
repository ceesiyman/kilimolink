class Tip {
  final String userName;
  final String content;

  Tip({
    required this.userName,
    required this.content,
  });

  factory Tip.fromJson(Map<String, dynamic> json) {
    return Tip(
      userName: json['userName'],
      content: json['content'],
    );
  }
}