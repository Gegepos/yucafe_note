class User {
  final int id;
  final String username;
  final String? nickname;
  final String? avatar;
  final String? email;
  final String? phone;
  final String? createTime;

  User({
    required this.id,
    required this.username,
    this.nickname,
    this.avatar,
    this.email,
    this.phone,
    this.createTime,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      username: json['username'] ?? '',
      nickname: json['nickname'],
      avatar: json['avatar'],
      email: json['email'],
      phone: json['phone'],
      createTime: json['createTime'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'nickname': nickname,
        'avatar': avatar,
        'email': email,
        'phone': phone,
      };
}
