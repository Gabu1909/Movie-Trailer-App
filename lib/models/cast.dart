class Cast {
  final int id;
  final String name;
  final String? profilePath;
  Cast({required this.id, required this.name, this.profilePath});
  factory Cast.fromJson(Map<String, dynamic> json) => Cast(
      id: json['id'], name: json['name'], profilePath: json['profile_path']);
}
