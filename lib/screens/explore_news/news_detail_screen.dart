import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // Thêm import này
import 'package:webview_flutter/webview_flutter.dart';

class NewsDetailScreen extends StatefulWidget {
  final String articleUrl;
  final String articleTitle;

  const NewsDetailScreen({
    super.key,
    required this.articleUrl,
    required this.articleTitle,
  });

  @override
  State<NewsDetailScreen> createState() => _NewsDetailScreenState();
}

class _NewsDetailScreenState extends State<NewsDetailScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      // Bước 1: Đăng ký một JavaScriptChannel
      ..addJavaScriptChannel(
        'SnackBarChannel', // Đặt tên cho kênh
        onMessageReceived: (JavaScriptMessage message) {
          // Bước 2: Xử lý tin nhắn nhận được từ WebView
          // Ở đây, chúng ta hiển thị một SnackBar với nội dung tin nhắn
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message.message)),
          );
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          // Được gọi khi trang web đã tải xong
          onPageFinished: (String url) {
            // Chỉ chạy JS tùy chỉnh ở chế độ debug để tránh lỗi trang trắng trên bản release
            // kDebugMode là một hằng số của Flutter, true khi ở debug mode.
            if (kDebugMode) {
              // Ẩn các thành phần không mong muốn
              _hideUnwantedElements();
              // Thêm listener cho các nút bấm bên trong web
              _addCustomButtonListener();
            }

            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.articleUrl));
  }

  // Hàm để chạy JavaScript và ẩn các phần tử không mong muốn
  void _hideUnwantedElements() {
    // QUAN TRỌNG: Bạn cần kiểm tra các trang web tin tức thực tế để tìm
    // đúng CSS selector (id, class, tag) của các phần tử bạn muốn ẩn.
    // Các ví dụ dưới đây chỉ là giả định.

    _controller.runJavaScript('''
      // Ví dụ 1: Ẩn phần tử bằng ID (ví dụ: header của trang)
      var header = document.getElementById('main-header');
      if (header) {
        header.style.display = 'none';
      }

      // Ví dụ 2: Ẩn tất cả các phần tử có class nhất định (ví dụ: banner quảng cáo)
      var ads = document.getElementsByClassName('ad-container');
      for (var i = 0; i < ads.length; i++) {
        ads[i].style.display = 'none';
      }

      // Ví dụ 3: Ẩn footer của trang bằng tên thẻ
      var footers = document.getElementsByTagName('footer');
      for (var i = 0; i < footers.length; i++) {
        footers[i].style.display = 'none';
      }

      // Ví dụ 4: Ẩn phần tử bằng querySelector (linh hoạt hơn)
      var subscriptionPopup = document.querySelector('.subscription-popup');
      if (subscriptionPopup) {
        subscriptionPopup.style.display = 'none';
      }
    ''');
  }

  // Hàm để thêm listener vào một nút bấm trong web để nó có thể gọi về Flutter
  void _addCustomButtonListener() {
    _controller.runJavaScript('''
      // Giả sử trang web có một nút "Share" với id là 'share-button'
      var shareButton = document.getElementById('share-button');
      
      // Nếu tìm thấy nút đó
      if (shareButton) {
        // Gán một sự kiện click cho nó
        shareButton.onclick = function() {
          // Bước 3: Gọi kênh 'SnackBarChannel' và gửi tin nhắn về Flutter
          SnackBarChannel.postMessage('User clicked the Share button!');
        };
      }
    ''');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.articleTitle, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}