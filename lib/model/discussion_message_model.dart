class DiscussionMessage {
  final String userName;
  final String content;
  final bool isVoiceMessage; // To indicate if the message is a voice message

  DiscussionMessage({
    required this.userName,
    required this.content,
    this.isVoiceMessage = false,
  });

  factory DiscussionMessage.fromJson(Map<String, dynamic> json) {
    return DiscussionMessage(
      userName: json['userName'],
      content: json['content'],
      isVoiceMessage: json['isVoiceMessage'] ?? false,
    );
  }
}