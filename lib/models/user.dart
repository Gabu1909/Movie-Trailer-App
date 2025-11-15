class User {
  final String id;
  String name;
  String username; // Username for login - now mutable
  String email; // Email - now mutable
  String password; // Password - now mutable to allow password changes
  String? profileImageUrl;
  String? phone;
  String? gender;
  String? country;

  User({
    required this.id,
    required this.name,
    required this.username,
    required this.email,
    required this.password,
    this.profileImageUrl,
    this.phone,
    this.gender,
    this.country,
  });

  // Convert User to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'username': username,
      'email': email,
      'password': password,
      'profileImageUrl': profileImageUrl,
      'phone': phone,
      'gender': gender,
      'country': country,
    };
  }

  // Create User from JSON
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      name: json['name'] as String,
      // Handle old data without username - generate from email
      username: json['username'] as String? ??
          (json['email'] as String).split('@')[0],
      email: json['email'] as String,
      password: json['password'] as String,
      profileImageUrl: json['profileImageUrl'] as String?,
      phone: json['phone'] as String?,
      gender: json['gender'] as String?,
      country: json['country'] as String?,
    );
  }
}
