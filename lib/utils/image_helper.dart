class ImageHelper {
  // Sử dụng proxy để bypass hotlink protection
  static String getProxiedImageUrl(String originalUrl) {
    // Encode URL để tránh lỗi ký tự đặc biệt
    final encodedUrl = Uri.encodeComponent(originalUrl);

    // Sử dụng images.weserv.nl - service proxy miễn phí và tối ưu ảnh
    // w=800: giới hạn chiều rộng ảnh là 800px (tối ưu băng thông)
    // q=85: chất lượng ảnh 85% (cân bằng giữa chất lượng và dung lượng)
    return 'https://images.weserv.nl/?url=$encodedUrl&w=800&q=85';
  }
}