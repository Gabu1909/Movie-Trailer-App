class Cast {
  final int id;
  final String name;
  final String? profilePath;
  final List<dynamic>? knownFor; // Thêm trường này

  Cast({
    required this.id,
    required this.name,
    this.profilePath,
    this.knownFor, // Thêm vào constructor
  });

  factory Cast.fromJson(Map<String, dynamic> json) => Cast(
      id: json['id'],
      name: json['name'],
      profilePath: json['profile_path'],
      knownFor: json['known_for'] as List<dynamic>?);
}
