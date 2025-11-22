import '../../core/api/api_constants.dart';

class Review {
  final String author;
  final String? avatarPath;
  final double? rating;
  final String content;
  final String createdAt;
  final List<Review>? replies; 
  final int? replyId; 

  const Review({
    required this.author,
    required this.content,
    required this.createdAt,
    this.rating,
    this.avatarPath,
    this.replies,
    this.replyId,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      author: json["author"] ?? "Unknown",
      content: json["content"] ?? "",
      createdAt: json["created_at"] ?? "",
      rating: json["author_details"]?["rating"]?.toDouble(),
      avatarPath: json["author_details"]?["avatar_path"],
      replies: (json['replies'] as List<dynamic>?)
          ?.map((r) => Review.fromJson(r))
          .toList(),
    );
  }

  factory Review.fromMap(Map<String, dynamic> map) {
    return Review(
      author: map.containsKey('authorName') && map['authorName'] != null 
          ? map['authorName'] as String 
          : 'You',
      content: map['content'] as String,
      createdAt: map['createdAt'] as String,
      rating: map['rating'] as double?,
      avatarPath: map.containsKey('authorAvatarPath') ? map['authorAvatarPath'] as String? : null,
      replies: [], 
    );
  }

  String? get fullAvatarUrl {
    if (avatarPath == null) return null;
    if (avatarPath!.startsWith('file://') || avatarPath!.startsWith('/data/')) {
      return avatarPath;
    }
    if (avatarPath!.startsWith('/https')) return avatarPath!.substring(1);
    if (avatarPath!.startsWith('http')) return avatarPath;
    return '${ApiConstants.imageBaseUrlW500}$avatarPath';
  }
}
