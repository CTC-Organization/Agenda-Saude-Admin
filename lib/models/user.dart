class User {
  String accessToken;
  String refreshToken;
  String name;
  String email;
  String role;
  String id;
  String userId;

  User(
      {required this.id,
      required this.userId,
      required this.accessToken,
      required this.refreshToken,
      required this.name,
      required this.email,
      required this.role});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      userId: json['userId'],
      name: json['name'],
      email: json['email'],
      role: json['role'],
      accessToken: json['accessToken'],
      refreshToken: json['refreshToken'],
    );
  }
}
