class User {
  final String id;
  final String name;
  final String email;
  final String password; // Chỉ để mô phỏng, không nên lưu password thế này
  String? profileImageUrl;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.password,
    this.profileImageUrl,
  });

  // Phương thức để chuyển đổi một đối tượng User thành Map (JSON)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'password': password,
      'profileImageUrl': profileImageUrl,
    };
  }

  // Factory constructor để tạo một đối tượng User từ Map (JSON)
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      password: json['password'],
      profileImageUrl: json['profileImageUrl'],
    );
  }

  // Hàm static để chuyển đổi một Map<String, User> thành Map<String, dynamic>
  static Map<String, dynamic> mapToJson(Map<String, User> map) {
    return map.map((key, value) => MapEntry(key, value.toJson()));
  }

  // Hàm static để chuyển đổi một Map<String, dynamic> thành Map<String, User>
  static Map<String, User> mapFromJson(Map<String, dynamic> json) {
    return json.map((key, value) => MapEntry(key, User.fromJson(value)));
  }
}
