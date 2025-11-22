class User {
  final String id;
  String name;
  String username; 
  String email; 
  String password; 
  String? profileImageUrl;
  String? phone;
  String? gender;
  String? country;
  String? createdAt;

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
    this.createdAt,
  });

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
      'createdAt': createdAt,
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      name: json['name'] as String,
      username: json['username'] as String? ??
          (json['email'] as String).split('@')[0],
      email: json['email'] as String,
      password: json['password'] as String,
      profileImageUrl: json['profileImageUrl'] as String?,
      phone: json['phone'] as String?,
      gender: json['gender'] as String?,
      country: json['country'] as String?,
      createdAt: json['createdAt'] as String?,
    );
  }
}
