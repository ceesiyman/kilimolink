class Auth {
  final String token;
  final String userId;

  Auth({
    required this.token,
    required this.userId,
  });

  factory Auth.fromJson(Map<String, dynamic> json) {
    return Auth(
      token: json['token'],
      userId: json['userId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'userId': userId,
    };
  }
}