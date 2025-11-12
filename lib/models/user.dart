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
}
