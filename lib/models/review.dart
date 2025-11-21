import '../api/api_constants.dart';

class Review {
  final String author;
  final String? avatarPath;
  final double? rating;
  final String content;
  final String createdAt;
  final List<Review>? replies; // Thêm danh sách các câu trả lời

  Review({
    required this.author,
    required this.content,
    required this.createdAt,
    this.rating,
    this.avatarPath,
    this.replies,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      author: json["author"] ?? "Unknown",
      content: json["content"] ?? "",
      createdAt: json["created_at"] ?? "",
      rating: json["author_details"]?["rating"]?.toDouble(),
      avatarPath: json["author_details"]?["avatar_path"],
      // Giả sử API trả về replies, nếu không thì sẽ là null
      replies: (json['replies'] as List<dynamic>?)
          ?.map((r) => Review.fromJson(r))
          .toList(),
    );
  }

  // Factory mới để tạo từ map của database
  factory Review.fromMap(Map<String, dynamic> map) {
    return Review(
      author: 'You', // Review từ DB luôn là của người dùng hiện tại
      content: map['content'] as String,
      createdAt: map['createdAt'] as String,
      rating: map['rating'] as double?,
      replies: [], // Review từ DB local chưa có replies
    );
  }

  String? get fullAvatarUrl {
    if (avatarPath == null) return null;
    if (avatarPath!.startsWith('/https')) return avatarPath!.substring(1);
    return '${ApiConstants.imageBaseUrlW500}$avatarPath';
  }
}
