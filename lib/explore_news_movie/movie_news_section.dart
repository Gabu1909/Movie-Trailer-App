import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart'; // Import thư viện
import '../screens/explore_news/news_detail_screen.dart';
import '../utils/ui_helpers.dart';

class MovieNewsSection extends StatelessWidget {
  final List<dynamic> articles;

  const MovieNewsSection({super.key, required this.articles});

  @override
  Widget build(BuildContext context) {
    // Thay thế ListView.builder bằng SliverList
    return SliverList.builder(
      itemCount: articles.length, // Cung cấp số lượng item
      itemBuilder: (context, index) {
        // itemBuilder tương tự như ListView
        final article = articles[index];
        final title = article['title'] ?? 'Không có tiêu đề';
        final source = article['source']['name'] ?? 'Không rõ nguồn';
        final imageUrl = article['urlToImage'];
        final proxiedUrl = UIHelpers.getProxiedImageUrl(imageUrl);

        // In ra URL để kiểm tra
        print('📸 Article #$index: $imageUrl');
        print('🔄 Proxied: $proxiedUrl');

        final url = article['url'];
        final publishedAt = article['publishedAt'] != null
            ? DateTime.parse(article['publishedAt'])
            : null;

        return Card(
          color: Colors.white.withOpacity(0.08),
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          elevation: 5,
          shadowColor: Colors.black.withOpacity(0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          clipBehavior: Clip.antiAlias, // Để bo tròn cả ảnh
          child: InkWell(
            // Cập nhật onTap để điều hướng đến NewsDetailScreen
            onTap: () async {
              // 1. Kiểm tra kết nối mạng
              final connectivityResult =
                  await (Connectivity().checkConnectivity());
              if (connectivityResult == ConnectivityResult.none) {
                // 2. Nếu không có mạng, hiển thị SnackBar
                // Dùng 'if (!context.mounted) return;' để đảm bảo an toàn khi dùng context trong hàm async
                if (!context.mounted) return;
                UIHelpers.showErrorSnackBar(
                  context,
                  'Không có kết nối internet. Vui lòng thử lại!',
                );
              } else {
                // 3. Nếu có mạng, điều hướng đến màn hình chi tiết
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        NewsDetailScreen(articleUrl: url, articleTitle: title),
                  ),
                );
              }
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- Phần ảnh ---
                Hero(
                  tag: url, // Dùng url làm hero tag duy nhất
                  child: CachedNetworkImage(
                    imageUrl: proxiedUrl, // ✅ Dùng URL đã proxy
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      height: 180,
                      color: Colors.black26,
                      child: const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                    ),
                    errorWidget: (context, url, error) {
                      print('❌ Failed even with proxy: $error');
                      return Container(
                        height: 180,
                        color: Colors.black26,
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.image_not_supported,
                                color: Colors.grey, size: 40),
                            SizedBox(height: 8),
                            Text('No Image Found',
                                style: TextStyle(
                                    color: Colors.grey, fontSize: 12)),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                // --- Phần nội dung ---
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                          color: Colors.white,
                          height: 1.3,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            source,
                            style: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (publishedAt != null)
                            Text(
                              '${publishedAt.day}/${publishedAt.month}/${publishedAt.year}',
                              style: TextStyle(
                                  color: Colors.grey.shade500, fontSize: 12),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
