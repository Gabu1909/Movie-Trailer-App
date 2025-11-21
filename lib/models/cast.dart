class Cast {
  final int id;
  final String name;
  final String? profilePath;
  final String? knownForDepartment;
  final List<dynamic>? knownFor; // Thêm trường này

  Cast({
    required this.id,
    required this.name,
    this.profilePath,
    this.knownForDepartment,
    this.knownFor, // Thêm vào constructor
  });

  factory Cast.fromJson(Map<String, dynamic> json) => Cast(
        id: json['id'],
        name: json['name'],
        profilePath: json['profile_path'],
        knownForDepartment: json['known_for_department'],
        knownFor: json['known_for'] as List<dynamic>?,
      );
}
