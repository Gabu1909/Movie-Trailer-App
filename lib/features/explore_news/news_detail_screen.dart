import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; 
import 'package:webview_flutter/webview_flutter.dart';
import '../../../shared/utils/ui_helpers.dart';

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
      ..addJavaScriptChannel(
        'SnackBarChannel', 
        onMessageReceived: (JavaScriptMessage message) {
          UIHelpers.showInfoSnackBar(context, message.message);
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            if (kDebugMode) {
              _hideUnwantedElements();
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

  void _hideUnwantedElements() {


    _controller.runJavaScript('''

    ''');
  }

  void _addCustomButtonListener() {
    _controller.runJavaScript('');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.articleTitle,
            maxLines: 1, overflow: TextOverflow.ellipsis),
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
